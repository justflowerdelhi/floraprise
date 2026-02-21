namespace Sumpooj.Application.Staff;

public class StaffDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Role { get; set; } = default!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public bool IsActive { get; set; }
    public string? CommissionType { get; set; }
    public decimal? CommissionRate { get; set; }
    public decimal? HourlyRate { get; set; }
    public Guid? PrimaryLocationId { get; set; }
    public Guid? UserId { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class StaffListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Role { get; set; } = default!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public bool IsActive { get; set; }
    public string? CommissionType { get; set; }
    public decimal? CommissionRate { get; set; }
}

public class CreateStaffRequest
{
    public string Name { get; set; } = default!;
    public string Role { get; set; } = "Staff";
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? CommissionType { get; set; }
    public decimal? CommissionRate { get; set; }
    public decimal? HourlyRate { get; set; }
    public Guid? PrimaryLocationId { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateStaffRequest
{
    public string? Name { get; set; }
    public string? Role { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? CommissionType { get; set; }
    public decimal? CommissionRate { get; set; }
    public decimal? HourlyRate { get; set; }
    public Guid? PrimaryLocationId { get; set; }
    public bool? IsActive { get; set; }
}

public class StaffSearchRequest
{
    public string? Query { get; set; }
    public string? Role { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class StaffPerformanceDto
{
    public Guid StaffId { get; set; }
    public string StaffName { get; set; } = default!;
    public string Role { get; set; } = default!;
    public SalesMetricsDto Sales { get; set; } = new();
    public CommissionMetricsDto Commission { get; set; } = new();
}

public class SalesMetricsDto
{
    public int TotalOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TotalCost { get; set; }
    public decimal GrossProfit { get; set; }
    public decimal MarginPercent { get; set; }
    public decimal AverageOrderValue { get; set; }
}

public class CommissionMetricsDto
{
    public decimal CommissionBase { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal CommissionEarned { get; set; }
}
