const config = require("../config/analysis");
const VideoService = require("../services/videoService");
const APIErrorHandler = require("../utils/apiErrorHandler");
const Logger = require("../utils/logger");
const AnalysisController = require("./analysisController");

class VideoController {
  static async getChannel(req, res) {
    const { ids, useId, variant } = req.body;
    let isId = useId == "true" || useId == true;

    if (!ids) {
      return res.status(204).send();
    }

    const input = atob(ids);
    const idList = input.split(",");

    if (idList.length == 0) {
      return res.status(204).send();
    }

    // Separate channel IDs and usernames for batch processing
    const channelIds = [];
    const usernames = [];

    for (let id of idList) {
      if (isId) {
        channelIds.push(id);
      } else {
        usernames.push(id);
      }
    }

    // Remove duplicates from both arrays
    const uniqueChannelIds = [...new Set(channelIds)];
    const uniqueUsernames = [...new Set(usernames)];

    // Batch process both types
    const batchPromises = [];

    if (uniqueChannelIds.length > 0) {
      batchPromises.push(
        VideoService.getChannelsByIds(uniqueChannelIds, variant)
      );
    }

    if (uniqueUsernames.length > 0) {
      batchPromises.push(
        VideoService.getChannelsByUsernames(uniqueUsernames, variant)
      );
    }

    if (batchPromises.length === 0) {
      return res.status(204).send();
    }

    const batchResults = await Promise.allSettled(batchPromises);

    // Check for any failures and handle them appropriately
    const failures = batchResults.filter(
      (result) => result.status === "rejected"
    );
    if (failures.length > 0) {
      const firstFailure = failures[0].reason;
      return APIErrorHandler.sendErrorResponse(res, firstFailure);
    }

    const channels = batchResults
      .filter((result) => result.status === "fulfilled")
      .flatMap((result) => result.value)
      .filter((channel) => channel !== null);

    if (channels.length == 0) {
      return res.status(204).send();
    }

    let pendingChannels = [];

    for (const channel of channels) {
      const data = VideoService.getVideosDataByChannel(channel, variant);
      if (data) {
        pendingChannels.push(data);
      }
    }

    const internalChannels = await Promise.allSettled(pendingChannels);
    const result = internalChannels
      .filter((e) => e.status === "fulfilled")
      .map((e) => e.value);

    return res.status(200).json(result);
  }

