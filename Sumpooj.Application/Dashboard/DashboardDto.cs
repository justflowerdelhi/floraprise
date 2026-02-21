namespace Sumpooj.Application.Dashboard;

// Response wrapper
public class DashboardResponse
{
    public string Role { get; set; } = default!;
    public object Data { get; set; } = default!;
}

// Admin Dashboard
public class AdminDashboardDto
{
    public decimal TodaySales { get; set; }
    public decimal SalesTrend { get; set; }
    public int OrdersToday { get; set; }
    public int DeliveriesScheduled { get; set; }
    public decimal GrossProfit { get; set; }
    public int LowStockItems { get; set; }
    public int ExpiringBatches { get; set; }
    public int StaffTasksPending { get; set; }
    public List<AlertDto> TopAlerts { get; set; } = new();
}

public class AlertDto
{
    public string Id { get; set; } = default!;
    public string Type { get; set; } = default!;
    public string Message { get; set; } = default!;
    public string Severity { get; set; } = default!;
    public string? Href { get; set; }
}

// Manager Dashboard
public class ManagerDashboardDto
{
    public decimal TodaySales { get; set; }
    public int OrdersToday { get; set; }
    public int DeliveriesScheduled { get; set; }
    public int LowStockItems { get; set; }
    public int ExpiringBatches { get; set; }
    public int StaffTasksPending { get; set; }
    public List<AlertDto> TopAlerts { get; set; } = new();
}

// Designer Dashboard
public class DesignerDashboardDto
{
    public List<ProductionTaskDto> ProductionTasks { get; set; } = new();
    public List<ProductionTaskDto> WeddingPrepTasks { get; set; } = new();
    public List<ProductionTaskDto> CustomOrders { get; set; } = new();
    public int MaintenanceRequired { get; set; }
    public int ExpiringBouquets { get; set; }
}

public class ProductionTaskDto
{
    public string Id { get; set; } = default!;
    public string Title { get; set; } = default!;
    public string Type { get; set; } = default!;
    public string Status { get; set; } = default!;
    public string DueTime { get; set; } = default!;
    public string Priority { get; set; } = default!;
    public string? Notes { get; set; }
}

// Cashier Dashboard
public class CashierDashboardDto
{
    public int PendingPickups { get; set; }
    public int UnpaidOrders { get; set; }
    public int TodaySalesCount { get; set; }
    public decimal TodaySalesTotal { get; set; }
}

// Driver Dashboard
public class DriverDashboardDto
{
    public List<DeliveryTaskDto> Deliveries { get; set; } = new();
    public int CompletedCount { get; set; }
    public int PendingCount { get; set; }
    public int FailedCount { get; set; }
}

public class DeliveryTaskDto
{
    public string Id { get; set; } = default!;
    public string OrderNumber { get; set; } = default!;
    public string CustomerName { get; set; } = default!;
    public string Phone { get; set; } = default!;
    public string Address { get; set; } = default!;
    public string TimeSlot { get; set; } = default!;
    public string Status { get; set; } = default!;
    public string Items { get; set; } = default!;
    public string? Notes { get; set; }
}
