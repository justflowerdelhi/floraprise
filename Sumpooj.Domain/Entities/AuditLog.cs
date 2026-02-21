namespace Sumpooj.Domain.Entities;

/// <summary>
/// Tracks all user actions in the system for compliance and debugging
/// </summary>
public class AuditLog : BaseEntity
{
    private AuditLog() { }

    public AuditLog(
        Guid companyId,
        Guid? userId,
        string? userName,
        string action,
        string entityType,
        Guid? entityId,
        string? entityName)
    {
        CompanyId = companyId;
        UserId = userId;
        UserName = userName;
        Action = action;
        EntityType = entityType;
        EntityId = entityId;
        EntityName = entityName;
        Timestamp = DateTime.UtcNow;
    }

    public Guid CompanyId { get; private set; }
    public Guid? UserId { get; private set; }
    public string? UserName { get; private set; }
    public string? UserRole { get; private set; }
    
    /// <summary>
    /// Action type: CREATE, UPDATE, DELETE, VIEW, LOGIN, LOGOUT, etc.
    /// </summary>
    public string Action { get; private set; } = default!;
    
    /// <summary>
    /// Entity type: Order, Product, Customer, etc.
    /// </summary>
    public string EntityType { get; private set; } = default!;
    
    /// <summary>
    /// ID of the affected entity
    /// </summary>
    public Guid? EntityId { get; private set; }
    
    /// <summary>
    /// Human-readable name/identifier of the entity (e.g., Order Number, Product Name)
    /// </summary>
    public string? EntityName { get; private set; }
    
    /// <summary>
    /// JSON representation of old values (for updates)
    /// </summary>
    public string? OldValues { get; private set; }
    
    /// <summary>
    /// JSON representation of new values (for creates/updates)
    /// </summary>
    public string? NewValues { get; private set; }
    
    /// <summary>
    /// Additional context or description
    /// </summary>
    public string? Description { get; private set; }
    
    /// <summary>
    /// IP address of the request
    /// </summary>
    public string? IpAddress { get; private set; }
    
    /// <summary>
    /// User agent string
    /// </summary>
    public string? UserAgent { get; private set; }
    
    /// <summary>
    /// Request path
    /// </summary>
    public string? RequestPath { get; private set; }
    
    /// <summary>
    /// HTTP method
    /// </summary>
    public string? HttpMethod { get; private set; }
    
    /// <summary>
    /// When the action occurred
    /// </summary>
    public DateTime Timestamp { get; private set; }
    
    /// <summary>
    /// Duration of the action in milliseconds (optional)
    /// </summary>
    public long? DurationMs { get; private set; }
    
    /// <summary>
    /// Whether the action was successful
    /// </summary>
    public bool IsSuccess { get; private set; } = true;
    
    /// <summary>
    /// Error message if action failed
    /// </summary>
    public string? ErrorMessage { get; private set; }

    public void SetUserRole(string? role)
    {
        UserRole = role;
    }

    public void SetOldValues(string? json)
    {
        OldValues = json;
    }

    public void SetNewValues(string? json)
    {
        NewValues = json;
    }

    public void SetDescription(string? description)
    {
        Description = description;
    }

    public void SetRequestInfo(string? ipAddress, string? userAgent, string? requestPath, string? httpMethod)
    {
        IpAddress = ipAddress;
        UserAgent = userAgent;
        RequestPath = requestPath;
        HttpMethod = httpMethod;
    }

    public void SetDuration(long durationMs)
    {
        DurationMs = durationMs;
    }

    public void MarkFailed(string errorMessage)
    {
        IsSuccess = false;
        ErrorMessage = errorMessage;
    }
}

/// <summary>
/// Standard audit action types
/// </summary>
public static class AuditActions
{
    // CRUD Operations
    public const string Create = "CREATE";
    public const string Read = "READ";
    public const string Update = "UPDATE";
    public const string Delete = "DELETE";
    
    // Authentication
    public const string Login = "LOGIN";
    public const string Logout = "LOGOUT";
    public const string LoginFailed = "LOGIN_FAILED";
    public const string PasswordChanged = "PASSWORD_CHANGED";
    public const string PasswordReset = "PASSWORD_RESET";
    
    // Order Operations
    public const string OrderCreated = "ORDER_CREATED";
    public const string OrderUpdated = "ORDER_UPDATED";
    public const string OrderCancelled = "ORDER_CANCELLED";
    public const string OrderStatusChanged = "ORDER_STATUS_CHANGED";
    
    // Payment Operations
    public const string PaymentReceived = "PAYMENT_RECEIVED";
    public const string PaymentVoided = "PAYMENT_VOIDED";
    public const string RefundProcessed = "REFUND_PROCESSED";
    
    // Inventory Operations
    public const string StockAdjusted = "STOCK_ADJUSTED";
    public const string BatchReceived = "BATCH_RECEIVED";
    public const string BatchExpired = "BATCH_EXPIRED";
    
    // Day Close
    public const string DayClosed = "DAY_CLOSED";
    
    // Settings
    public const string SettingsChanged = "SETTINGS_CHANGED";
    
    // Export/Import
    public const string DataExported = "DATA_EXPORTED";
    public const string DataImported = "DATA_IMPORTED";
}
