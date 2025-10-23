// Enhanced logging utility with structured logging
const config = require("../config");

class Logger {
  static getTimestamp() {
    return new Date().toISOString();
  }

  static formatMessage(level, message, meta = {}) {
    const logEntry = {
      timestamp: this.getTimestamp(),
      level: level.toUpperCase(),
      message,
      ...meta,
    };

    if (config.server.env === "production") {
      return JSON.stringify(logEntry);
    }

    // Pretty print for development
    return `[${logEntry.level}] ${logEntry.timestamp} - ${logEntry.message}${
      Object.keys(meta).length > 0 ? ` ${JSON.stringify(meta)}` : ""
    }`;
  }

  static info(message, meta = {}) {
    console.log(this.formatMessage("info", message, meta));
  }

  static warn(message, meta = {}) {
    console.warn(this.formatMessage("warn", message, meta));
  }

  static error(message, error = null, meta = {}) {
    const errorMeta = error
      ? {
          error: {
            name: error.name,
            message: error.message,
            stack: error.stack,
          },
          ...meta,
        }
      : meta;

    console.error(this.formatMessage("error", message, errorMeta));
  }

  static debug(message, meta = {}) {
    if (
      config.logging.level === "debug" ||
      config.server.env === "development"
    ) {
      console.debug(this.formatMessage("debug", message, meta));
    }
  }

  // Request logging
  static request(req, res, responseTime) {
    if (!config.logging.enableRequestLogging) return;

    const meta = {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      responseTime: `${responseTime}ms`,
      userAgent: req.get("User-Agent"),
      ip: req.ip,
      requestId: req.requestId || res.locals.requestId,
    };

    const level = res.statusCode >= 400 ? "warn" : "info";
    this[level](`${req.method} ${req.url}`, meta);
  }

  // Performance logging
  static performance(operation, duration, meta = {}) {
    this.info(`Performance: ${operation}`, {
      duration: `${duration}ms`,
      ...meta,
    });
  }

  // Cache logging
  static cache(operation, key, hit = null, meta = {}) {
    this.debug(`Cache ${operation}`, {
      key,
      hit,
      ...meta,
    });
  }
}

module.exports = Logger;
