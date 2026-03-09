const express = require("express");
const router = express.Router();

// ...existing code...

/**
 UNASSIGNED DELIVERIES
*/
const { deliveries } = require("../models/deliveryStore");
router.get("/unassigned", (req, res) => {
  const list = deliveries.filter(d => !d.routeId);
  res.json(list);
});

/**
 GENERATE ROUTES
*/
router.post("/generate", async (req, res) => {
  const { date } = req.body;
  res.json({ success: true });
});

/**
 GET ROUTE DETAIL
*/
router.get("/:routeId", async (req, res) => {
  const { routeId } = req.params;

  res.json({
    id: routeId,
    name: "Route A",
    status: "Draft",
    deliveries: []
  });
});

/**
 ASSIGN DRIVER
*/
router.put("/:routeId/assign-driver", async (req, res) => {
  res.json({ success: true });
});

/**
 START ROUTE
*/
router.put("/:routeId/start", async (req, res) => {
  res.json({ success: true });
});

/**
 COMPLETE ROUTE
*/
router.put("/:routeId/complete", async (req, res) => {
  res.json({ success: true });
});

/**
 REORDER STOP
*/
router.put("/:routeId/reorder-stop", async (req, res) => {
  res.json({ success: true });
});

/**
 MOVE STOP
*/
router.put("/:routeId/move-stop", async (req, res) => {
  res.json({ success: true });
});

module.exports = router;