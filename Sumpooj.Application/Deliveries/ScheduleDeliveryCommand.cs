namespace Sumpooj.Application.Deliveries;

public record ScheduleDeliveryCommand(
    Guid SalesOrderId,
    DateTime DeliveryDate,
    string TimeSlot,
    string Address);
