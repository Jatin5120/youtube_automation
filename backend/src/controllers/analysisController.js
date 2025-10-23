const AnalysisService = require("../services/analysisService");
const Logger = require("../utils/logger");
const { formatErrorResponse } = require("../utils/errors");
const config = require("../config/analysis");

class AnalysisController {
  constructor() {
    this.analysisService = new AnalysisService();
  }

  // Helper method for safe SSE writing
  static _writeSSE(res, event, data) {
    try {
      if (event) {
        res.write(`event:${event}\n\n`);
      }
      if (data) {
        res.write(`data:${JSON.stringify(data)}\n\n`);
      }
    } catch (error) {
      Logger.error(`SSE write error in ${event}:`, error);
      res.end();
      throw error;
    }
  }

  // Helper method for safe SSE writing with error handling
  static _writeSSESafe(res, event, data, onError) {
    try {
      AnalysisController._writeSSE(res, event, data);
    } catch (error) {
      if (onError) {
        onError(error);
      }
    }
  }

  async analyzeStream(req, res) {
    const { channels, batchSize } = req.body;

    // Set SSE headers (matching sod-messages pattern)
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no"); // Disable nginx buffering

    // Handle client disconnect
    req.on("close", () => {
      Logger.debug("Client disconnected from SSE stream", {
        requestId: req.requestId,
      });
    });

    try {
      await this.analysisService.analyzeBatchWithSSE({
        channels,
        batchSize,
        onProgress: (step, data) => {
          AnalysisController._writeSSESafe(res, step, data, () => res.end());
        },
        onBatchResult: (batchResult) => {
          AnalysisController._writeSSESafe(
            res,
            config.EVENTS.BATCH,
            { data: batchResult },
            () => res.end()
          );
        },
        onComplete: () => {
          AnalysisController._writeSSESafe(
            res,
            config.EVENTS.COMPLETE,
            {
              success: true,
            },
            () => res.end()
          );
          res.end();
        },
        onError: (error) => {
          Logger.error("Analysis error:", error);
          const errorResponse = formatErrorResponse(error);
          AnalysisController._writeSSESafe(
            res,
            config.EVENTS.ERROR,
            errorResponse,
            () => res.end()
          );
          res.end();
        },
      });
    } catch (error) {
      Logger.error("Controller error:", error);
      const errorResponse = formatErrorResponse(error);
      AnalysisController._writeSSESafe(
        res,
        config.EVENTS.ERROR,
        errorResponse,
        () => res.end()
      );
      res.end();
    }
  }
}

module.exports = AnalysisController;
