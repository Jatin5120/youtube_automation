const OpenAI = require("openai");
const crypto = require("crypto");
const { getNameTitlePrompts, getEmailPrompts } = require("../utils/prompts");
const { MemoryCache } = require("../utils/cache");
const config = require("../config/analysis");
const Logger = require("../utils/logger");
const { AnalysisError } = require("../utils/errors");
const EmailsService = require("./emailsService");
const LeadMagicService = require("./leadMagicService");
const tokenCostManager = require("../utils/tokenCost");

class AnalysisService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
    this.emailsService = new EmailsService();
    this.leadMagicService = new LeadMagicService();

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

  /**
   * Parse comma-separated email string into array of normalized emails
   * @param {string} rawEmails - Comma-separated email string
   * @returns {Array<string>} - Array of normalized email strings
   */
  _parseEmailString(rawEmails) {
    if (!rawEmails || rawEmails.trim() === "") {
      return [];
    }
    return rawEmails
      .split(",")
      .map((e) => this._normalizeEmailString(e))
      .filter(Boolean);
  }

  /**
   * Normalize email format (trim whitespace, lowercase)
   * @param {string} email - Raw email string
   * @returns {string} - Normalized email string
   */
  _normalizeEmailString(email) {
    if (!email || typeof email !== "string") {
      return "";
    }
    return email.trim().toLowerCase();
  }

  /**
   * Extract only valid emails from raw email string based on validation map
   * @param {string} rawEmails - Comma-separated email string
   * @param {Object} emailValidationMap - Map of email -> {valid, status}
   * @returns {string} - Comma-separated string of valid emails
   */
  _extractValidEmails(rawEmails, emailValidationMap) {
    if (!rawEmails || rawEmails.trim() === "") {
      return "";
    }

    const emails = this._parseEmailString(rawEmails);
    const validEmailList = emails.filter((email) => {
      const validation = emailValidationMap[email];
      return validation && validation.valid;
    });

    return validEmailList.join(",");
  }

  /**
   * Validate OpenAI API response structure
   * @param {Object} response - OpenAI API response object
   * @returns {Object} - Validated response with choices and content
   * @throws {AnalysisError} - If response is invalid
   */
  _validateOpenAIResponse(response) {
    if (!response.choices || response.choices.length === 0) {
      Logger.error("OpenAI response has no choices", { response });
      throw new AnalysisError("No response choices from AI", "NO_CHOICES");
    }

    if (!response.choices[0].message || !response.choices[0].message.content) {
      Logger.error("OpenAI response has no message content", {
        choice: response.choices[0],
      });
      throw new AnalysisError("No message content from AI", "NO_CONTENT");
    }

    return response;
  }

  /**
   * Create AbortController with timeout
   * @param {number} timeoutMs - Timeout in milliseconds
   * @returns {Object} - Object with controller and timeoutId {controller, timeoutId}
   */
  _createTimeoutController(timeoutMs) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
    return { controller, timeoutId };
  }

  /**
   * Fetch emails for channels from email service
   * @param {Array} channels - Array of channel objects with channelId
   * @returns {Promise<Array<string>>} - Array of email strings (one per channel)
   */
  async _getEmailsFromChannels(channels) {
    const emailPromises = channels.map((channel) =>
      this.emailsService.fromChannelIds([channel.channelId])
    );
    const emailsArray = await Promise.all(emailPromises);

    return emailsArray.map((arr) => arr[0] || "");
  }

  /**
   * Parse emails from channels and build mapping
   * @param {Array} channelsWithEmails - Channels with rawEmails property
   * @returns {Object} - Object with emailList and emailToChannelMap
   */
  _parseEmailsFromChannels(channelsWithEmails) {
    const emailList = [];
    const emailToChannelMap = new Map(); // email -> [{channelIndex, emailIndex, channelId}]

    channelsWithEmails.forEach((channel, channelIndex) => {
      const rawEmails = channel.rawEmails || "";
      if (!rawEmails || rawEmails.trim() === "") {
        return;
      }

      const emails = this._parseEmailString(rawEmails);

      emails.forEach((email) => {
        emailList.push(email);
        if (!emailToChannelMap.has(email)) {
          emailToChannelMap.set(email, []);
        }
        emailToChannelMap.get(email).push({
          channelIndex,
          channelId: channel.channelId,
        });
      });
    });

    return { emailList, emailToChannelMap };
  }

  /**
   * Build email validation map from validation results
   * Note: This method is kept for potential future use, but normalization
   * is now handled inline in _validateAndFilterChannels for consistency
   * @param {Array} validationResults - Results from email validation service
   * @returns {Object} - Map of normalized email -> {valid, status}
   */
  _buildEmailValidationMap(validationResults) {
    const emailValidationMap = {};
    validationResults.forEach((result) => {
      const normalizedEmail = this._normalizeEmailString(result.email);
      emailValidationMap[normalizedEmail] = {
        valid: result.valid,
        status: result.status,
      };
    });
    return emailValidationMap;
  }

  /**
   * Filter channels to keep only those with valid emails
   * @param {Array} channelsWithEmails - Channels with rawEmails property
   * @param {Set} channelsWithValidEmail - Set of channel indices with valid emails
   * @returns {Object} - Object with validChannels and originalIndices
   */
  _filterChannelsByEmailValidation(channelsWithEmails, channelsWithValidEmail) {
    const validChannels = [];
    const originalIndices = [];

    channelsWithEmails.forEach((channel, index) => {
      const rawEmails = channel.rawEmails || "";
      const hasEmail = rawEmails && rawEmails.trim() !== "";

      // Only keep channels with valid emails (channels without emails are filtered out)
      if (hasEmail && channelsWithValidEmail.has(index)) {
        validChannels.push(channel);
        originalIndices.push(index);
      }
    });

    return { validChannels, originalIndices };
  }

  /**
   * Validate emails and filter channels - keep only channels with at least one valid email
   * @param {Array} channelsWithEmails - Channels with rawEmails property
   * @returns {Promise<{validChannels: Array, emailValidationMap: Object, originalIndices: Array}>}
   */
  async _validateAndFilterChannels(channelsWithEmails) {
    try {
      // Parse emails from channels
      const { emailList, emailToChannelMap } =
        this._parseEmailsFromChannels(channelsWithEmails);

      // If no emails to validate, filter out all channels (no channels have emails)
      if (emailList.length === 0) {
        Logger.info("No emails to validate, filtering out all channels");
        return {
          validChannels: [],
          emailValidationMap: {},
          originalIndices: [],
        };
      }

      // Validate emails in batches
      const validationResults = await this.leadMagicService.validateEmails(
        emailList
      );

      // Build validation map (normalize email keys for consistency)
      const emailValidationMap = {};
      validationResults.forEach((result) => {
        const normalizedEmail = this._normalizeEmailString(result.email);
        emailValidationMap[normalizedEmail] = {
          valid: result.valid,
          status: result.status,
        };
      });

      // Determine which channels have at least one valid email
      const channelsWithValidEmail = new Set();
      validationResults.forEach((result) => {
        if (result.valid) {
          // Normalize email before lookup to ensure consistency
          const normalizedEmail = this._normalizeEmailString(result.email);
          const channelMappings = emailToChannelMap.get(normalizedEmail) || [];
          channelMappings.forEach((mapping) => {
            channelsWithValidEmail.add(mapping.channelIndex);
          });
        }
      });

      // Filter channels: only keep channels with valid emails
      const { validChannels, originalIndices } =
        this._filterChannelsByEmailValidation(
          channelsWithEmails,
          channelsWithValidEmail
        );

      Logger.info("Email validation complete", {
        totalChannels: channelsWithEmails.length,
        validChannels: validChannels.length,
        filteredChannels: channelsWithEmails.length - validChannels.length,
        emailsValidated: emailList.length,
        validEmails: validationResults.filter((r) => r.valid).length,
      });

      return {
        validChannels,
        emailValidationMap,
        originalIndices,
      };
    } catch (error) {
      Logger.error("Email validation failed", {
        error: error.message,
        errorStack: error.stack,
      });

      // Fail-safe: if validation fails and failSafe is enabled, proceed with all channels
      if (this.leadMagicService.failSafe) {
        Logger.warn(
          "Email validation failed, proceeding with all channels (fail-safe mode)"
        );
        return {
          validChannels: channelsWithEmails,
          emailValidationMap: {},
          originalIndices: channelsWithEmails.map((_, i) => i),
        };
      }

      // If fail-safe is disabled, throw error
      throw new AnalysisError(
        `Email validation failed: ${error.message}`,
        "VALIDATION_ERROR"
      );
    }
  }

  /**
   * Map AI results back to valid channels only (filtered channels are excluded)
   * @param {Array} originalChannels - Original channels array
   * @param {Array} validChannels - Channels that passed validation
   * @param {Object} aiResult - AI analysis results
   * @param {Object} emailValidationMap - Map of email -> {valid, status}
   * @param {Array} originalIndices - Indices mapping valid channels back to original
   * @returns {Object} - Results containing only valid channels (filtered channels excluded)
   */
  _mapResultsToOriginalChannels(
    originalChannels,
    validChannels,
    aiResult,
    emailValidationMap,
    originalIndices
  ) {
    // Create results array with only valid channels (filtered channels excluded)
    const results = [];

    // Create Map for O(1) lookup of AI results by channelId
    const aiResultMap = new Map();
    aiResult.results.forEach((result) => {
      aiResultMap.set(result.channelId, result);
    });

    // Process valid channels with AI results (only include valid channels)
    validChannels.forEach((validChannel, validIndex) => {
      const aiResultItem = aiResultMap.get(validChannel.channelId);

      if (aiResultItem) {
        // Get validated emails for this channel
        const rawEmails = validChannel.rawEmails || "";
        const validatedEmails = this._extractValidEmails(
          rawEmails,
          emailValidationMap
        );

        results.push({
          ...aiResultItem,
          email: validatedEmails,
        });
      } else {
        // AI result not found (shouldn't happen, but handle gracefully)
        results.push({
          channelId: validChannel.channelId,
          userName: validChannel.userName || "",
          analyzedTitle: "",
          analyzedName: "",
          email: validChannel.rawEmails || "",
          emailMessage: "",
        });
      }
    });

    return { results };
  }

  /**
   * Get AI analysis response for channels (name/title analysis only)
   * Email message generation is skipped - returns empty emailMessage for all results
   * @param {Array} channels - Array of channel objects to analyze
   * @returns {Promise<Object>} - Analysis results with empty emailMessage fields
   */
  async _getResponseFromOpenAI(channels) {
    const result = await this._getAnalysisResponseFromOpenAI(channels);

    // Defensive check: ensure result.results exists and is an array
    if (!result.results || !Array.isArray(result.results)) {
      Logger.error("Invalid result structure after AI analysis", {
        hasResults: !!result.results,
        isArray: Array.isArray(result.results),
        resultKeys: result ? Object.keys(result) : [],
      });
      throw new AnalysisError("Invalid result structure after AI analysis");
    }

    // Skip AI email message generation - return empty emailMessage for all results
    // Keep _getEmailResponseFromOpenAI method intact for future use
    result.results = result.results.map((r) => ({
      ...r,
      emailMessage: "",
    }));

    return result;
  }

  /**
   * Get AI analysis response for channels (analyzedName and analyzedTitle)
   * @param {Array} channels - Array of channel objects to analyze
   * @returns {Promise<Object>} - Analysis results with analyzedName and analyzedTitle
   */
  async _getAnalysisResponseFromOpenAI(channels) {
    const prompt = await getNameTitlePrompts(channels);

    const { controller, timeoutId } = this._createTimeoutController(
      this.config.OPENAI.TIMEOUT
    );

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

    clearTimeout(timeoutId);

    // Extract and record token usage for cost calculation
    if (response.usage) {
      tokenCostManager.recordUsage(
        response.usage,
        this.config.OPENAI.MODEL,
        `Channel Analysis (${channels.length} channels)`
      );
    }

    this._validateOpenAIResponse(response);

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

    this._validateBatchResponse(result, channels);

    return result;
  }

  /**
   * Generate email messages using AI (currently not used in active flow)
   * This method is kept intact for future use but is skipped in _getResponseFromOpenAI
   * @param {Array} analysisResults - Analysis results with analyzedName and analyzedTitle
   * @param {Array} channels - Original channel objects for context
   * @returns {Promise<Array>} - Results with emailMessage fields populated
   */
  async _getEmailResponseFromOpenAI(analysisResults, channels) {
    if (!analysisResults || analysisResults.length === 0) {
      return analysisResults.map((r) => ({ ...r, emailMessage: "" }));
    }

    try {
      // Create Map for O(1) lookup of channels by channelId
      const channelMap = new Map();
      channels.forEach((channel) => {
        channelMap.set(channel.channelId, channel);
      });

      // Prepare email inputs
      const emailInputs = analysisResults.map((result) => {
        const channel = channelMap.get(result.channelId);
        return {
          channelId: result.channelId,
          analyzedName: result.analyzedName,
          analyzedTitle: result.analyzedTitle,
          videoDescription:
            channel?.latestVideoDescription || channel?.videoDescription || "",
          channelDescription: channel?.channelDescription || "",
          subscriberCount: channel?.subscriberCount || 0,
          viewCount: channel?.viewCount || 0,
          keywords: channel?.keywords || "",
          uploadFrequency: channel?.uploadFrequency || "",
        };
      });

      const prompt = await getEmailPrompts(emailInputs);

      const { controller, timeoutId } = this._createTimeoutController(
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

      // Extract and record token usage for cost calculation
      if (response.usage) {
        tokenCostManager.recordUsage(
          response.usage,
          this.config.OPENAI.MODEL,
          `Email Generation (${emailInputs.length} emails)`
        );
      }

      this._validateOpenAIResponse(response);

      const content = response.choices[0].message.content;

      const emailData = JSON.parse(content);

      // Create Map for O(1) lookup of email results by channelId
      const emailResultMap = new Map();
      emailData.results?.forEach((emailResult) => {
        emailResultMap.set(emailResult.channelId, emailResult);
      });

      // Merge emails into results
      const messages = analysisResults.map((result) => {
        const emailObj = emailResultMap.get(result.channelId);
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
        // 1. Fetch emails first
        const emails = await this._getEmailsFromChannels(channels);

        // 2. Attach emails to channel data
        const channelsWithEmails = channels.map((ch, idx) => ({
          ...ch,
          rawEmails: emails[idx] || "",
        }));

        // 3. Validate emails and filter channels
        const { validChannels, emailValidationMap, originalIndices } =
          await this._validateAndFilterChannels(channelsWithEmails);

        // 4. Early return if no valid channels
        if (validChannels.length === 0) {
          Logger.info("All channels filtered out due to invalid emails");
          // Return empty results (no channels passed email validation)
          const result = { results: [] };
          // Cache result
          this.analysisCache.set(cacheKey, result);
          return result;
        }

        // 5. Store validChannels for error handling
        // (needed in case AI call fails and we need to generate fallback)
        const validChannelsForErrorHandling = validChannels;

        // 6. Run AI analysis only on valid channels
        let aiResult;
        try {
          aiResult = await this._getResponseFromOpenAI(validChannels);
        } catch (aiError) {
          // If AI analysis fails, generate fallback for valid channels only
          Logger.error("AI analysis failed, generating fallback", {
            error: aiError.message,
            validChannelsCount: validChannelsForErrorHandling.length,
          });

          // Generate fallback results for valid channels only
          const fallbackResult = this._generateFallbackResults(
            validChannelsForErrorHandling
          );

          // Map fallback results to maintain consistency
          const result = this._mapResultsToOriginalChannels(
            channels,
            validChannelsForErrorHandling,
            fallbackResult,
            emailValidationMap,
            originalIndices
          );

          // Cache result
          this.analysisCache.set(cacheKey, result);
          return result;
        }

        // 7. Map results back to original channel structure
        const result = this._mapResultsToOriginalChannels(
          channels,
          validChannels,
          aiResult,
          emailValidationMap,
          originalIndices
        );

        // Cache result
        this.analysisCache.set(cacheKey, result);

        return result;
      } catch (error) {
        if (error.name === "AbortError") {
          Logger.error("OpenAI request timeout", error);
          throw new AnalysisError("Request timeout", "TIMEOUT");
        }

        Logger.error("Batch analysis failed", {
          error: error.message,
          errorStack: error.stack,
        });
        // Re-throw to be handled by analyzeBatchWithSSE
        throw error;
      }
    });
  }

  _generateFallbackResults(channels) {
    // Generate fallback results when AI analysis fails
    // Extract basic information from channels and provide safe defaults
    const results = channels.map((channel) => {
      // Extract analyzedTitle from videoTitle (first 3-8 words)
      let analyzedTitle = "Business Content";
      if (channel.videoTitle) {
        const words = channel.videoTitle.trim().split(/\s+/);
        const wordCount = Math.min(Math.max(words.length, 3), 8);
        analyzedTitle = words.slice(0, wordCount).join(" ");
      }

      // Extract analyzedName from userName or channelName (first name)
      let analyzedName = "User";
      if (channel.userName) {
        // Try to extract first name from username
        const userNameParts = channel.userName
          .replace(/[^a-zA-Z\s]/g, " ")
          .trim()
          .split(/\s+/);
        if (userNameParts.length > 0) {
          analyzedName = userNameParts[0];
        } else {
          analyzedName = channel.userName.substring(0, 10);
        }
      } else if (channel.channelName) {
        const channelNameParts = channel.channelName
          .replace(/[^a-zA-Z\s]/g, " ")
          .trim()
          .split(/\s+/);
        if (channelNameParts.length > 0) {
          analyzedName = channelNameParts[0];
        }
      }

      // Ensure analyzedName is title case and within reasonable length
      analyzedName =
        analyzedName.charAt(0).toUpperCase() +
        analyzedName.slice(1).toLowerCase();
      if (analyzedName.length > 20) {
        analyzedName = analyzedName.substring(0, 20);
      }

      return {
        channelId: channel.channelId || "",
        userName: channel.userName || "",
        analyzedTitle: analyzedTitle || "Business Content",
        analyzedName: analyzedName || "User",
        email: "", // Empty in fallback scenario
        emailMessage: "", // Empty in fallback scenario
      };
    });

    return { results };
  }

  _validateBatchResponse(result, channels) {
    if (!result.results || !Array.isArray(result.results)) {
      Logger.error("Invalid response structure", {
        hasResults: !!result.results,
        isArray: Array.isArray(result.results),
        resultKeys: result ? Object.keys(result) : [],
      });
      throw new AnalysisError("Invalid response structure");
    }

    if (result.results.length !== channels.length) {
      Logger.error("Result count mismatch", {
        resultCount: result.results.length,
        channelCount: channels.length,
        channelIds: channels.map((c) => c.channelId),
        resultChannelIds: result.results.map((r) => r.channelId),
      });
      throw new AnalysisError(
        `Result count mismatch: expected ${channels.length}, got ${result.results.length}`
      );
    }

    // Validate each result has required fields
    for (const item of result.results) {
      var missingFields = [];
      if (!item.channelId) missingFields.push("channelId");
      // if (!item.userName) missingFields.push("userName");
      if (!item.analyzedTitle) missingFields.push("analyzedTitle");
      if (!item.analyzedName) missingFields.push("analyzedName");
      if (missingFields.length > 0) {
        Logger.error("Missing required fields in result", {
          item,
          missingFields,
        });
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
        try {
          // Single AI call for batch
          const batchResult = await this.analyzeChannelsBatch(batch, size);

          processedCount += batchResult.results.length;

          onProgress(config.EVENTS.PROGRESS, {
            current: processedCount,
            total: totalChannels,
            message: `Analyzed ${processedCount} of ${totalChannels} channels`,
          });

          // Send batch results (even if empty array)
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
        } catch (batchError) {
          // Log error but continue processing remaining batches
          // Don't call onError here as it would end the SSE stream
          // Only log and continue - fatal errors will be caught by outer try-catch
          Logger.error(
            "Error processing batch, continuing with remaining batches",
            {
              error: batchError.message,
              batchSize: batch.length,
              errorStack: batchError.stack,
            }
          );

          // Continue processing remaining batches instead of stopping
          continue;
        }

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
