namespace Sumpooj.Application.SalesOrders;

public record ConfirmPhoneOutstationOrderCommand(
    Guid SalesOrderId,
    Guid VendorId,
    decimal VendorCost,
    decimal DeliveryCharge);
