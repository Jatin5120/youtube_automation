const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const router = require("./routes");
const logger = require("./middleware");

const app = express();
const parser = express.json;

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: "Too many requests from this IP, please try again later.",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use(limiter);

// CORS configuration
app.use(cors());

// Body parsing middleware with size limits
app.use(parser({ limit: "10mb" }));
app.use(express.urlencoded({ limit: "10mb", extended: true }));

// Middlewares
app.use(logger);

app.use("/api", router);

app.listen(3000, (req, res) => {
  console.log("Server running on port 3000");
});

module.exports = app;
