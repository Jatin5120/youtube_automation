const { google } = require("googleapis");
const { isUploadedThisMonth, isUploadedInThreeMonth } = require("../utils");
const { youtubeKey } = require("../helper");
const { channelCache, searchCache, videoCache } = require("../utils/cache");
const quotaManager = require("../utils/quota");

// Custom error classes
class YouTubeAPIError extends Error {
  constructor(message, status, retryAfter = null) {
    super(message);
    this.name = "YouTubeAPIError";
    this.status = status;
    this.retryAfter = retryAfter;
  }
}

// Retry utility with exponential backoff
const retryWithBackoff = async (fn, maxRetries = 3, baseDelay = 1000) => {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      // Don't retry on client errors (4xx) except 429
      if (error.status >= 400 && error.status < 500 && error.status !== 429) {
        throw error;
      }

      const delay = baseDelay * Math.pow(2, attempt - 1);
      console.log(`Attempt ${attempt} failed, retrying in ${delay}ms...`);
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
};

module.exports = class VideoService {
  // Batch method to get multiple channels by IDs in a single API call
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

    // Clean and validate channel ID format (should start with UC and be 24 characters total)
    const validChannelIds = channelIds
      .map((id) => id.trim())
      .filter((id) => {
        return /^UC[a-zA-Z0-9_-]{22}$/.test(id);
      })
      .filter((id, index, array) => array.indexOf(id) === index); // Remove duplicates

    if (validChannelIds.length === 0) {
      throw new YouTubeAPIError("No valid channel IDs provided", 400);
    }

    // Check if we need to batch the request (YouTube API limit is 50 IDs per request)
    const BATCH_SIZE = 50;
    if (validChannelIds.length <= BATCH_SIZE) {
      // Single batch request
      return await this._fetchChannelsBatch(validChannelIds, variant);
    } else {
      // Multiple batch requests
      const batches = [];
      for (let i = 0; i < validChannelIds.length; i += BATCH_SIZE) {
        const batch = validChannelIds.slice(i, i + BATCH_SIZE);
        batches.push(batch);
      }

      // Process all batches in parallel
      const batchPromises = batches.map((batch) => {
        return this._fetchChannelsBatch(batch, variant);
      });

      const results = await Promise.allSettled(batchPromises);

      // Combine all successful results
      const allChannels = [];
      results.forEach((result) => {
        if (result.status === "fulfilled") {
          allChannels.push(...result.value);
        }
        // Continue with other batches even if one fails
      });

      return allChannels;
    }
  }

  // Helper method to fetch a single batch of channels
  static async _fetchChannelsBatch(channelIds, variant) {
    // Check cache first for this specific batch
    const cacheKey = `channels_batch_${channelIds.sort().join(",")}_${variant}`;
    const cached = channelCache.get(cacheKey);
    if (cached) {
      return cached;
    }

    return retryWithBackoff(async () => {
      try {
        // Check quota before making request
        if (!quotaManager.canMakeRequest("channels.list")) {
          throw new YouTubeAPIError("Daily quota exceeded", 429);
        }

        const requestParams = {
          key: youtubeKey(variant),
          part: [
            "snippet",
            "id",
            "contentDetails",
            "statistics",
            "localizations",
          ],
          id: channelIds.join(","), // Comma-separated list of channel IDs
        };

        const res = await google.youtube("v3").channels.list(requestParams);

        // Record quota usage
        quotaManager.recordUsage("channels.list");

        const result = res.data.items || [];

        // Cache successful results
        channelCache.set(cacheKey, result);
        return result;
      } catch (error) {
        if (error.response) {
          const status = error.response.status;
          const retryAfter = error.response.headers["retry-after"];

          if (status === 403) {
            throw new YouTubeAPIError("API quota exceeded", 403, retryAfter);
          } else if (status === 429) {
            throw new YouTubeAPIError("Rate limit exceeded", 429, retryAfter);
          } else if (status === 400) {
            const errorData = error.response.data;
            const errorMessage = errorData?.error?.message || error.message;
            throw new YouTubeAPIError(
              `Invalid request: ${errorMessage}`,
              400,
              null
            );
          }

          throw new YouTubeAPIError(
            `YouTube API error: ${error.message}`,
            status,
            retryAfter
          );
        }

        throw new YouTubeAPIError(`Network error: ${error.message}`, 500);
      }
    });
  }

  // Convert usernames to channel IDs first, then batch process
  static async getChannelsByUsernames(usernames, variant) {
    if (!usernames || usernames.length === 0) {
      return [];
    }

    // Check cache first
    const cacheKey = `usernames_batch_${usernames.sort().join(",")}_${variant}`;
    const cached = channelCache.get(cacheKey);
    if (cached) {
      console.log(
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
      channelCache.set(cacheKey, []);
      return [];
    }

    // Now batch fetch all channels by IDs
    const channels = await this.getChannelsByIds(validChannelIds, variant);

    // Cache the result
    channelCache.set(cacheKey, channels);
    return channels;
  }

  // Helper method to get channel ID by username
  static async getChannelIdByUsername(username, variant) {
    if (!username || typeof username !== "string") {
      return null;
    }

    const cacheKey = `channel_id_username_${username}_${variant}`;
    const cached = channelCache.get(cacheKey);
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
          channelCache.set(cacheKey, channelId);
          return channelId;
        }

        channelCache.set(cacheKey, null, 300000); // Cache null for 5 minutes
        return null;
      } catch (error) {
        console.error(
          `Error getting channel ID for username ${username}:`,
          error.message
        );
        return null;
      }
    });
  }

  static async getChannelByUsername(username, useSearchAPI, variant) {
    if (!username || typeof username !== "string") {
      throw new YouTubeAPIError("Invalid username provided", 400);
    }

    // Check cache first
    const cacheKey = `channel_username_${username}_${useSearchAPI}_${variant}`;
    const cached = channelCache.get(cacheKey);
    if (cached) {
      console.log(`Cache hit for channel username: ${username}`);
      return cached;
    }

    return retryWithBackoff(async () => {
      try {
        const res = await google.youtube("v3").channels.list({
          key: youtubeKey(variant),
          part: [
            "snippet",
            "id",
            "contentDetails",
            "statistics",
            "localizations",
          ],
          forHandle: useSearchAPI == true ? username : `@${username}`,
        });

        if (
          res.data == null ||
          res.data.items == null ||
          res.data.items.length === 0
        ) {
          // Cache null results for shorter time to avoid repeated API calls
          channelCache.set(cacheKey, null, 300000); // 5 minutes
          return null;
        }

        const result = res.data.items[0];
        // Cache successful results
        channelCache.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error(
          `Error fetching channel by username ${username}:`,
          error.message
        );

        if (error.response) {
          const status = error.response.status;
          const retryAfter = error.response.headers["retry-after"];

          if (status === 403) {
            throw new YouTubeAPIError("API quota exceeded", 403, retryAfter);
          } else if (status === 404) {
            return null; // Channel not found
          } else if (status === 429) {
            throw new YouTubeAPIError("Rate limit exceeded", 429, retryAfter);
          }

          throw new YouTubeAPIError(
            `YouTube API error: ${error.message}`,
            status,
            retryAfter
          );
        }

        throw new YouTubeAPIError(`Network error: ${error.message}`, 500);
      }
    });
  }

  static async getChannelById(id, variant) {
    if (!id || typeof id !== "string") {
      throw new YouTubeAPIError("Invalid channel ID provided", 400);
    }

    // Check cache first
    const cacheKey = `channel_id_${id}_${variant}`;
    const cached = channelCache.get(cacheKey);
    if (cached) {
      console.log(`Cache hit for channel ID: ${id}`);
      return cached;
    }

    return retryWithBackoff(async () => {
      try {
        const res = await google.youtube("v3").channels.list({
          key: youtubeKey(variant),
          part: ["snippet", "id", "contentDetails", "statistics"],
          id: id,
        });

        if (
          res.data == null ||
          res.data.items == null ||
          res.data.items.length === 0
        ) {
          // Cache null results for shorter time to avoid repeated API calls
          channelCache.set(cacheKey, null, 300000); // 5 minutes
          return null;
        }

        const result = res.data.items[0];
        // Cache successful results
        channelCache.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error(`Error fetching channel by ID ${id}:`, error.message);

        if (error.response) {
          const status = error.response.status;
          const retryAfter = error.response.headers["retry-after"];

          if (status === 403) {
            throw new YouTubeAPIError("API quota exceeded", 403, retryAfter);
          } else if (status === 404) {
            return null; // Channel not found
          } else if (status === 429) {
            throw new YouTubeAPIError("Rate limit exceeded", 429, retryAfter);
          }

          throw new YouTubeAPIError(
            `YouTube API error: ${error.message}`,
            status,
            retryAfter
          );
        }

        throw new YouTubeAPIError(`Network error: ${error.message}`, 500);
      }
    });
  }

  static async getVideosDataByChannel(channel, variant) {
    if (!channel) {
      return null;
    }

    const description = channel.snippet.description;
    const subscriberCount = channel.statistics.subscriberCount;
    const totalVideos = channel.statistics.videoCount;
    var channelId = channel.contentDetails.relatedPlaylists.uploads;
    const playlist = await this.getPlaylists(channelId, variant);
    const videosThisMonth = playlist.videosThisMonth;
    const videosLastThreeMonths = playlist.videosLastThreeMonths;
    const uploadedThisMonth = isUploadedThisMonth(
      Date.parse(videosThisMonth[0].snippet.publishedAt)
    );
    const uploadedLastThreeMonths = isUploadedThisMonth(
      Date.parse(videosLastThreeMonths[0].snippet.publishedAt)
    );
    return {
      subscriberCount,
      totalVideos,
      description,
      channelName: channel.snippet.title,
      userName: channel.snippet.customUrl,
      country: channel.snippet.country,
      totalVideosLastMonth: uploadedThisMonth ? videosThisMonth.length : 0,
      totalVideosLastThreeMonths: uploadedLastThreeMonths
        ? videosLastThreeMonths.length
        : 0,
      latestVideoTitle: videosThisMonth[0].snippet.title,
      lastUploadDate: videosThisMonth[0].snippet.publishedAt,
      language: playlist.language,
      uploadedThisMonth: uploadedThisMonth,
    };
  }

  static async getPlaylists(id, variant) {
    const res = await google.youtube("v3").playlists.list({
      key: youtubeKey(variant),
      part: ["contentDetails", "snippet"],
      id: id,
      maxResults: 1,
    });
    const language = res.data.items[0].snippet.defaultLanguage;
    var videos = await this.getPlaylistVideos(res.data.items[0].id, variant);
    return {
      videosThisMonth: videos.videosThisMonth,
      videosLastThreeMonths: videos.videosLastThreeMonths,
      language,
    };
  }

  static async getPlaylistVideos(id, variant) {
    const res = await google.youtube("v3").playlistItems.list({
      key: youtubeKey(variant),
      part: ["contentDetails", "snippet"],
      playlistId: id,
      maxResults: 50,
    });

    if (res.data.items.length === 0) {
      return [];
    }
    var videosThisMonth = [];
    var videosLastThreeMonths = [];
    for await (var item of res.data.items) {
      try {
        var date = Date.parse(item.snippet.publishedAt);
        if (isUploadedThisMonth(date)) {
          videosThisMonth.push(item);
          videosLastThreeMonths.push(item);
        } else if (isUploadedInThreeMonth(date)) {
          videosLastThreeMonths.push(item);
        } else {
          break;
        }
      } catch (e) {
        console.log(e);
      }
    }
    if (videosThisMonth.length === 0) {
      videosThisMonth.push(res.data.items[0]);
    }
    if (videosLastThreeMonths.length === 0) {
      videosLastThreeMonths.push(res.data.items[0]);
    }

    return {
      videosThisMonth: videosThisMonth,
      videosLastThreeMonths: videosLastThreeMonths,
    };
  }

  static async searchChannels(query, pageToken, variant) {
    // Check cache first
    const cacheKey = `search_${query}_${pageToken || "first"}_${variant}`;
    const cached = searchCache.get(cacheKey);
    if (cached) {
      console.log(`Cache hit for search query: ${query}`);
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
          title: e.snippet.title,
          description: e.snippet.description,
        }));

        const result = { data, nextPageToken };
        // Cache search results
        searchCache.set(cacheKey, result);
        return result;
      } catch (error) {
        console.error(
          `Error searching channels for query ${query}:`,
          error.message
        );

        if (error.response) {
          const status = error.response.status;
          const retryAfter = error.response.headers["retry-after"];

          if (status === 403) {
            throw new YouTubeAPIError("API quota exceeded", 403, retryAfter);
          } else if (status === 429) {
            throw new YouTubeAPIError("Rate limit exceeded", 429, retryAfter);
          }

          throw new YouTubeAPIError(
            `YouTube API error: ${error.message}`,
            status,
            retryAfter
          );
        }

        throw new YouTubeAPIError(`Network error: ${error.message}`, 500);
      }
    });
  }
};
