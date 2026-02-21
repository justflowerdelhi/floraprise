using Sumpooj.Application.Dashboard;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.UseCases;

public class DashboardService
{
    private readonly IOrderRepository _orderRepository;
    private readonly IProductBatchRepository _batchRepository;
    private readonly IProductRepository _productRepository;
    private readonly ITaskRepository _taskRepository;

    public DashboardService(
        IOrderRepository orderRepository,
        IProductBatchRepository batchRepository,
        IProductRepository productRepository,
        ITaskRepository taskRepository)
    {
        _orderRepository = orderRepository;
        _batchRepository = batchRepository;
        _productRepository = productRepository;
        _taskRepository = taskRepository;
    }

    public async Task<DashboardResponse> GetDashboardAsync(Guid companyId, string role, Guid? locationId = null)
    {
        return role.ToUpperInvariant() switch
        {
            "ADMIN" => new DashboardResponse { Role = "ADMIN", Data = await GetAdminDashboardAsync(companyId) },
            "MANAGER" => new DashboardResponse { Role = "MANAGER", Data = await GetManagerDashboardAsync(companyId) },
            "DESIGNER" => new DashboardResponse { Role = "DESIGNER", Data = await GetDesignerDashboardAsync(companyId) },
            "CASHIER" => new DashboardResponse { Role = "CASHIER", Data = await GetCashierDashboardAsync(companyId) },
            "DRIVER" => new DashboardResponse { Role = "DRIVER", Data = await GetDriverDashboardAsync(companyId) },
            _ => throw new ArgumentException($"Unknown role: {role}")
        };
    }

    private async Task<AdminDashboardDto> GetAdminDashboardAsync(Guid companyId)
    {
        var todaysSales = await _orderRepository.GetTodaysSalesAsync(companyId);
        var ordersToday = await _orderRepository.GetTodaysOrderCountAsync(companyId);
        var deliveriesScheduled = await _orderRepository.GetPendingDeliveriesCountAsync(companyId, DateTime.Today);
        var lowStockItems = await _productRepository.GetLowStockCountAsync(companyId);
        var expiringBatches = (await _batchRepository.GetExpiryAlertsAsync(companyId, 7)).Count;
        var pendingTasks = await _taskRepository.GetPendingTaskCountAsync(companyId);

        var alerts = new List<AlertDto>();
        
        if (lowStockItems > 0)
        {
            alerts.Add(new AlertDto
            {
                Id = "low_stock",
                Type = "low_stock",
                Message = $"{lowStockItems} items are low in stock",
                Severity = "warning",
                Href = "/inventory"
            });
        }

        if (expiringBatches > 0)
        {
            alerts.Add(new AlertDto
            {
                Id = "expiring",
                Type = "expiry",
                Message = $"{expiringBatches} batches expiring soon",
                Severity = "warning",
                Href = "/expiry-alerts"
            });
        }

        return new AdminDashboardDto
        {
            TodaySales = todaysSales,
            SalesTrend = 0, // Would need historical data
            OrdersToday = ordersToday,
            DeliveriesScheduled = deliveriesScheduled,
            GrossProfit = todaysSales * 0.35m, // Simplified - would need actual calculation
            LowStockItems = lowStockItems,
            ExpiringBatches = expiringBatches,
            StaffTasksPending = pendingTasks,
            TopAlerts = alerts
        };
    }

    private async Task<ManagerDashboardDto> GetManagerDashboardAsync(Guid companyId)
    {
        var admin = await GetAdminDashboardAsync(companyId);
        return new ManagerDashboardDto
        {
            TodaySales = admin.TodaySales,
            OrdersToday = admin.OrdersToday,
            DeliveriesScheduled = admin.DeliveriesScheduled,
            LowStockItems = admin.LowStockItems,
            ExpiringBatches = admin.ExpiringBatches,
            StaffTasksPending = admin.StaffTasksPending,
            TopAlerts = admin.TopAlerts
        };
    }

    private Task<DesignerDashboardDto> GetDesignerDashboardAsync(Guid companyId)
    {
        // Would fetch actual production tasks from orders
        return Task.FromResult(new DesignerDashboardDto
        {
            ProductionTasks = new List<ProductionTaskDto>(),
            WeddingPrepTasks = new List<ProductionTaskDto>(),
            CustomOrders = new List<ProductionTaskDto>(),
            MaintenanceRequired = 0,
            ExpiringBouquets = 0
        });
    }

    private async Task<CashierDashboardDto> GetCashierDashboardAsync(Guid companyId)
    {
        var ordersToday = await _orderRepository.GetTodaysOrderCountAsync(companyId);
        var todaysSales = await _orderRepository.GetTodaysSalesAsync(companyId);

        return new CashierDashboardDto
        {
            PendingPickups = 0, // Would need specific query
            UnpaidOrders = 0, // Would need specific query
            TodaySalesCount = ordersToday,
            TodaySalesTotal = todaysSales
        };
    }

    private Task<DriverDashboardDto> GetDriverDashboardAsync(Guid companyId)
    {
        // Would fetch deliveries assigned to current driver
        return Task.FromResult(new DriverDashboardDto
        {
            Deliveries = new List<DeliveryTaskDto>(),
            CompletedCount = 0,
            PendingCount = 0,
            FailedCount = 0
        });
    }
}
