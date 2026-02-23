namespace Sumpooj.Application.Deliveries;

public record AssignDeliveryPersonCommand(
    Guid DeliveryId,
    Guid StaffId);
