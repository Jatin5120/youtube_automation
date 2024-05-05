const { google } = require("googleapis");
const { isUploadedThisMonth, isUploadedInThreeMonth } = require("../utils");
const { searchKey, youtubeKey } = require("../helper");

module.exports = class VideoService {
  static async getChannelByUsername(username, useSearchAPI, variant) {
    try {
      const res = await google.youtube("v3").channels.list({
        key: useSearchAPI == true ? searchKey(variant) : youtubeKey(variant),
        part: [
          "snippet",
          "id",
          "contentDetails",
          "statistics",
          "localizations",
        ],
        forHandle: useSearchAPI == true ? username : `@${username}`,
      });

      if (res.data.items.length === 0) {
        return null;
      }

      var item = res.data.items[0];

      return item;
    } catch (e) {
      console.log(e);
    }
  }

  static async getChannelById(id, variant) {
    try {
      console.log("getChannelById");
      const res = await google.youtube("v3").channels.list({
        key: youtubeKey(variant),
        part: [
          "snippet",
          "id",
          "contentDetails",
          "statistics",
          "localizations",
        ],
        id: id,
      });

      if (res.data.items.length === 0) {
        return null;
      }
      console.log(res.data.items.length);

      var item = res.data.items[0];

      return item;
    } catch (e) {
      console.log(e);
      return null;
    }
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
    console.log("getPlaylists");
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
    const res = await google.youtube("v3").search.list({
      key: searchKey(variant),
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

    return { data, nextPageToken };
  }
};
