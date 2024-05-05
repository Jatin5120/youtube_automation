require("dotenv").config();

function youtubeKey(variant) {
  if (variant == "development") {
    return process.env.YOUTUBE_API_KEY;
  }
  if (variant == "variant1") {
    return process.env.YOUTUBE_API_KEY_VARIANT1;
  }
  if (variant == "variant2") {
    return process.env.YOUTUBE_API_KEY_VARIANT2;
  }
  if (variant == "variant3") {
    return process.env.YOUTUBE_API_KEY_VARIANT3;
  }
  if (variant == "variant4") {
    return process.env.YOUTUBE_API_KEY_VARIANT4;
  }
  if (variant == "variant5") {
    return process.env.YOUTUBE_API_KEY_VARIANT5;
  }
  return process.env.YOUTUBE_API_KEY;
}

function searchKey(variant) {
  if (variant == "development") {
    return process.env.SEARCH_API_KEY;
  }
  if (variant == "variant1") {
    return process.env.SEARCH_API_KEY_VARIANT1;
  }
  if (variant == "variant2") {
    return process.env.SEARCH_API_KEY_VARIANT2;
  }
  if (variant == "variant3") {
    return process.env.SEARCH_API_KEY_VARIANT3;
  }
  if (variant == "variant4") {
    return process.env.SEARCH_API_KEY_VARIANT4;
  }
  if (variant == "variant5") {
    return process.env.SEARCH_API_KEY_VARIANT5;
  }
  return process.env.SEARCH_API_KEY;
}

module.exports = { youtubeKey, searchKey };
