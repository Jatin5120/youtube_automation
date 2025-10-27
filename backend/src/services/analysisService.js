const OpenAI = require("openai");
const crypto = require("crypto");
const {
  getCombinedBatchPrompt,
  getBatchEmailPrompt,
} = require("../utils/prompts");
const { MemoryCache } = require("../utils/cache");
const config = require("../config/analysis");
const Logger = require("../utils/logger");
const { AnalysisError } = require("../utils/errors");
const EmailsService = require("./emailsService");

class AnalysisService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
    this.emailsService = new EmailsService();

    // Initialize cache with configuration
    this.analysisCache = new MemoryCache(
      config.CACHE.TTL,
      config.CACHE.MAX_ENTRIES
    );

    // Store configuration
    this.config = config;

    // Mutex for preventing race conditions in batch processing
    this.processingMutex = new Map(); // key -> { promise, timestamp }

    // Start mutex cleanup timer (every 5 minutes)
    this._startMutexCleanup();
  }

  // Start mutex cleanup timer
  _startMutexCleanup() {
    setInterval(() => {
      this._cleanupAbandonedMutexes();
    }, this.config.BATCH.MUTEX_CLEANUP_INTERVAL);
  }

  // Clean up abandoned mutexes
  _cleanupAbandonedMutexes() {
    const now = Date.now();
    const maxAge = this.config.BATCH.MUTEX_MAX_AGE;

    for (const [key, mutexData] of this.processingMutex.entries()) {
      if (now - mutexData.timestamp > maxAge) {
        Logger.warn(`Cleaning up abandoned mutex: ${key}`);
        this.processingMutex.delete(key);
      }
    }
  }

  // Generate cache key from input
  _getCacheKey(type, input) {
    const hash = crypto
      .createHash("md5")
      .update(JSON.stringify({ type, ...input }))
      .digest("hex");
    return `analysis_${type}_${hash}`;
  }

  // Generate cache key for batch
  _getBatchCacheKey(channels) {
    const hash = crypto
      .createHash("md5")
      .update(
        JSON.stringify(
          channels.map((ch) => ({
            id: ch.channelId,
            videoTitle: ch.videoTitle,
            channelName: ch.channelName,
          }))
        )
      )
      .digest("hex");
    return `batch_${hash}`;
  }

  // Mutex helper to prevent race conditions
  async _withMutex(key, asyncOperation) {
    // Check if there's already a processing operation for this key
    if (this.processingMutex.has(key)) {
      Logger.debug(`Waiting for existing processing operation: ${key}`);
      // Wait for the existing operation to complete
      await this.processingMutex.get(key).promise;

      // After waiting, check cache again (the other operation might have populated it)
      const cached = this.analysisCache.get(key);
      if (cached) {
        Logger.info("Cache hit after waiting for mutex", { key });
        return cached;
      }
    }

    // Create a new processing promise
    const processingPromise = this._executeWithMutex(key, asyncOperation);
    this.processingMutex.set(key, {
      promise: processingPromise,
      timestamp: Date.now(),
    });

    try {
      const result = await processingPromise;
      return result;
    } finally {
      // Clean up the mutex entry
      this.processingMutex.delete(key);
    }
  }

  // Execute the actual operation with proper error handling
  async _executeWithMutex(key, asyncOperation) {
    try {
      return await asyncOperation();
    } catch (error) {
      Logger.error(`Operation failed for key ${key}:`, error);
      throw error;
    }
  }

  async _getEmailsFromChannels(channels) {
    const channelIds = channels.map((channel) => channel.channelId);
    const emails = await this.emailsService.fromChannelIds(channelIds);
    return emails;
  }

  async _getResponseFromOpenAI(prompt, controller) {
    const response = await this.openai.chat.completions.create(
      {
        model: this.config.OPENAI.MODEL,
        messages: [
          { role: "system", content: prompt.systemPrompt },
          { role: "user", content: prompt.userPrompt },
        ],
        max_completion_tokens: this.config.OPENAI.MAX_TOKENS,
        temperature: this.config.OPENAI.TEMPERATURE,
        response_format: {
          type: "json_schema",
          json_schema: {
            name: "channel_analysis",
            schema: this.config.RESPONSE_SCHEMA,
          },
        },
      },
      {
        signal: controller.signal,
      }
    );
    return response;
  }

  async _generateEmailsForBatch(analysisResults, channels) {
    if (!analysisResults || analysisResults.length === 0) {
      return analysisResults.map((r) => ({ ...r, emailMessage: "" }));
    }

    try {
      // Prepare email inputs
      const emailInputs = analysisResults.map((result) => {
        const channel = channels.find(
          (ch) => ch.channelId === result.channelId
        );
        return {
          channelId: result.channelId,
          analyzedName: result.analyzedName,
          analyzedTitle: result.analyzedTitle,
          videoDescription: channel?.videoDescription || "",
        };
      });

      const prompt = getBatchEmailPrompt(emailInputs);

      // Timeout control
      const controller = new AbortController();
      const timeoutId = setTimeout(
        () => controller.abort(),
        this.config.OPENAI.TIMEOUT
      );

      const response = await this.openai.chat.completions.create(
        {
          model: this.config.OPENAI.MODEL,
          messages: [
            { role: "system", content: prompt.systemPrompt },
            { role: "user", content: prompt.userPrompt },
          ],
          max_completion_tokens:
            this.config.OPENAI.EMAIL_MAX_TOKENS * (emailInputs.length + 1),
          temperature: this.config.OPENAI.EMAIL_TEMPERATURE,
          response_format: {
            type: "json_schema",
            json_schema: {
              name: "email_analysis",
              schema: this.config.EMAIL_RESPONSE_SCHEMA,
            },
          },
        },
        { signal: controller.signal }
      );

      clearTimeout(timeoutId);

      const content = response.choices[0].message.content;

      const emailData = JSON.parse(content);

      // Merge emails into results
      const messages = analysisResults.map((result) => {
        const emailObj = emailData.results?.find(
          (e) => e.channelId === result.channelId
        );
        return {
          ...result,
          emailMessage: emailObj?.emailMessage || "",
        };
      });
      return messages;
    } catch (error) {
      Logger.error("Email generation failed for batch", {
        error: error,
        count: analysisResults.length,
      });
      // Return results with empty emailMessage on failure
      return analysisResults.map((r) => ({ ...r, emailMessage: "" }));
    }
  }

  // New method: Process batch of channels in single AI call
  async analyzeChannelsBatch(channels, batchSize = null) {
    // Input validation
    if (!Array.isArray(channels) || channels.length === 0) {
      throw new AnalysisError(
        "Channels must be a non-empty array",
        "INVALID_INPUT"
      );
    }

    // Validate each channel has required fields
    for (const channel of channels) {
      if (!channel.userName || !channel.videoTitle || !channel.channelName) {
        throw new AnalysisError(
          "Each channel must have userName, videoTitle, and channelName",
          "INVALID_CHANNEL"
        );
      }
    }

    // Generate cache key for batch
    const cacheKey = this._getBatchCacheKey(channels);

    // Check cache first (before mutex to avoid unnecessary waiting)
    const cached = this.analysisCache.get(cacheKey);
    if (cached) {
      Logger.info("Batch cache hit", { channels: channels.length });
      return cached;
    }

    // Use mutex to prevent race conditions
    return await this._withMutex(cacheKey, async () => {
      // Double-check cache after acquiring mutex (another request might have populated it)
      const cachedAfterMutex = this.analysisCache.get(cacheKey);
      if (cachedAfterMutex) {
        Logger.info("Batch cache hit after mutex", {
          channels: channels.length,
        });
        return cachedAfterMutex;
      }

      try {
        const prompt = getCombinedBatchPrompt(channels);

        // Add timeout to OpenAI request
        const controller = new AbortController();
        const timeoutId = setTimeout(
          () => controller.abort(),
          this.config.OPENAI.TIMEOUT
        );

        const data = await Promise.all([
          this._getEmailsFromChannels(channels),
          this._getResponseFromOpenAI(prompt, controller),
        ]);
        const emails = data[0];
        const response = data[1];

        clearTimeout(timeoutId);

        // Validate response structure
        if (!response.choices || response.choices.length === 0) {
          Logger.error("OpenAI response has no choices", { response });
          throw new AnalysisError("No response choices from AI", "NO_CHOICES");
        }

        if (
          !response.choices[0].message ||
          !response.choices[0].message.content
        ) {
          Logger.error("OpenAI response has no message content", {
            choice: response.choices[0],
          });
          throw new AnalysisError("No message content from AI", "NO_CONTENT");
        }

        // Safe JSON parsing with error handling
        let result;
        try {
          const content = response.choices[0].message.content.trim();
          if (!content) {
            throw new Error("Empty content received from AI");
          }
          result = JSON.parse(content);
        } catch (parseError) {
          Logger.error("Failed to parse OpenAI response", {
            error: parseError.message,
            content: response.choices[0].message.content,
            contentLength: response.choices[0].message.content.length,
          });
          throw new AnalysisError(
            `Invalid response format from AI: ${parseError.message}`,
            "PARSE_ERROR"
          );
        }

        // Validate response
        this._validateBatchResponse(result, channels);

        result.results = result.results.map((result, index) => ({
          ...result,
          email: index < emails.length ? emails[index] : "",
        }));

        // Generate email messages
        result.results = await this._generateEmailsForBatch(
          result.results,
          channels
        );

        // Cache result
        this.analysisCache.set(cacheKey, result);

        return result;
      } catch (error) {
        if (error.name === "AbortError") {
          Logger.error("OpenAI request timeout", error);
          throw new AnalysisError("Request timeout", "TIMEOUT");
        }

        Logger.error("Batch analysis failed", error);
        // Return fallback results
        return this._generateFallbackResults(channels);
      }
    });
  }

  _validateBatchResponse(result, channels) {
    if (!result.results || !Array.isArray(result.results)) {
      throw new AnalysisError("Invalid response structure");
    }

    if (result.results.length !== channels.length) {
      throw new AnalysisError("Result count mismatch");
    }

    // Validate each result has required fields
    for (const item of result.results) {
      var missingFields = [];
      if (!item.channelId) missingFields.push("channelId");
      if (!item.userName) missingFields.push("userName");
      if (!item.analyzedTitle) missingFields.push("analyzedTitle");
      if (!item.analyzedName) missingFields.push("analyzedName");
      if (missingFields.length > 0) {
        throw new AnalysisError(
          `Missing required fields in result: ${missingFields.join(", ")}`
        );
      }
    }
  }

  // Updated batch analysis with SSE callbacks for channels
  async analyzeBatchWithSSE({
    channels,
    batchSize,
    onProgress,
    onBatchResult,
    onComplete,
    onError,
  }) {
    try {
      if (!Array.isArray(channels) || channels.length === 0) {
        throw new AnalysisError(this.config.ERRORS.EMPTY_ITEMS, "EMPTY_ITEMS");
      }

      const size = batchSize || this.config.BATCH.CHANNELS_PER_BATCH;
      const totalChannels = channels.length;
      let processedCount = 0;

      onProgress(config.EVENTS.STARTED, {
        current: 0,
        total: totalChannels,
        message: `Starting batch analysis (${size} channels per batch)...`,
      });

      // Pre-check cache for all batches to optimize processing
      const batches = [];
      for (let i = 0; i < channels.length; i += size) {
        const batch = channels.slice(i, i + size);
        const cacheKey = this._getBatchCacheKey(batch);
        const cached = this.analysisCache.get(cacheKey);

        if (cached) {
          processedCount += cached.results.length;

          onProgress(config.EVENTS.PROGRESS, {
            current: processedCount,
            total: totalChannels,
            message: `Analyzed ${processedCount} of ${totalChannels} channels (cached)`,
          });

          onBatchResult(
            cached.results.map((result) => ({
              channelId: result.channelId,
              userName: result.userName,
              analyzedTitle: result.analyzedTitle,
              analyzedName: result.analyzedName,
              email: result.email,
              emailMessage: result.emailMessage,
            }))
          );
        } else {
          batches.push(batch);
        }
      }

      // Process only non-cached batches
      for (const batch of batches) {
        // Single AI call for batch
        const batchResult = await this.analyzeChannelsBatch(batch, size);

        processedCount += batchResult.results.length;

        onProgress(config.EVENTS.PROGRESS, {
          current: processedCount,
          total: totalChannels,
          message: `Analyzed ${processedCount} of ${totalChannels} channels`,
        });

        onBatchResult(
          batchResult.results.map((result) => ({
            channelId: result.channelId,
            userName: result.userName,
            analyzedTitle: result.analyzedTitle,
            analyzedName: result.analyzedName,
            email: result.email,
            emailMessage: result.emailMessage,
          }))
        );

        // Rate limiting between batches
        const batchIndex = batches.indexOf(batch);
        if (batchIndex < batches.length - 1) {
          Logger.debug(
            `Waiting ${this.config.BATCH.RATE_LIMIT_DELAY}ms before next batch...`
          );
          await new Promise((resolve) =>
            setTimeout(resolve, this.config.BATCH.RATE_LIMIT_DELAY)
          );
        }
      }

      onComplete();
    } catch (error) {
      Logger.error("Fatal error in batch processing:", error);
      onError(error);
    }
  }
}

module.exports = AnalysisService;
