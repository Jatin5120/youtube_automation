require("dotenv").config();

function youtubeKey(variant) {
  if (variant == "development") {
    return process.env.DEV_YOUTUBE_API_KEY;
  }
  if (variant == "production") {
    return process.env.YOUTUBE_API_KEY;
  }
  return process.env.YOUTUBE_API_KEY;
}

module.exports = { youtubeKey };
