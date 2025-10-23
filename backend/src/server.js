const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const router = require("./routes");
const {
  requestLogger,
  apiLogger,
  errorHandler,
  notFoundHandler,
  requestId,
} = require("./middleware");
const config = require("./config");
const Logger = require("./utils/logger");

const app = express();

// Trust proxy (required when behind a reverse proxy like Render, Cloudflare, etc.)
app.set("trust proxy", config.server.trustProxy);

// Security middleware
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", "data:", "https:"],
      },
    },
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  message: {
    error: config.rateLimit.message,
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for health checks
  skip: (req) => req.url === "/api/health" || req.url === "/api/",
});

app.use(limiter);

// CORS configuration
app.use(
  cors({
    origin: config.cors.origin,
    credentials: config.cors.credentials,
    methods: ["GET", "POST", "PATCH", "DELETE"],
    allowedHeaders: [
      "Content-Type",
      "Authorization",
      "Accept",
      "Cache-Control",
      "Connection",
      "X-Requested-With",
    ],
  })
);

// Body parsing middleware with size limits
app.use(
  express.json({
    limit: "50mb", // Increased for large channel batches
    verify: (req, res, buf) => {
      // Store raw body for webhook verification if needed
      req.rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ limit: "50mb", extended: true }));

// Request ID middleware (must be before request logging)
app.use(requestId);

// Comprehensive API logging
app.use(apiLogger);

// API routes
app.use("/api", router);

// 404 handler
app.use(notFoundHandler);

// Error handling middleware (must be last)
app.use(errorHandler);

// Graceful shutdown
process.on("SIGTERM", () => {
  Logger.info("SIGTERM received, shutting down gracefully");
  process.exit(0);
});

process.on("SIGINT", () => {
  Logger.info("SIGINT received, shutting down gracefully");
  process.exit(0);
});

// Start server
const server = app.listen(config.server.port, () => {
  Logger.info(`Server running on port ${config.server.port}`, {
    env: config.server.env,
    nodeVersion: process.version,
  });
});

// Handle server errors
server.on("error", (error) => {
  if (error.code === "EADDRINUSE") {
    Logger.error(`Port ${config.server.port} is already in use`);
  } else {
    Logger.error("Server error", error);
  }
  process.exit(1);
});

module.exports = app;
