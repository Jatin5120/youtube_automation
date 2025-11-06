const { google } = require("googleapis");
const { youtubeKey } = require("../helper");
const { retryWithBackoff } = require("../utils/retry");
const APIErrorHandler = require("../utils/apiErrorHandler");
const Logger = require("../utils/logger");
const config = require("../config");
const analysisConfig = require("../config/analysis");
const {
  channelStaticCache,
  channelStatsCache,
  searchCache,
  usernameToIdCache,
  CacheManager,
} = require("../utils/cache");
const quotaManager = require("../utils/quota");

// Internal constants for readability and to avoid magic strings
const YT_METHOD = {
  CHANNELS_LIST: "channels.list",
  SEARCH_LIST: "search.list",
};

const CHANNEL_PARTS = [
  "snippet",
  "id",
  "contentDetails",
  "statistics",
  "localizations",
  "topicDetails", // NEW: For channel topics/categories
  "brandingSettings", // NEW: For channel keywords
];

// Custom error classes
/**
 * Represents a YouTube API error with HTTP-like status and optional retryAfter.
 */
class YouTubeAPIError extends Error {
  constructor(message, status, retryAfter = null) {
    super(message);
    this.name = "YouTubeAPIError";
    this.status = status;
    this.retryAfter = retryAfter;
  }
}

/**
 * Service for interacting with YouTube API with caching, retry, batching, and quota safeguards.
 */
class YouTubeService {
  // In-flight request tracking to prevent duplicate API calls
  static _inFlightRequests = new Map();

  // ---------- Private utilities ----------

  static _getBatchSize() {
    return config.youtube.batchSize;
  }

  static _isValidChannelId(id) {
    return /^UC[a-zA-Z0-9_-]{22}$/.test(id);
  }

  static _dedupePreserveOrder(items) {
    const seen = new Set();
    const result = [];
    for (const item of items) {
      if (!seen.has(item)) {
        seen.add(item);
        result.push(item);
      }
    }
    return result;
  }

  static _toBatches(array, size) {
    const batches = [];
    for (let i = 0; i < array.length; i += size) {
      batches.push(array.slice(i, i + size));
    }
    return batches;
  }

  static _mapSettledFulfilled(results) {
    const merged = [];
    for (const r of results) {
      if (r.status === "fulfilled") {
        const value = r.value;
        if (Array.isArray(value)) {
          merged.push(...value);
        } else if (value !== undefined && value !== null) {
          merged.push(value);
        }
      }
    }
    return merged;
  }

  static _buildChannelsListParams(channelIds, variant) {
    return {
      key: youtubeKey(variant),
      part: CHANNEL_PARTS,
      id: channelIds.join(","),
    };
  }

  static _toYouTubeAPIError(error, method) {
    const apiError = APIErrorHandler.handleYouTubeError(error, method);
    return new YouTubeAPIError(
      apiError.message,
      apiError.status,
      apiError.retryAfter
    );
  }

  // Batch method to get multiple channels by IDs in a single API call
  /**
   * Fetch multiple channels by IDs in batches, leveraging caches and parallelism.
   * @param {string[]} channelIds
   * @param {string} variant
   * @returns {Promise<Array<object>>}
   */
  static async getChannelsByIds(channelIds, variant) {
    if (!channelIds || channelIds.length === 0) {
      return [];
    }

    // Validate channel IDs format
    const invalidIds = channelIds.filter(
      (id) => !id || typeof id !== "string" || id.trim() === ""
    );
    if (invalidIds.length > 0) {
      throw new YouTubeAPIError(
        `Invalid channel IDs: ${invalidIds.join(", ")}`,
        400
      );
    }

    // Clean and validate channel ID format
    const validChannelIds = this._dedupePreserveOrder(
      channelIds
        .map((id) => id.trim())
        .filter((id) => this._isValidChannelId(id))
    );

    if (validChannelIds.length === 0) {
      throw new YouTubeAPIError("No valid channel IDs provided", 400);
    }

    // Check if we need to batch the request (YouTube API limit is 50 IDs per request)
    const BATCH_SIZE = this._getBatchSize();
    if (validChannelIds.length <= BATCH_SIZE) {
      return await this._fetchChannelsBatch(validChannelIds, variant);
    } else {
      const batches = this._toBatches(validChannelIds, BATCH_SIZE);
      const batchPromises = batches.map((batch) =>
        this._fetchChannelsBatch(batch, variant)
      );
      const results = await Promise.allSettled(batchPromises);
      return this._mapSettledFulfilled(results);
    }
  }

