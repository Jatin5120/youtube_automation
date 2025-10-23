const quotaManager = require("../utils/quota");

class QuotaController {
  static async getQuotaStatus(req, res) {
    try {
      const quotaStatus = quotaManager.getQuotaStatus();
      res.json({
        ...quotaStatus,
        isLow: quotaManager.isQuotaLow(),
        isExhausted: quotaManager.isQuotaExhausted(),
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      res.status(500).json({
        error: "Failed to get quota status",
        message: error.message,
        timestamp: new Date().toISOString(),
      });
    }
  }
}

module.exports = QuotaController;
