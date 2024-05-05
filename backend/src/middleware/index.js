const { youtubeKey } = require("../helper");

function logger(req, res, next) {
  // Log information about the incoming request
  console.log(`${req.method} ${req.url}`);

  // Continue to the next middleware or route handler
  next();
}

module.exports = logger;
