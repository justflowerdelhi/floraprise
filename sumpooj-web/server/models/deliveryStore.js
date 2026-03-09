// Temporary in-memory delivery store
const deliveries = [];

function createDeliveryFromOrder(order) {
  const delivery = {
    deliveryId: "DLV-" + Date.now(),
    orderId: order.id,
    orderNumber: order.orderNumber,
    customerName: order.customerName || "",
    phone: order.phoneNumber || null,
    deliveryDate: order.deliveryDate,
    timeSlot: order.timeSlot || "",
    address: order.deliveryAddress || "",
    status: "Scheduled",
    deliveryPersonName: null,
    routeId: null,
    stopOrder: null
  };

  deliveries.push(delivery);
  return delivery;
}

function getDeliveries(date) {
  if (!date) return deliveries;
  return deliveries.filter(d => d.deliveryDate === date);
}

function assignDriver(deliveryId, driverName) {
  const d = deliveries.find(x => x.deliveryId === deliveryId);
  if (!d) return;
  d.deliveryPersonName = driverName;
}

function updateStatus(deliveryId, status) {
  const d = deliveries.find(x => x.deliveryId === deliveryId);
  if (!d) return;
  d.status = status;
}

module.exports = {
  deliveries,
  createDeliveryFromOrder,
  getDeliveries,
  assignDriver,
  updateStatus
};
