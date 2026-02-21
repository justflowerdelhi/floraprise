namespace Sumpooj.Application.Audit;

public class AuditLogDto
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public string? UserRole { get; set; }
    public string Action { get; set; } = default!;
    public string EntityType { get; set; } = default!;
    public Guid? EntityId { get; set; }
    public string? EntityName { get; set; }
    public string? OldValues { get; set; }
    public string? NewValues { get; set; }
    public string? Description { get; set; }
    public string? IpAddress { get; set; }
    public string? RequestPath { get; set; }
    public string? HttpMethod { get; set; }
    public DateTime Timestamp { get; set; }
    public long? DurationMs { get; set; }
    public bool IsSuccess { get; set; }
    public string? ErrorMessage { get; set; }
}

public class AuditLogSearchRequest
{
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public string? Action { get; set; }
    public string? EntityType { get; set; }
    public Guid? EntityId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public bool? IsSuccess { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 50;
}

public class AuditLogSummaryDto
{
    public DateTime Date { get; set; }
    public int TotalActions { get; set; }
    public int SuccessfulActions { get; set; }
    public int FailedActions { get; set; }
    public Dictionary<string, int> ActionBreakdown { get; set; } = new();
    public Dictionary<string, int> EntityBreakdown { get; set; } = new();
    public List<UserActivityDto> TopUsers { get; set; } = new();
}

public class UserActivityDto
{
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public int ActionCount { get; set; }
    public DateTime? LastActivity { get; set; }
}

public class CreateAuditLogRequest
{
    public string Action { get; set; } = default!;
    public string EntityType { get; set; } = default!;
    public Guid? EntityId { get; set; }
    public string? EntityName { get; set; }
    public object? OldValue { get; set; }
    public object? NewValue { get; set; }
    public string? Description { get; set; }
}
