const VideoService = require("../services");
const VideoHelper = require("../helpers");

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
      return res.status(204).send();
    }

    const internal = await Promise.allSettled(pending);

    const isFailed = internal[0].status === "rejected";
    if (isFailed) {
      const status = internal[0].reason.status;

      if (status == 403) {
        return res.status(429).send({
          error:
            "The request cannot be completed because you have exceeded your quota",
        });
      }
    }

    const channels = internal
      .filter((e) => e.status === "fulfilled")
      .map((e) => e.value);

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

  static async getChannelsFromUrl(req, res) {
    const { url, variant } = req.query;

    if (!url) {
      return res.status(204).send();
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
      return res.status(204).send();
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
      return res.status(204).send();
    }

    return VideoService.searchChannels(query, pageToken, variant)
      .then((result) => res.status(200).send(result))
      .catch((error) => {
        const status = error.status;

        if (status == 403) {
          return res.status(429).send({
            error:
              "The request cannot be completed because you have exceeded your quota",
          });
        }
        return res.status(204).send();
      });
  }
}

module.exports = VideoController;
