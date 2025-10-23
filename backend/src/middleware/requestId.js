const crypto = require("crypto");

/**
 * Request ID middleware for better debugging and tracing
 * Adds a unique request ID to each request for correlation
 */
const requestId = (req, res, next) => {
  // Generate unique request ID
  const requestId = crypto.randomUUID();

  // Add to request object
  req.requestId = requestId;

  // Add to response headers for client correlation
  res.setHeader("X-Request-ID", requestId);

  // Add to response locals for logging
  res.locals.requestId = requestId;

  next();
};

module.exports = { requestId };
