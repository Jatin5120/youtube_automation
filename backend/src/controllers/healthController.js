const Logger = require("../utils/logger");

class HealthController {
  static async getRoot(req, res) {
    return res.json({
      message: "YouTube Automation Backend API",
      status: "healthy",
      timestamp: new Date().toISOString(),
      version: "1.0.0",
    });
  }

  static async getHealth(req, res) {
    const { memoryMonitor, cpuMonitor } = require("../middleware/performance");
    const { validateApiKeys } = require("../helper");

    try {
      // Basic health check
      const health = {
        status: "ok",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: memoryMonitor(),
        cpu: cpuMonitor(),
        version: process.version,
        env: process.env.NODE_ENV || "development",
      };

      // Check API keys (non-blocking)
      try {
        validateApiKeys();
        health.apiKeys = "ok";
      } catch (error) {
        health.apiKeys = "error";
        health.apiKeyError = error.message;
      }

      res.status(200).json(health);
    } catch (error) {
      Logger.error("Health check failed", error);
      res.status(500).json({
        status: "error",
        timestamp: new Date().toISOString(),
        error: error.message,
      });
    }
  }

  static async wakeup(req, res) {
    try {
      // Simple wakeup endpoint to keep Render.com server alive
      const wakeup = {
        status: "awake",
        message: "Server is awake and ready",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        env: process.env.NODE_ENV || "development",
      };

      res.status(200).json(wakeup);
    } catch (error) {
      Logger.error("Wakeup endpoint failed", error);
      res.status(500).json({
        status: "error",
        timestamp: new Date().toISOString(),
        error: error.message,
      });
    }
  }
}

module.exports = HealthController;
