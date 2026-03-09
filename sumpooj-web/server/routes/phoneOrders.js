const express = require("express");
const router = express.Router();

const { createDeliveryFromOrder } = require("../models/deliveryStore");

// Confirm phone order and create delivery
router.post("/:id/confirm-local", async (req, res) => {
  const order = {
    id: req.params.id,
    orderNumber: "FP-" + Date.now(),
    customerName: "Customer",
    deliveryDate: "2026-03-09",
    deliveryAddress: "Address",
    timeSlot: "9:00 - 11:00"
  };

  createDeliveryFromOrder(order);

  res.json(order);
});

module.exports = router;