  // SSE streaming endpoint for large channel batches
  static async getChannelStream(req, res) {
    const { ids, useId, variant } = req.body;
    const isId = useId == "true" || useId == true;

    const input = atob(ids);
    const idList = input
      .split(",")
      .map((id) => id.trim())
      .filter(Boolean);

    Logger.info(`Streaming ${idList.length} channels`, {
      type: isId ? "channelId" : "username",
      count: idList.length,
    });

    // Set SSE headers (following sod-messages pattern)
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Cache-Control",
    });

    // Handle client disconnect
    req.on("close", () => {
      Logger.debug("Client disconnected from channel stream");
    });

    try {
      // Send initial started event
      AnalysisController._writeSSESafe(res, config.EVENTS.STARTED, null, () =>
        res.end()
      );

      AnalysisController._writeSSESafe(
        res,
        config.EVENTS.PROGRESS,
        {
          current: 0,
          total: idList.length,
          message: "Starting to fetch channel details...",
        },
        () => res.end()
      );

      // Separate channel IDs and usernames
      const channelIds = [];
      const usernames = [];

      if (isId) {
        channelIds.push(...idList);
      } else {
        usernames.push(...idList);
      }

      const uniqueChannelIds = [...new Set(channelIds)];
      const uniqueUsernames = [...new Set(usernames)];

      const { YouTubeService } = require("../services/youtubeService");

      // Process channel IDs with streaming progress
      if (uniqueChannelIds.length > 0) {
        await YouTubeService.getChannelsByIdsWithProgress(
          uniqueChannelIds,
          variant,
          async (progressData) => {
            if (progressData.type === config.EVENTS.BATCH) {
              // Process video data for this batch
              const batchChannels = progressData.batchResults;
              const pendingVideos = [];

              for (const channel of batchChannels) {
                const videoData = VideoService.getVideosDataByChannel(
                  channel,
                  variant
                );
                if (videoData) {
                  pendingVideos.push(videoData);
                }
              }

              const results = await Promise.allSettled(pendingVideos);
              const batchVideoData = results
                .filter((e) => e.status === "fulfilled")
                .map((e) => e.value);

              AnalysisController._writeSSESafe(
                res,
                config.EVENTS.PROGRESS,
                {
                  current: progressData.channelsInBatch,
                  total: progressData.channelsProcessed,
                  message: `Processed batch ${progressData.channelsInBatch} of ${progressData.channelsProcessed}`,
                },
                () => res.end()
              );

              // Send batch result
              AnalysisController._writeSSESafe(
                res,
                config.EVENTS.BATCH,
                {
                  batchNumber: progressData.batchNumber,
                  totalBatches: progressData.totalBatches,
                  data: batchVideoData,
                },
                () => res.end()
              );
            } else if (progressData.type === config.EVENTS.ERROR) {
              AnalysisController._writeSSESafe(
                res,
                config.EVENTS.ERROR,
                {
                  message: progressData.error,
                  batchNumber: progressData.batchNumber,
                },
                () => res.end()
              );
            }
          }
        );
      }

      // Process usernames if any (typically not needed for streaming)
      if (uniqueUsernames.length > 0) {
        const usernameChannels = await VideoService.getChannelsByUsernames(
          uniqueUsernames,
          variant
        );

        const pendingVideos = [];
        for (const channel of usernameChannels) {
          const videoData = VideoService.getVideosDataByChannel(
            channel,
            variant
          );
          if (videoData) {
            pendingVideos.push(videoData);
          }
        }

        const results = await Promise.allSettled(pendingVideos);
        const usernameVideoData = results
          .filter((e) => e.status === "fulfilled")
          .map((e) => e.value);

        if (usernameVideoData.length > 0) {
          AnalysisController._writeSSESafe(
            res,
            config.EVENTS.BATCH,
            {
              batchNumber: "usernames",
              current: usernameVideoData.length,
              total: idList.length,
              data: usernameVideoData,
            },
            () => res.end()
          );
        }
      }

      // Send completion event
      AnalysisController._writeSSESafe(
        res,
        config.EVENTS.COMPLETE,
        { success: true },
        () => res.end()
      );
    } catch (error) {
      console.error("Error in getChannelStream:", error);
      AnalysisController._writeSSESafe(
        res,
        config.EVENTS.ERROR,
        { message: error.message },
        () => res.end()
      );
    } finally {
      res.end();
    }
  }

  static async searchChannels(req, res) {
    const { query, pageToken, variant } = req.query;

    try {
      const result = await VideoService.searchChannels(
        query,
        pageToken,
        variant
      );

      return res.status(200).json(result);
    } catch (error) {
      return APIErrorHandler.sendErrorResponse(res, error);
    }
  }

  // Cache monitoring endpoint
  static async getCacheStats(req, res) {
    try {
      const { CacheManager } = require("../utils/cache");
      const stats = CacheManager.getCacheStats();

      return res.status(200).json({
        success: true,
        data: stats,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      return res.status(500).json({
        error: "Failed to retrieve cache statistics",
      });
    }
  }

  // Cache invalidation endpoint
  static async invalidateCache(req, res) {
    const { channelId, variant } = req.body;

    try {
      const { CacheManager } = require("../utils/cache");

      if (channelId) {
        CacheManager.invalidateChannelData(channelId, variant);

        return res.status(200).json({
          success: true,
          message: `Cache invalidated for channel ${channelId}`,
        });
      } else {
        // Clear all caches
        const {
          channelStaticCache,
          channelStatsCache,
          searchCache,
          usernameToIdCache,
        } = require("../utils/cache");

        channelStaticCache.clear();
        channelStatsCache.clear();
        searchCache.clear();
        usernameToIdCache.clear();

        return res.status(200).json({
          success: true,
          message: "All caches cleared",
        });
      }
    } catch (error) {
      return res.status(500).json({
        error: "Failed to invalidate cache",
      });
    }
  }
}

module.exports = VideoController;
