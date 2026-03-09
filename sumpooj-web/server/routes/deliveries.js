const express = require("express");
const router = express.Router();

const {
  getDeliveries,
  assignDriver,
  updateStatus
} = require("../models/deliveryStore");

router.get("/", (req, res) => {
  const { date } = req.query;
  res.json(getDeliveries(date));
});

router.put("/:id/assign", (req, res) => {
  const { staffId } = req.body;
  assignDriver(req.params.id, staffId);
  res.json({ success: true });
});

router.put("/:id/out-for-delivery", (req, res) => {
  updateStatus(req.params.id, "OutForDelivery");
  res.json({ success: true });
});

router.put("/:id/delivered", (req, res) => {
  updateStatus(req.params.id, "Delivered");
  res.json({ success: true });
});

module.exports = router;
