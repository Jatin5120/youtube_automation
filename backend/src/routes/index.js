const express = require("express");
const router = express.Router();

const {
  VideoController,
  HealthController,
  QuotaController,
} = require("../controllers");
const AnalysisController = require("../controllers/analysisController");
const {
  validateChannelRequest,
  validateSearchRequest,
  validateAnalysisRequest,
  validateChannelStreamRequest,
} = require("../middleware/validation");
const { timeout } = require("../middleware");
const config = require("../config");

// Health check endpoints
router.get("/", HealthController.getRoot);
router.get("/health", HealthController.getHealth);
router.get("/wakeup", HealthController.wakeup);

// Enhanced cache statistics endpoint
router.get("/cache/stats", VideoController.getCacheStats);

// Quota status endpoint
router.get("/quota/status", QuotaController.getQuotaStatus);

// Enhanced cache management endpoints
router.delete("/cache", VideoController.invalidateCache);
router.post("/cache/invalidate", VideoController.invalidateCache);

router.patch(
  "/videos",
  timeout(config.timeout.default),
  validateChannelRequest,
  VideoController.getChannel
);
router.get(
  "/search",
  timeout(config.timeout.default),
  validateSearchRequest,
  VideoController.searchChannels
);

// Analysis routes
const analysisController = new AnalysisController();

router.post(
  "/analyze/stream",
  timeout(config.timeout.sse),
  validateAnalysisRequest,
  analysisController.analyzeStream.bind(analysisController)
);

// Channel streaming endpoint for large batches
router.post(
  "/videos/stream",
  timeout(config.timeout.sse),
  validateChannelStreamRequest,
  VideoController.getChannelStream
);

module.exports = router;
