const express = require("express");
const cors = require("cors");
const router = require("./routes");
const logger = require("./middleware");

const app = express();
const parser = express.json;

app.use(cors());
app.use(parser());

// Middlewares
app.use(logger);

app.use("/api", router);

app.listen(3000, (req, res) => {
  console.log("Server running on port 3000");
});

module.exports = app;
