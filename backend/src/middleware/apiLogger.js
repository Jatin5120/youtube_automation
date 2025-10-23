const Logger = require("../utils/logger");

/**
 * Comprehensive API Logging Middleware
 *
 * This middleware automatically logs all API requests and responses
 * with detailed information including timing, parameters, and results.
 *
 * Features:
 * - Request/Response logging with timing
 * - Parameter extraction (query, body, params)
 * - Response size and status tracking
 * - Error logging with context
 * - Request ID correlation
 * - Performance metrics
 */
function apiLogger(req, res, next) {
  const startTime = Date.now();
  const requestId =
    req.requestId ||
    res.locals.requestId ||
    `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Attach request ID to request object for controllers
  req.requestId = requestId;
  res.locals.requestId = requestId;

  // Extract request information
  const requestInfo = {
    query: req.query,
    params: req.params,
    ip: req.ip,
    requestId,
  };

  // Extract body information (be careful with sensitive data)
  if (req.body && Object.keys(req.body).length > 0) {
    requestInfo.body = sanitizeRequestBody(req.body);
  }

  // Log incoming request
  Logger.info(`API Request: ${req.method} ${req.path}\n`, requestInfo);

  // Override res.json to capture response data
  const originalJson = res.json;
  const originalSend = res.send;
  const originalEnd = res.end;
  const originalWriteHead = res.writeHead;
  const originalWrite = res.write;

  let responseData = null;
  let responseSize = 0;
  let isSSE = false;

  // Override writeHead to detect SSE
  res.writeHead = function (statusCode, statusMessage, headers) {
    if (headers && headers["Content-Type"] === "text/event-stream") {
      isSSE = true;
    }
    return originalWriteHead.call(this, statusCode, statusMessage, headers);
  };

  // Override write to capture SSE data
  res.write = function (chunk, encoding, callback) {
    if (isSSE) {
      responseSize +=
        typeof chunk === "string" ? chunk.length : chunk.byteLength;
    }
    return originalWrite.call(this, chunk, encoding, callback);
  };

  res.json = function (obj) {
    responseData = obj;
    responseSize = JSON.stringify(obj).length;
    return originalJson.call(this, obj);
  };

  res.send = function (data) {
    responseData = data;
    responseSize =
      typeof data === "string" ? data.length : JSON.stringify(data).length;
    return originalSend.call(this, data);
  };

  res.end = function (...args) {
    const responseTime = Date.now() - startTime;

    // Log response
    const responseInfo = {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      responseTime: `${responseTime}ms`,
      responseSize: `${responseSize} bytes`,
      requestId,
    };

    // Add SSE-specific info
    if (isSSE) {
      responseInfo.type = "SSE";
      responseInfo.streamSize = `${responseSize} bytes`;
    }

    // Add response data info for successful requests
    if (res.statusCode < 400 && responseData) {
      if (Array.isArray(responseData)) {
        responseInfo.resultCount = responseData.length;
      } else if (responseData.data && Array.isArray(responseData.data)) {
        responseInfo.resultCount = responseData.data.length;
        responseInfo.hasNextPage = !!responseData.nextPageToken;
      } else if (responseData.success !== undefined) {
        responseInfo.success = responseData.success;
      }
    }

    // Add error information for failed requests
    if (res.statusCode >= 400) {
      responseInfo.error =
        responseData?.error || responseData?.message || "Unknown error";
    }

    // Log with appropriate level
    const logLevel = res.statusCode >= 400 ? "warn" : "info";
    const logMessage = isSSE
      ? `API Response (SSE): ${req.method} ${req.path}`
      : `API Response: ${req.method} ${req.path}`;

    Logger[logLevel](`${logMessage}\n`, responseInfo);

    // Call original end
    return originalEnd.apply(this, args);
  };

  // Handle errors
  res.on("error", (error) => {
    Logger.error(`Response error for ${req.method} ${req.path}`, error, {
      requestId,
      statusCode: res.statusCode,
    });
  });

  next();
}

/**
 * Sanitize request body to remove sensitive information
 * @param {Object} body - Request body object
 * @returns {Object} - Sanitized body
 */
function sanitizeRequestBody(body) {
  const sensitiveKeys = ["password", "token", "secret", "key", "authorization"];
  const sanitized = { ...body };

  // Remove or mask sensitive fields
  for (const key of Object.keys(sanitized)) {
    const lowerKey = key.toLowerCase();
    if (sensitiveKeys.some((sensitive) => lowerKey.includes(sensitive))) {
      sanitized[key] = "[REDACTED]";
    }
  }

  // Limit body size for logging (truncate large payloads)
  const bodyStr = JSON.stringify(sanitized);
  if (bodyStr.length > 1000) {
    return {
      ...sanitized,
      _truncated: true,
      _originalSize: bodyStr.length,
    };
  }

  return sanitized;
}

module.exports = apiLogger;
