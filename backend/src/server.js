const express = require("express");
const cors = require("cors");
const router = require("./routes");

const app = express();
const parser = express.json;

app.use(cors());
app.use(parser());
app.use(router);

app.listen(3000, (req, res) => {
  console.log("Server running on port 3000");
});