  // Helper method to fetch a single batch of channels with optimized caching
  /**
   * Fetch a single batch of channels with cache lookups.
   * @param {string[]} channelIds
   * @param {string} variant
   */
  static async _fetchChannelsBatch(channelIds, variant) {
    // Check individual channel caches first
    const results = [];
    const uncachedIds = [];

    for (const channelId of channelIds) {
      try {
        const staticKey = CacheManager.getChannelStaticKey(channelId, variant);
        const statsKey = CacheManager.getChannelStatsKey(channelId, variant);

        const staticData = channelStaticCache.get(staticKey);
        const statsData = channelStatsCache.get(statsKey);

        if (staticData && statsData) {
          results.push({
            ...staticData,
            statistics: statsData,
          });
        } else {
          uncachedIds.push(channelId);
        }
      } catch (cacheError) {
        console.warn(
          `Cache error for channel ${channelId}:`,
          cacheError.message
        );
        uncachedIds.push(channelId);
      }
    }

    // If all channels are cached, return results
    if (uncachedIds.length === 0) {
      Logger.debug(`Cache hit for all ${channelIds.length} channels`);
      return results;
    }

    // Fetch uncached channels
    const fetchedChannels = await this._fetchUncachedChannels(
      uncachedIds,
      variant
    );

    // Combine cached and fetched results
    const allResults = [...results, ...fetchedChannels];

    // Sort by original order
    return channelIds
      .map((id) => allResults.find((channel) => channel.id === id))
      .filter(Boolean);
  }

  // Fetch uncached channels from API with race condition prevention
  /**
   * Fetch uncached channels from the API with in-flight request de-duplication.
   * @param {string[]} channelIds
   * @param {string} variant
   */
  static async _fetchUncachedChannels(channelIds, variant) {
    const requestKey = `channels_${channelIds.sort().join(",")}_${variant}`;

    // Check if request is already in flight
    if (this._inFlightRequests.has(requestKey)) {
      Logger.debug(`Request already in flight for: ${requestKey}`);
      return await this._inFlightRequests.get(requestKey);
    }

    // Create promise and store it
    const promise = retryWithBackoff(async () => {
      try {
        // Check quota before making request
        if (!quotaManager.canMakeRequest(YT_METHOD.CHANNELS_LIST)) {
          throw new YouTubeAPIError("Daily quota exceeded", 429);
        }

        const requestParams = this._buildChannelsListParams(
          channelIds,
          variant
        );

        const res = await google.youtube("v3").channels.list(requestParams);

        // Record quota usage
        quotaManager.recordUsage(YT_METHOD.CHANNELS_LIST);

        const channels = res.data.items || [];

        // Cache each channel separately with optimized TTLs
        for (const channel of channels) {
          const staticKey = CacheManager.getChannelStaticKey(
            channel.id,
            variant
          );
          const statsKey = CacheManager.getChannelStatsKey(channel.id, variant);

          // Cache static data for 24 hours
          channelStaticCache.set(staticKey, {
            id: channel.id,
            snippet: channel.snippet,
            contentDetails: channel.contentDetails,
            localizations: channel.localizations,
          });

          // Cache statistics for 6 hours
          channelStatsCache.set(statsKey, channel.statistics);
        }

        return channels;
      } catch (error) {
        throw this._toYouTubeAPIError(error, YT_METHOD.CHANNELS_LIST);
      }
    });

    // Store the promise and clean up when done
    this._inFlightRequests.set(requestKey, promise);

    try {
      const result = await promise;
      return result;
    } finally {
      this._inFlightRequests.delete(requestKey);
    }
  }

  // Process channels in batches with progress tracking (sequential)
  /**
   * Sequentially fetch channels in batches and invoke onProgress per batch.
   * @param {string[]} channelIds
   * @param {string} variant
   * @param {(progress: object) => Promise<void>|void} onProgress
   */
  static async getChannelsByIdsWithProgress(
    channelIds,
    variant,
    onProgress = null
  ) {
    if (!channelIds || channelIds.length === 0) {
      return [];
    }

    const BATCH_SIZE = this._getBatchSize(); // 50
    const totalBatches = Math.ceil(channelIds.length / BATCH_SIZE);

    Logger.info(
      `Processing ${channelIds.length} channels in ${totalBatches} batches (sequential)`,
      {
        totalChannels: channelIds.length,
        totalBatches,
      }
    );

    const allChannels = [];

    // Process batches sequentially
    for (let i = 0; i < channelIds.length; i += BATCH_SIZE) {
      const batch = channelIds.slice(i, i + BATCH_SIZE);
      const batchNumber = Math.floor(i / BATCH_SIZE) + 1;

      Logger.debug(
        `Processing batch ${batchNumber}/${totalBatches} (${batch.length} channels)`
      );

      try {
        const batchResult = await this._fetchChannelsBatch(batch, variant);
        allChannels.push(...batchResult);

        // Report progress with batch results (await to ensure upstream SSE writes complete)
        if (onProgress) {
          await onProgress({
            type: analysisConfig.EVENTS.BATCH,
            batchNumber,
            totalBatches,
            channelsInBatch: batchResult.length,
            channelsProcessed: allChannels.length,
            totalChannels: channelIds.length,
            progress: Math.round((batchNumber / totalBatches) * 100),
            batchResults: batchResult,
          });
        }
      } catch (error) {
        Logger.error(
          `Error processing batch ${batchNumber}: ${error.message}`,
          {
            batchNumber,
            totalBatches,
            error: error.message,
          }
        );

        // Report error for this batch (await to preserve ordering)
        if (onProgress) {
          await onProgress({
            type: analysisConfig.EVENTS.ERROR,
            batchNumber,
            error: error.message,
          });
        }
        // Continue with remaining batches
      }
    }

    return allChannels;
  }

