const express = require("express");
const router = express.Router();

const VideoController = require("../controllers");
const {
  validateChannelRequest,
  validateSearchRequest,
} = require("../middleware/validation");
const { channelCache, searchCache, videoCache } = require("../utils/cache");
const quotaManager = require("../utils/quota");

router.get("/", async (req, res) => {
  return res.json({
    message: "Backend is working",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  });
});

// Cache statistics endpoint
router.get("/cache/stats", (req, res) => {
  const stats = {
    channelCache: channelCache.getStats(),
    searchCache: searchCache.getStats(),
    videoCache: videoCache.getStats(),
    timestamp: new Date().toISOString(),
  };

  res.json(stats);
});

// Quota status endpoint
router.get("/quota/status", (req, res) => {
  const quotaStatus = quotaManager.getQuotaStatus();
  res.json({
    ...quotaStatus,
    isLow: quotaManager.isQuotaLow(),
    isExhausted: quotaManager.isQuotaExhausted(),
    timestamp: new Date().toISOString(),
  });
});

// Clear cache endpoint (for development/testing)
router.delete("/cache", (req, res) => {
  channelCache.clear();
  searchCache.clear();
  videoCache.clear();

  res.json({
    message: "All caches cleared",
    timestamp: new Date().toISOString(),
  });
});

router.patch("/videos", validateChannelRequest, VideoController.getChannel);
router.get("/search", validateSearchRequest, VideoController.searchChannels);

module.exports = router;
