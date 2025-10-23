const { google } = require("googleapis");
const { youtubeKey } = require("../helper");
const { isUploadedThisMonth, isUploadedInThreeMonth } = require("../utils");
const { retryWithBackoff } = require("../utils/retry");
const APIErrorHandler = require("../utils/apiErrorHandler");
const { YouTubeService } = require("./youtubeService");

class VideoService {
  // Delegate to YouTubeService for channel operations
  static async getChannelsByIds(channelIds, variant) {
    return YouTubeService.getChannelsByIds(channelIds, variant);
  }

  static async getChannelsByUsernames(usernames, variant) {
    return YouTubeService.getChannelsByUsernames(usernames, variant);
  }

  static async getChannelByUsername(username, useSearchAPI, variant) {
    // This method is not used in the current implementation
    // but kept for backward compatibility
    throw new Error(
      "Method not implemented - use getChannelsByUsernames instead"
    );
  }

  static async getChannelById(id, variant) {
    // This method is not used in the current implementation
    // but kept for backward compatibility
    throw new Error("Method not implemented - use getChannelsByIds instead");
  }

  // Video data operations
  static async getVideosDataByChannel(channel, variant) {
    if (!channel) {
      return null;
    }

    const description = channel.snippet.description;
    const subscriberCount = channel.statistics.subscriberCount;
    const totalVideos = channel.statistics.videoCount;
    const channelId = channel.contentDetails.relatedPlaylists.uploads;

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
      channelId,
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
    const videos = await this.getPlaylistVideos(res.data.items[0].id, variant);

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

    const videosThisMonth = [];
    const videosLastThreeMonths = [];

    for (const item of res.data.items) {
      try {
        const date = Date.parse(item.snippet.publishedAt);
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

  // Delegate to YouTubeService for search operations
  static async searchChannels(query, pageToken, variant) {
    return YouTubeService.searchChannels(query, pageToken, variant);
  }
}

module.exports = VideoService;
