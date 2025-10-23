const config = require("../config");
const Logger = require("../utils/logger");

function youtubeKey(variant) {
  const key =
    config.apiKeys.youtube[variant] || config.apiKeys.youtube.production;

  if (!key) {
    Logger.error(`YouTube API key not found for variant: ${variant}`);
    throw new Error(`YouTube API key not configured for variant: ${variant}`);
  }

  return key;
}

function openaiKey() {
  const key = config.apiKeys.openai;

  if (!key) {
    Logger.error("OpenAI API key not found");
    throw new Error("OpenAI API key not configured");
  }

  return key;
}

// Validate all required API keys on startup
function validateApiKeys() {
  try {
    youtubeKey("development");
    youtubeKey("production");
    openaiKey();
  } catch (error) {
    Logger.error("API key validation failed", error);
    throw error;
  }
}

module.exports = {
  youtubeKey,
  openaiKey,
  validateApiKeys,
};
