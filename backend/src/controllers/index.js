const VideoService = require("../services");

class VideoController {
  static async getChannel(req, res) {
    const { ids, useId, variant } = req.body;
    let isId = useId == "true" || useId == true;

    if (!ids) {
      return res.status(204).send();
    }

    const input = atob(ids);
    const idList = input.split(",");

    console.log(
      `${variant}: ${idList.length} ${isId ? "channelId(s)" : "username(s)"}`
    );

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

      if (firstFailure.name === "YouTubeAPIError") {
        if (firstFailure.status === 403) {
          return res.status(429).json({
            error:
              "The request cannot be completed because you have exceeded your quota",
            retryAfter: firstFailure.retryAfter,
          });
        } else if (firstFailure.status === 429) {
          return res.status(429).json({
            error: "Rate limit exceeded. Please try again later.",
            retryAfter: firstFailure.retryAfter,
          });
        } else if (firstFailure.status === 400) {
          return res.status(400).json({
            error: "Invalid request parameters",
            details: firstFailure.message,
          });
        }
      }

      // For other errors, return 500
      console.error("Unexpected error in getChannel:", firstFailure);
      return res.status(500).json({
        error: "Internal server error occurred while processing channels",
      });
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

    return res.status(200).send(result);
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
      console.error("Error in searchChannels:", error);

      if (error.name === "YouTubeAPIError") {
        if (error.status === 403) {
          return res.status(429).json({
            error:
              "The request cannot be completed because you have exceeded your quota",
            retryAfter: error.retryAfter,
          });
        } else if (error.status === 429) {
          return res.status(429).json({
            error: "Rate limit exceeded. Please try again later.",
            retryAfter: error.retryAfter,
          });
        } else if (error.status === 400) {
          return res.status(400).json({
            error: "Invalid search parameters",
            details: error.message,
          });
        }
      }

      return res.status(500).json({
        error: "Internal server error occurred while searching channels",
      });
    }
  }
}

module.exports = VideoController;
