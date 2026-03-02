namespace Sumpooj.Application.Dashboard;

// Response wrapper
public class DashboardResponse
{
    public string Role { get; set; } = default!;
    public object Data { get; set; } = default!;
}

public class SalesTrendPoint
{
    public string Day { get; set; } = default!;
    public decimal Sales { get; set; }
}

// Admin Dashboard — matches frontend AdminDashboardData
public class AdminDashboardDto
{
    public decimal TodaySales { get; set; }
    public decimal MonthRevenue { get; set; }
    public decimal GrossProfitToday { get; set; }
    public decimal InventoryValue { get; set; }
    public decimal WastageToday { get; set; }
    public int NetworkOrdersPending { get; set; }
    public int ExpiringBouquets { get; set; }
    public int UpcomingWeddings { get; set; }
    public List<SalesTrendPoint> SalesTrend { get; set; } = new();
}

public class AlertDto
{
    public string Id { get; set; } = default!;
    public string Type { get; set; } = default!;
    public string Message { get; set; } = default!;
    public string Severity { get; set; } = default!;
    public string? Href { get; set; }
}

// Manager Dashboard — matches frontend ManagerDashboardData
public class ManagerDashboardDto
{
    public int OrdersToFulfill { get; set; }
    public int DeliveriesScheduled { get; set; }
    public int ProductionPending { get; set; }
    public int LowStockAlerts { get; set; }
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
