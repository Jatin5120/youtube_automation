// Centralized configuration management
require("dotenv").config();

const config = {
  // Server Configuration
  server: {
    port: process.env.PORT || 3000,
    env: process.env.NODE_ENV || "development",
    trustProxy: process.env.TRUST_PROXY === "true",
  },

  // API Keys
  apiKeys: {
    youtube: {
      development: process.env.DEV_YOUTUBE_API_KEY,
      production: process.env.YOUTUBE_API_KEY,
    },
    openai: process.env.OPENAI_API_KEY,
    apify: process.env.APIFY_API_TOKEN,
  },

  // Rate Limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX) || 100,
    message: "Too many requests from this IP, please try again later.",
  },

  // CORS Configuration
  cors: {
    origin: process.env.CORS_ORIGIN || "*",
    credentials: process.env.CORS_CREDENTIALS === "true",
  },

  // YouTube API Configuration
  youtube: {
    quota: {
      daily: parseInt(process.env.YOUTUBE_DAILY_QUOTA) || 10000,
      lowThreshold: parseFloat(process.env.YOUTUBE_QUOTA_LOW_THRESHOLD) || 0.8,
    },
    batchSize: parseInt(process.env.YOUTUBE_BATCH_SIZE) || 50,
  },

  // Apify Configuration
  apify: {
    actorId: "exporter24/youtube-email-bulk-scraper",
    timeout: parseInt(process.env.APIFY_TIMEOUT) || 300000, // 5 minutes
    maxRetries: parseInt(process.env.APIFY_MAX_RETRIES) || 3,
  },

  // Logging Configuration
  logging: {
    level: process.env.LOG_LEVEL || "info",
    enableRequestLogging: process.env.LOG_REQUESTS === "true",
  },

  // Request Timeout Configuration
  timeout: {
    default: parseInt(process.env.REQUEST_TIMEOUT) || 30000, // 30 seconds
    analysis: parseInt(process.env.ANALYSIS_TIMEOUT) || 120000, // 2 minutes for analysis
    sse: parseInt(process.env.SSE_TIMEOUT) || 300000, // 5 minutes for SSE
  },
};

// Validation
const validateConfig = () => {
  const required = [
    "apiKeys.youtube.development",
    "apiKeys.youtube.production",
    "apiKeys.openai",
  ];

  const missing = required.filter((key) => {
    const value = key.split(".").reduce((obj, k) => obj?.[k], config);
    return !value;
  });

  if (missing.length > 0) {
    throw new Error(`Missing required configuration: ${missing.join(", ")}`);
  }
};

// Validate configuration on startup
if (config.server.env === "production") {
  validateConfig();
}

module.exports = config;
