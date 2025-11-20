// Custom error classes for better error handling
class AnalysisError extends Error {
  constructor(message, code = "ANALYSIS_ERROR", statusCode = 500) {
    super(message);
    this.name = "AnalysisError";
    this.code = code;
    this.statusCode = statusCode;
  }
}

class ValidationError extends Error {
  constructor(message, field = null) {
    super(message);
    this.name = "ValidationError";
    this.field = field;
    this.statusCode = 400;
  }
}

class CacheError extends Error {
  constructor(message) {
    super(message);
    this.name = "CacheError";
    this.statusCode = 500;
  }
}

class OpenAIError extends Error {
  constructor(message, originalError = null) {
    super(message);
    this.name = "OpenAIError";
    this.originalError = originalError;
    this.statusCode = 500;
  }
}

class ApifyError extends Error {
  constructor(message, originalError = null, statusCode = 500) {
    super(message);
    this.name = "ApifyError";
    this.originalError = originalError;
    this.statusCode = statusCode;
  }
}

class LeadMagicError extends Error {
  constructor(message, originalError = null, statusCode = 500) {
    super(message);
    this.name = "LeadMagicError";
    this.originalError = originalError;
    this.statusCode = statusCode;
    this.status = statusCode; // For compatibility with retry utility
  }
}

// Error response formatter
function formatErrorResponse(error, includeStack = false) {
  const response = {
    success: false,
    message: error.message,
    code: error.code || "UNKNOWN_ERROR",
    timestamp: new Date().toISOString(),
  };

  if (includeStack && process.env.NODE_ENV === "development") {
    response.stack = error.stack;
  }

  if (error.field) {
    response.field = error.field;
  }

  return response;
}

module.exports = {
  AnalysisError,
  ValidationError,
  CacheError,
  OpenAIError,
  ApifyError,
  LeadMagicError,
  formatErrorResponse,
};
