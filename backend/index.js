require("dotenv").config();
const { google } = require("googleapis");

const YOUTUBE_API_KEY = process.env.YOUTUBE_API_KEY;

async function getChannel(id) {
  const res = await google.youtube("v3").channels.list({
    key: YOUTUBE_API_KEY,
    part: ["snippet", "id", "contentDetails", "statistics"],
    id: id,
    // forHandle: "@anotherhomosapien",
    // forHandle: ["@flutterdev", "@anotherhomosapien"],
  });

  if (res.data.items.length === 0) {
    console.log("No channels found");
    return;
  }

  var item = res.data.items[0];
  //   console.log(item);
  const subscriberCount = item.statistics.subscriberCount;
  const totalVideos = item.statistics.videoCount;
  var channelId = item.contentDetails.relatedPlaylists.uploads;
  const videos = await getPlaylists(channelId);
  return {
    subscriberCount,
    totalVideos,
    channelName: item.snippet.title,
    userName: item.snippet.customUrl,
    totalVideosLastMonth: videos.length,
    latestVideoTitle: videos[0].snippet.title,
    lastUploadDate: videos[0].snippet.publishedAt,
    uploadedThisMonth: isUploadedThisMonth(
      Date.parse(videos[0].snippet.publishedAt)
    ),
  };
}

async function getPlaylists(id) {
  const res = await google.youtube("v3").playlists.list({
    key: YOUTUBE_API_KEY,
    part: ["contentDetails", "snippet"],
    id: id,
    maxResults: 1,
  });
  return await getPlaylistVideos(res.data.items[0].id);
}

async function getPlaylistVideos(id) {
  const res = await google.youtube("v3").playlistItems.list({
    key: YOUTUBE_API_KEY,
    part: ["contentDetails", "snippet"],
    playlistId: id,
    maxResults: 50,
  });

  if (res.data.items.length === 0) {
    console.log("No videos found");
    return;
  }
  //   var videoType = {};
  var videos = [];
  for await (var item of res.data.items) {
    // console.log(item.snippet);
    try {
      var date = Date.parse(item.snippet.publishedAt);
      if (!isUploadedThisMonth(date)) {
        break;
      }
      videos.push(item);
    } catch (e) {
      console.log(e);
    }

    // const videoId = item.contentDetails.videoId;
    // const details = await getVideoDetails(videoId);

    // const duration = details.contentDetails.duration;
    // const isShortVideo = isYouTubeShort(duration);
    // if (!isShortVideo) {
    //   videoType["videos"] = (videoType["videos"] || 0) + 1;
    // } else {
    //   videoType["shorts"] = (videoType["shorts"] || 0) + 1;
    // }
  }
  if (videos.length === 0) {
    videos.push(res.data.items[0]);
  }

  return videos;

  //   console.log(videoType);
}

async function getVideoDetails(id) {
  const res = await google.youtube("v3").videos.list({
    key: YOUTUBE_API_KEY,
    part: [
      "snippet",
      "contentDetails",
      "statistics",
      "topicDetails",
      // "processingDetails",
      "statistics",
      "liveStreamingDetails",
      // "fileDetails",
    ],
    id: id,
  });

  //   console.log(res.data.items[0]);

  return res.data.items[0];
}

function isYouTubeShort(dur) {
  var duration = dur.replace("PT", "");
  // Convert the duration string to seconds
  function durationToSeconds(time) {
    let seconds = 0;
    const matches = duration.match(/(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);

    if (matches) {
      if (matches[1]) seconds += parseInt(matches[1]) * 3600; // hours
      if (matches[2]) seconds += parseInt(matches[2]) * 60; // minutes
      if (matches[3]) seconds += parseInt(matches[3]); // seconds
    }

    return seconds;
  }

  const thresholdInSeconds = 65; // Set your threshold duration in seconds
  const videoDurationInSeconds = durationToSeconds(duration);

  return videoDurationInSeconds < thresholdInSeconds;
}

function isUploadedThisMonth(date) {
  const now = Date.now();
  const _MS_PER_DAY = 1000 * 60 * 60 * 24;
  const diff = Math.ceil((now - date) / _MS_PER_DAY);
  return diff <= 30;
}

function search() {
  google
    .youtube("v3")
    .search.list({
      key: YOUTUBE_API_KEY,
      part: ["snippet"],
      q: "productivity",
      type: "channel",
      maxResults: 50,
    })
    .then(async (res) => {
      //   console.log(res.data);
      var pending = [];

      for (var item of res.data.items) {
        // console.log(item.snippet);
        const data = getChannel(item.snippet.channelId);
        // console.log(`${i + 1}: ${item.snippet.title}`);
        pending.push(data);
      }
      var internal = await Promise.allSettled(pending);
      var result = internal
        .filter((e) => e.status === "fulfilled")
        .map((e) => e.value);

      console.log(result);
    });
}

// function getCategories() {
//   google
//     .youtube("v3")
//     .videoCategories.list({
//       key: YOUTUBE_API_KEY,
//       part: ["snippet"],
//       //   id: id,
//       regionCode: "IN",
//     })
//     .then((res) => {
//       console.log(res.data.items);
//     });
// }

function getData() {
  getChannel().then((data) => {
    console.log(data);
  });
}

// getData();
// getChannel();
// getVideos();
// getPlaylists();
// getPlaylistDetails();
// getCategories();
search();
