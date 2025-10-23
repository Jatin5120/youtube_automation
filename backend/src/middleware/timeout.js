const Logger = require("../utils/logger");

/**
 * Request timeout middleware
 * @param {number} ms - Timeout in milliseconds
 * @returns {Function} Express middleware function
 */
const timeout = (ms) => (req, res, next) => {
  const timeoutId = setTimeout(() => {
    if (!res.headersSent) {
      Logger.warn(`Request timeout after ${ms}ms`, {
        method: req.method,
        url: req.url,
        ip: req.ip,
      });

      res.status(408).json({
        error: "Request timeout",
        message: `Request timed out after ${ms}ms`,
        timestamp: new Date().toISOString(),
      });
    }
  }, ms);

  // Clear timeout when response is sent
  const originalEnd = res.end;
  res.end = function (...args) {
    clearTimeout(timeoutId);
    originalEnd.apply(this, args);
  };

  next();
};

module.exports = { timeout };
