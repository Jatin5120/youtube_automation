const { body, query, validationResult } = require("express-validator");

// Validation for channel request
const validateChannelRequest = [
  body("ids")
    .notEmpty()
    .withMessage("IDs are required")
    .custom((value) => {
      try {
        const decoded = Buffer.from(value, "base64").toString("utf-8");
        const idList = decoded.split(",");
        if (idList.length === 0 || idList.some((id) => !id.trim())) {
          throw new Error("Invalid IDs format");
        }
        return true;
      } catch (error) {
        throw new Error("IDs must be valid base64 encoded string");
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

module.exports = {
  validateChannelRequest,
  validateSearchRequest,
};
