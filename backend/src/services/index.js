require("dotenv").config();
const { google } = require("googleapis");
const { isUploadedThisMonth } = require("../utils");

module.exports = class VideoService {
  static YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;

  static async getChannelByUsername(username) {
    const res = await google.youtube("v3").channels.list({
      key: this.YOUTUBE_API_KEY,
      part: ["snippet", "id", "contentDetails", "statistics"],
      forHandle: `@${username}`,
    });

    if (res.data.items.length === 0) {
      return null;
    }

    var item = res.data.items[0];

    return item;
  }

  static async getChannelById(id) {
    const res = await google.youtube("v3").channels.list({
      key: this.YOUTUBE_API_KEY,
      part: ["snippet", "id", "contentDetails", "statistics"],
      id: id,
    });

    if (res.data.items.length === 0) {
      return null;
    }

    var item = res.data.items[0];

    return item;
  }

  static async getVideosDataByChannel(channel) {
    if (!channel) {
      return null;
    }

    const description = channel.snippet.description;
    const subscriberCount = channel.statistics.subscriberCount;
    const totalVideos = channel.statistics.videoCount;
    var channelId = channel.contentDetails.relatedPlaylists.uploads;
    const videos = await this.getPlaylists(channelId);
    const uploadedThisMonth = isUploadedThisMonth(
      Date.parse(videos[0].snippet.publishedAt)
    );
    return {
      subscriberCount,
      totalVideos,
      description,
      channelName: channel.snippet.title,
      userName: channel.snippet.customUrl,
      totalVideosLastMonth: uploadedThisMonth ? videos.length : 0,
      latestVideoTitle: videos[0].snippet.title,
      lastUploadDate: videos[0].snippet.publishedAt,
      uploadedThisMonth: uploadedThisMonth,
    };
  }

  static async getPlaylists(id) {
    const res = await google.youtube("v3").playlists.list({
      key: this.YOUTUBE_API_KEY,
      part: ["contentDetails", "snippet"],
      id: id,
      maxResults: 1,
    });
    return await this.getPlaylistVideos(res.data.items[0].id);
  }

  static async getPlaylistVideos(id) {
    const res = await google.youtube("v3").playlistItems.list({
      key: this.YOUTUBE_API_KEY,
      part: ["contentDetails", "snippet"],
      playlistId: id,
      maxResults: 50,
    });

    if (res.data.items.length === 0) {
      return [];
    }
    var videos = [];
    for await (var item of res.data.items) {
      try {
        var date = Date.parse(item.snippet.publishedAt);
        if (!isUploadedThisMonth(date)) {
          break;
        }
        videos.push(item);
      } catch (e) {
        console.log(e);
      }
    }
    if (videos.length === 0) {
      videos.push(res.data.items[0]);
    }

    return videos;
  }
};
