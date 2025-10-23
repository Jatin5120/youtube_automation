const { body, query, validationResult } = require("express-validator");

// Validation for channel request
const validateChannelRequest = [
  body("ids")
    .notEmpty()
    .withMessage("IDs are required")
    .isLength({ min: 1, max: 10000 })
    .withMessage("IDs string too long")
    .custom((value) => {
      try {
        const decoded = Buffer.from(value, "base64").toString("utf-8");
        const idList = decoded.split(",");

        if (idList.length === 0) {
          throw new Error("No IDs provided");
        }

        if (idList.length > 100) {
          throw new Error("Too many IDs (max 100)");
        }

        if (idList.some((id) => !id.trim())) {
          throw new Error("Empty ID found");
        }

        // Validate ID format
        const invalidIds = idList.filter((id) => {
          const trimmed = id.trim();
          return !trimmed || trimmed.length < 3 || trimmed.length > 50;
        });

        if (invalidIds.length > 0) {
          throw new Error(`Invalid ID format: ${invalidIds[0]}`);
        }

        return true;
      } catch (error) {
        throw new Error(`IDs validation failed: ${error.message}`);
      }
    }),
  body("useId").optional().isBoolean().withMessage("useId must be boolean"),
  body("variant")
    .optional()
    .isIn(["development", "production"])
    .withMessage("variant must be either development or production"),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: "Validation failed",
        details: errors.array(),
        timestamp: new Date().toISOString(),
      });
    }
    next();
  },
];

// Validation for search request
const validateSearchRequest = [
  query("query")
    .notEmpty()
    .withMessage("Query is required")
    .isLength({ min: 1, max: 100 })
    .withMessage("Query must be between 1 and 100 characters")
    .trim()
    .escape(),
  query("pageToken")
    .optional()
    .isString()
    .withMessage("pageToken must be a string"),
  query("variant")
    .optional()
    .isIn(["development", "production"])
    .withMessage("variant must be either development or production"),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: "Validation failed",
        details: errors.array(),
      });
    }
    next();
  },
];

// Add this to the existing validation.js file

const validateAnalysisRequest = [
  body("channels")
    .isArray({ min: 1, max: 500 })
    .withMessage("Channels must be an array with 1-500 elements"),

  body("channels.*.channelId")
    .notEmpty()
    .withMessage("Each channel must have an channelId"),

  body("channels.*.title")
    .notEmpty()
    .withMessage("Each channel must have a title"),

  body("channels.*.channelName")
    .notEmpty()
    .withMessage("Each channel must have a channelName"),

  body("channels.*.userName")
    .notEmpty()
    .withMessage("Each channel must have a userName"),

  body("batchSize")
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage("Batch size must be between 1-50"),

  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: "Validation failed",
        details: errors.array(),
      });
    }
    next();
  },
];

// Validation for channel streaming request
const validateChannelStreamRequest = [
  body("ids")
    .notEmpty()
    .withMessage("IDs are required")
    .isLength({ min: 1, max: 50000 })
    .withMessage("IDs string too long")
    .custom((value) => {
      try {
        const decoded = Buffer.from(value, "base64").toString("utf-8");
        const idList = decoded.split(",");

        if (idList.length === 0) {
          throw new Error("No IDs provided");
        }

        if (idList.length > 1000) {
          throw new Error("Too many IDs (max 1000)");
        }

        if (idList.some((id) => !id.trim())) {
          throw new Error("Empty ID found");
        }

        return true;
      } catch (error) {
        throw new Error(`IDs validation failed: ${error.message}`);
      }
    }),
  body("useId").optional().isBoolean().withMessage("useId must be boolean"),
  body("variant")
    .optional()
    .isIn(["development", "production"])
    .withMessage("variant must be either development or production"),
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: "Validation failed",
        details: errors.array(),
        timestamp: new Date().toISOString(),
      });
    }
    next();
  },
];

module.exports = {
  validateChannelRequest,
  validateSearchRequest,
  validateAnalysisRequest,
  validateChannelStreamRequest, // Add this
};
