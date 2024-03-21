const VideoService = require("../services");

class VideoController {
  static async getChannel(req, res) {
    const { ids } = req.query;
    if (!ids) {
      return res.status(204);
    }
    const input = atob(ids);
    const idList = input.split(",");

    if (idList.length == 0) {
      return res.status(204);
    }

    var pending = [];

    for (var id of idList) {
      const data = VideoService.getChannelByUsername(id);
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

    var pendingChannels = [];

    for (const channel of channels) {
      const data = VideoService.getVideosDataByChannel(channel);
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
    const { query } = req.query;

    if (!query) {
      return res.status(204);
    }

    var result = await VideoService.searchChannels(query);

    return res.status(200).send(result);
  }
}

module.exports = VideoController;
