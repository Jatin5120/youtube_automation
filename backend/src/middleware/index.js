const Logger = require("../utils/logger");
const config = require("../config");
const { timeout } = require("./timeout");
const { requestId } = require("./requestId");
const apiLogger = require("./apiLogger");

// Request logging middleware
function requestLogger(req, res, next) {
  const startTime = Date.now();

  // Override res.end to capture response time
  const originalEnd = res.end;
  res.end = function (...args) {
    const responseTime = Date.now() - startTime;
    Logger.request(req, res, responseTime);
    originalEnd.apply(this, args);
  };

  next();
}

// Error handling middleware
function errorHandler(err, req, res, next) {
  Logger.error("Unhandled error", err, {
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get("User-Agent"),
  });

  // Don't leak error details in production
  const isDevelopment = config.server.env === "development";

  res.status(err.status || 500).json({
    error: isDevelopment ? err.message : "Internal server error",
    ...(isDevelopment && { stack: err.stack }),
    timestamp: new Date().toISOString(),
  });
}

// 404 handler
function notFoundHandler(req, res) {
  res.status(404).json({
    error: "Route not found",
    path: req.url,
    method: req.method,
    timestamp: new Date().toISOString(),
  });
}

module.exports = {
  requestLogger,
  apiLogger,
  errorHandler,
  notFoundHandler,
  timeout,
  requestId,
};
