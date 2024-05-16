const express = require("express");
const router = express.Router();

const VideoController = require("../controllers");

router.get("/", async (req, res) => {
  return res.json("Backend is working");
});
router.patch("/videos", VideoController.getChannel);
router.get("/search", VideoController.searchChannels);

module.exports = router;
