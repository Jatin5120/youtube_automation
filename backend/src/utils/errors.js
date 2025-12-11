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
  // Handle error objects that already have user-friendly format (from _getUserFriendlyError)
  if (error && typeof error === "object" && error.message && error.code) {
    const response = {
      success: false,
      message: error.message,
      code: error.code,
      timestamp: new Date().toISOString(),
    };

    if (error.technicalDetails && process.env.NODE_ENV === "development") {
      response.technicalDetails = error.technicalDetails;
    }

    if (error.field) {
      response.field = error.field;
    }

    if (includeStack && process.env.NODE_ENV === "development" && error.stack) {
      response.stack = error.stack;
    }

    return response;
  }

  // Handle standard Error objects
  const response = {
    success: false,
    message: error.message || "An unknown error occurred",
    code: error.code || "UNKNOWN_ERROR",
    timestamp: new Date().toISOString(),
  };

  if (includeStack && process.env.NODE_ENV === "development") {
    response.stack = error.stack;
    response.technicalDetails = error.message;
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
