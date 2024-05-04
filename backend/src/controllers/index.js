const VideoService = require("../services");
const VideoHelper = require("../helpers");

class VideoController {
  static async getChannel(req, res) {
    const { ids, useId, variant } = req.query;
    let isId = useId == "true";

    if (!ids) {
      return res.status(204);
    }

    const input = atob(ids);
    const idList = input.split(",");

    if (idList.length == 0) {
      return res.status(204);
    }

    let pending = [];

    for (let id of idList) {
      const data = isId
        ? VideoService.getChannelById(id, variant)
        : VideoService.getChannelByUsername(id, false, variant);
      if (data) {
        pending.push(data);
      }
    }

    if (pending.length == 0) {
      return res.status(204);
    }

    const internal = await Promise.allSettled(pending);
    const channels = internal
      .filter((e) => e.status === "fulfilled")
      .map((e) => e.value);

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

  static async getChannelsFromUrl(req, res) {
    const { url, variant } = req.query;

    if (!url) {
      return res.status(204);
    }

    let usernames = await VideoHelper.getChannelsFromUrl(url);

    let pending = [];

    for (let username of usernames) {
      const data = VideoService.getChannelByUsername(username, true, variant);
      if (data) {
        pending.push(data);
      }
    }

    if (pending.length == 0) {
      return res.status(204);
    }

    const internal = await Promise.allSettled(pending);
    const channels = internal
      .filter((e) => e.status === "fulfilled")
      .map((e) => e.value);

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

    if (!query) {
      return res.status(204);
    }

    let result = await VideoService.searchChannels(query, pageToken, variant);

    return res.status(200).send(result);
  }
}

module.exports = VideoController;
