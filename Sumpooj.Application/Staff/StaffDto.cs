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

    // ── Identity / Login info ────────────────────────────────
    public Guid? IdentityUserId { get; set; }
    public string? LoginIdentifier { get; set; }
    public string? LoginRole { get; set; }
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
    public string DriverStatus { get; set; } = "Available";
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

    // ── Optional login access ───────────────────────────────
    /// <summary>When true, creates an ASP.NET Identity user linked to this staff member.</summary>
    public bool EnableLogin { get; set; }
    /// <summary>Email or phone used as the Identity username. Required when EnableLogin is true.</summary>
    public string? LoginIdentifier { get; set; }
    /// <summary>Identity role to assign (e.g. "Admin", "Manager", "Staff"). Required when EnableLogin is true.</summary>
    public string? LoginRole { get; set; }
    /// <summary>Admin-provided password. Required when EnableLogin is true (min 6 chars, must satisfy Identity rules).</summary>
    public string? Password { get; set; }
}

/// <summary>Result returned after creating a staff member.</summary>
public class CreateStaffResult
{
    public Guid StaffId { get; set; }
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

/// <summary>Request to enable login for an existing staff member (edit mode).</summary>
public class EnableLoginRequest
{
    public string LoginIdentifier { get; set; } = default!;
    public string LoginRole { get; set; } = "Staff";
    /// <summary>Admin-provided password (min 6 chars, must satisfy Identity rules).</summary>
    public string Password { get; set; } = default!;
}

/// <summary>Request to reset password for a staff member's identity user.</summary>
public class ResetPasswordRequest
{
    /// <summary>New password (min 6 chars, must satisfy Identity rules).</summary>
    public string Password { get; set; } = default!;
}

public class StaffPerformanceDto
{
    public Guid StaffId { get; set; }
    public string StaffName { get; set; } = default!;
    public string StaffRole { get; set; } = default!;
    public string PeriodStart { get; set; } = default!;
    public string PeriodEnd { get; set; } = default!;
    public SalesMetricsDto Sales { get; set; } = new();
    public EventMetricsDto Events { get; set; } = new();
    public ProductionMetricsDto Production { get; set; } = new();
    public DeliveryMetricsDto Deliveries { get; set; } = new();
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
    public decimal TotalDiscountsGiven { get; set; }
    public int WalkInSales { get; set; }
    public int PhoneSales { get; set; }
    public int OnlineSales { get; set; }
}

public class EventMetricsDto
{
    public int EventsAssigned { get; set; }
    public int EventsCompleted { get; set; }
    public int ProposalsCreated { get; set; }
    public int ProposalsApproved { get; set; }
    public decimal EventRevenue { get; set; }
    public decimal EventProfit { get; set; }
}

public class ProductionMetricsDto
{
    public int ItemsAssigned { get; set; }
    public int ItemsCompleted { get; set; }
    public int ItemsInProgress { get; set; }
    public decimal ProductionCompletionRate { get; set; }
    public decimal? AverageCompletionTime { get; set; }
}

public class DeliveryMetricsDto
{
    public int DeliveriesAssigned { get; set; }
    public int DeliveriesCompleted { get; set; }
    public int DeliveriesOnTime { get; set; }
    public decimal OnTimeRate { get; set; }
    public decimal? TotalDistance { get; set; }
}

public class CommissionMetricsDto
{
    public decimal CommissionBase { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal CommissionEarned { get; set; }
    public string? PeriodStart { get; set; }
    public string? PeriodEnd { get; set; }
}