  // Convert usernames to channel IDs first, then batch process
  /**
   * Resolve usernames to channel IDs, then fetch channel details.
   * @param {string[]} usernames
   * @param {string} variant
   */
  static async getChannelsByUsernames(usernames, variant) {
    if (!usernames || usernames.length === 0) {
      return [];
    }

    // Check cache first
    const cacheKey = `usernames_batch_${usernames.sort().join(",")}_${variant}`;
    const cached = channelStaticCache.get(cacheKey);
    if (cached) {
      Logger.debug(
        `Cache hit for batch usernames: ${usernames.length} usernames`
      );
      return cached;
    }

    // Convert usernames to channel IDs first
    const channelIdPromises = usernames.map((username) =>
      this.getChannelIdByUsername(username, variant)
    );

    const channelIds = await Promise.allSettled(channelIdPromises);
    const validChannelIds = channelIds
      .filter((result) => result.status === "fulfilled" && result.value)
      .map((result) => result.value);

    if (validChannelIds.length === 0) {
      channelStaticCache.set(cacheKey, []);
      return [];
    }

    // Now batch fetch all channels by IDs
    const channels = await this.getChannelsByIds(validChannelIds, variant);

    // Cache the result
    channelStaticCache.set(cacheKey, channels);
    return channels;
  }

  // Helper method to get channel ID by username
  /**
   * Get channel ID for a given @username (YouTube handle).
   * @param {string} username
   * @param {string} variant
   * @returns {Promise<string|null>}
   */
  static async getChannelIdByUsername(username, variant) {
    if (!username || typeof username !== "string") {
      return null;
    }

    const cacheKey = CacheManager.getUsernameKey(username, variant);
    const cached = usernameToIdCache.get(cacheKey);
    if (cached !== null) {
      return cached;
    }

    return retryWithBackoff(async () => {
      try {
        const res = await google.youtube("v3").channels.list({
          key: youtubeKey(variant),
          part: ["id"],
          forHandle: `@${username}`,
        });

        if (res.data.items && res.data.items.length > 0) {
          const channelId = res.data.items[0].id;
          usernameToIdCache.set(cacheKey, channelId);
          return channelId;
        }

        usernameToIdCache.set(cacheKey, null, 300000); // Cache null for 5 minutes
        return null;
      } catch (error) {
        Logger.error(
          `Error getting channel ID for username ${username}: ${error.message}`,
          {
            username,
            error: error.message,
          }
        );
        return null;
      }
    });
  }

  /**
   * Search channels by query with caching and pagination.
   * @param {string} query
   * @param {string|undefined} pageToken
   * @param {string} variant
   */
  static async searchChannels(query, pageToken, variant) {
    // Check cache first
    const cacheKey = `search_${query}_${pageToken || "first"}_${variant}`;
    const cached = searchCache.get(cacheKey);
    if (cached) {
      Logger.debug(`Cache hit for search query: ${query}`);
      return cached;
    }

    return retryWithBackoff(async () => {
      try {
        const res = await google.youtube("v3").search.list({
          key: youtubeKey(variant),
          part: ["snippet"],
          q: query,
          type: "channel",
          relevanceLanguage: "en",
          pageToken: pageToken,
          maxResults: 50,
        });

        const nextPageToken = res.data.nextPageToken;

        const data = res.data.items.map((e) => ({
          channelId: e.snippet.channelId,
          channelName: e.snippet.channelTitle,
          channelDescription: e.snippet.description,
        }));

        const result = { data, nextPageToken };
        // Cache search results
        searchCache.set(cacheKey, result);
        return result;
      } catch (error) {
        throw this._toYouTubeAPIError(error, YT_METHOD.SEARCH_LIST);
      }
    });
  }
}

module.exports = { YouTubeService, YouTubeAPIError };
