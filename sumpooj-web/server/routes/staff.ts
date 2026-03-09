const express = require("express");
const router = express.Router();

// Minimal working endpoint
router.get("/", (req, res) => {
  res.json([]);
});

module.exports = router;