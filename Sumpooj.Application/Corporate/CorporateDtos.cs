using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Corporate;

public class CorporateClientDto
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public string Name { get; set; } = default!;
    public string BillingEmail { get; set; } = default!;
    public string? Phone { get; set; }
    public decimal? CreditLimit { get; set; }
    public string? PaymentTerms { get; set; }
    public string BillingCycle { get; set; } = "MONTHLY";
    public Guid? DefaultProductId { get; set; }
    public string? DefaultMessage { get; set; }
    public bool IsActive { get; set; }
    public decimal OutstandingAmount { get; set; }
    public int ActiveEmployees { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class CorporateEmployeeDto
{
    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public string Name { get; set; } = default!;
    public DateTime DateOfBirth { get; set; }
    public string? Address { get; set; }
    public bool IsActive { get; set; }
}

public class CorporateInvoiceDto
{
    public Guid Id { get; set; }
    public Guid ClientId { get; set; }
    public DateTime StartDateUtc { get; set; }
    public DateTime EndDateUtc { get; set; }
    public decimal TotalAmount { get; set; }
    public CorporateInvoiceStatus Status { get; set; }
    public DateTime? PaidAtUtc { get; set; }
    public List<CorporateInvoiceLineDto> Lines { get; set; } = new();
    public DateTime CreatedAtUtc { get; set; }
}

public class CorporateInvoiceLineDto
{
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = default!;
    public DateTime OrderDateUtc { get; set; }
    public decimal Amount { get; set; }
}

public class CorporateOrderMetaDto
{
    public Guid OrderId { get; set; }
    public Guid ClientId { get; set; }
    public Guid? EmployeeId { get; set; }
    public CorporateBillingStatus BillingStatus { get; set; }
    public bool IsAutoCreated { get; set; }
    public bool NeedsApproval { get; set; }
    public DateTime? AutomationDateUtc { get; set; }
    public bool IsAccountingPosted { get; set; }
    public bool IsInventoryPosted { get; set; }
}

public class PendingCorporateApprovalOrderDto
{
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = default!;
    public Guid ClientId { get; set; }
    public string ClientName { get; set; } = default!;
    public Guid? EmployeeId { get; set; }
    public string? EmployeeName { get; set; }
    public DateTime OrderDateUtc { get; set; }
    public DateTime DeliveryDateUtc { get; set; }
    public string? DeliveryAddress { get; set; }
    public decimal TotalAmount { get; set; }
    public bool NeedsApproval { get; set; }
    public DateTime? AutomationDateUtc { get; set; }
}

public class CreateCorporateClientRequest
{
    public string Name { get; set; } = default!;
    public string BillingEmail { get; set; } = default!;
    public string? Phone { get; set; }
    public decimal? CreditLimit { get; set; }
    public string? PaymentTerms { get; set; }
    public string BillingCycle { get; set; } = "MONTHLY";
    public Guid? DefaultProductId { get; set; }
    public string? DefaultMessage { get; set; }
}

public class CreateCorporateEmployeeRequest
{
    public string Name { get; set; } = default!;
    public DateTime DateOfBirth { get; set; }
    public string? Address { get; set; }
}

public class CreateCorporateOrderRequest
{
    public Guid ClientId { get; set; }
    public string OrderType { get; set; } = "DELIVERY";
    public DateTime DeliveryDate { get; set; }
    public string? TimeSlot { get; set; }
    public string? DeliveryAddress { get; set; }
    public string? DeliveryPincode { get; set; }
    public string? RecipientName { get; set; }
    public string? RecipientPhone { get; set; }
    public string? Message { get; set; }
    public Guid? LocationId { get; set; }
    public List<CorporateOrderItemRequest> Items { get; set; } = new();
}

public class CorporateOrderItemRequest
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
}

public class CreateCorporateOrderResponse
{
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = default!;
    public Guid CorporateClientId { get; set; }
    public bool CreditLimitExceeded { get; set; }
}

public class GenerateCorporateInvoiceRequest
{
    public Guid ClientId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
}

public class RecordCorporateInvoicePaymentRequest
{
    public DateTime PaidAtUtc { get; set; } = DateTime.UtcNow;
    public string PaymentMethod { get; set; } = "BANK";
}

public class CorporateBirthdayAutomationResult
{
    public DateTime RunDateUtc { get; set; }
    public int CreatedOrders { get; set; }
    public int SkippedMissingDefaultProduct { get; set; }
    public int SkippedNoAddress { get; set; }
    public int SkippedDuplicate { get; set; }
}
