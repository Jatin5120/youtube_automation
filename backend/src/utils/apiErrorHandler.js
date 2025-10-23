// Centralized API error handling utility
class APIErrorHandler {
  static handleYouTubeError(error, operation = "Unknown operation") {
    if (error.response) {
      const status = error.response.status;
      const retryAfter = error.response.headers["retry-after"];

      switch (status) {
        case 403:
          return {
            name: "YouTubeAPIError",
            message: "API quota exceeded",
            status: 403,
            retryAfter,
          };
        case 404:
          return {
            name: "YouTubeAPIError",
            message: "Resource not found",
            status: 404,
            retryAfter: null,
          };
        case 429:
          return {
            name: "YouTubeAPIError",
            message: "Rate limit exceeded",
            status: 429,
            retryAfter,
          };
        case 400:
          const errorData = error.response.data;
          const errorMessage = errorData?.error?.message || error.message;
          return {
            name: "YouTubeAPIError",
            message: `Invalid request: ${errorMessage}`,
            status: 400,
            retryAfter: null,
          };
        default:
          return {
            name: "YouTubeAPIError",
            message: `YouTube API error: ${error.message}`,
            status,
            retryAfter,
          };
      }
    }

    return {
      name: "YouTubeAPIError",
      message: `Network error: ${error.message}`,
      status: 500,
      retryAfter: null,
    };
  }

  static sendErrorResponse(res, error) {
    if (error.name === "YouTubeAPIError") {
      switch (error.status) {
        case 403:
          return res.status(429).json({
            error:
              "The request cannot be completed because you have exceeded your quota",
            retryAfter: error.retryAfter,
          });
        case 429:
          return res.status(429).json({
            error: "Rate limit exceeded. Please try again later.",
            retryAfter: error.retryAfter,
          });
        case 400:
          return res.status(400).json({
            error: "Invalid request parameters",
            details: error.message,
          });
        case 404:
          return res.status(404).json({
            error: "Resource not found",
            details: error.message,
          });
        default:
          return res.status(500).json({
            error: "Internal server error occurred while processing request",
          });
      }
    }

    return res.status(500).json({
      error: "Internal server error occurred while processing request",
    });
  }
}

module.exports = APIErrorHandler;
