// Analysis service configuration
module.exports = {
  // OpenAI Configuration
  OPENAI: {
    MODEL: "gpt-4.1-nano",
    TEMPERATURE: 0.1,
    TOP_P: 0.8,
    MAX_TOKENS: 800,
    TIMEOUT: 15000,
    EMAIL_TEMPERATURE: 0.7,
    EMAIL_MAX_TOKENS: 90,
  },

  // Cache Configuration
  CACHE: {
    TTL: 7 * 24 * 60 * 60 * 1000, // 7 days in milliseconds
    MAX_ENTRIES: 5000,
  },

  // Batch Processing Configuration
  BATCH: {
    CHANNELS_PER_BATCH: 5, // Configurable for testing
    RATE_LIMIT_DELAY: 500, // 500ms - optimized for better throughput
    MAX_RETRIES: 3,
    RETRY_DELAY: 1000, // 1 second
    MUTEX_CLEANUP_INTERVAL: 300000, // 5 minutes
    MUTEX_MAX_AGE: 300000, // 5 minutes
  },

  // Response Schema for OpenAI JSON mode
  RESPONSE_SCHEMA: {
    type: "object",
    properties: {
      results: {
        type: "array",
        items: {
          type: "object",
          properties: {
            channelId: { type: "string" },
            userName: { type: "string" },
            analyzedTitle: { type: "string" },
            analyzedName: { type: "string" },
          },
          required: ["channelId", "userName", "analyzedTitle", "analyzedName"],
        },
      },
    },
    required: ["results"],
  },

  EMAIL_RESPONSE_SCHEMA: {
    type: "object",
    properties: {
      results: {
        type: "array",
        items: {
          type: "object",
          properties: {
            channelId: { type: "string" },
            emailMessage: { type: "string" },
          },
          required: ["channelId", "emailMessage"],
        },
      },
    },
    required: ["results"],
  },

  // Error Messages
  ERRORS: {
    EMPTY_ITEMS: "Items must be a non-empty array",
    ANALYSIS_FAILED: "Analysis failed",
    CACHE_ERROR: "Cache operation failed",
  },

  // SSE Event Types
  EVENTS: {
    STARTED: "started",
    PROGRESS: "progress",
    RESULT: "result",
    BATCH: "batch",
    COMPLETE: "complete",
    ERROR: "error",
  },
};
