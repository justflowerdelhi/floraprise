const express = require("express");
const cors = require("cors");
const deliveryRoutes = require("./routes/deliveryRoutes");
const deliveriesRouter = require("./routes/deliveries");
const staffRoutes = require("./routes/staff");
const phoneOrdersRouter = require("./routes/phoneOrders");

const app = express();

app.use(cors());
app.use(express.json());

/* API Routes */
app.use("/api/delivery-routes", deliveryRoutes);
app.use("/api/deliveries", deliveriesRouter);
app.use("/api/staff", staffRoutes);
app.use("/api/phone-orders", phoneOrdersRouter);

/* Health check */
app.get("/api/health", (req, res) => {
  res.json({ status: "ok" });
});

const PORT = 3000;

app.listen(PORT, () => {
  console.log(`Floraprise API running on port ${PORT}`);
});
