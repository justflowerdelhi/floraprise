namespace Sumpooj.Domain.Entities;

public class CorporateClient : BaseEntity
{
    private readonly List<CorporateEmployee> _employees = new();

    private CorporateClient() { }

    public CorporateClient(
        Guid companyId,
        Guid customerId,
        string name,
        string billingEmail,
        string? phone,
        decimal? creditLimit,
        string? paymentTerms,
        string billingCycle,
        Guid? defaultProductId,
        string? defaultMessage)
    {
        CompanyId = companyId;
        CustomerId = customerId;
        Name = name;
        BillingEmail = billingEmail;
        Phone = phone;
        CreditLimit = creditLimit;
        PaymentTerms = paymentTerms;
        BillingCycle = billingCycle;
        DefaultProductId = defaultProductId;
        DefaultMessage = defaultMessage;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid CustomerId { get; private set; }
    public Customer? Customer { get; private set; }

    public string Name { get; private set; } = default!;
    public string BillingEmail { get; private set; } = default!;
    public string? Phone { get; private set; }
    public decimal? CreditLimit { get; private set; }
    public string? PaymentTerms { get; private set; }
    public string BillingCycle { get; private set; } = "MONTHLY";
    public Guid? DefaultProductId { get; private set; }
    public string? DefaultMessage { get; private set; }
    public bool IsActive { get; private set; }

    public IReadOnlyCollection<CorporateEmployee> Employees => _employees.AsReadOnly();

    public void UpdateProfile(
        string name,
        string billingEmail,
        string? phone,
        decimal? creditLimit,
        string? paymentTerms,
        string billingCycle,
        Guid? defaultProductId,
        string? defaultMessage)
    {
        Name = name;
        BillingEmail = billingEmail;
        Phone = phone;
        CreditLimit = creditLimit;
        PaymentTerms = paymentTerms;
        BillingCycle = billingCycle;
        DefaultProductId = defaultProductId;
        DefaultMessage = defaultMessage;
        MarkUpdated();
    }

    public void MarkActive(bool isActive)
    {
        IsActive = isActive;
        MarkUpdated();
    }
}

public class CorporateEmployee : BaseEntity
{
    private CorporateEmployee() { }

    public CorporateEmployee(
        Guid companyId,
        Guid clientId,
        string name,
        DateTime dateOfBirth,
        string? address)
    {
        CompanyId = companyId;
        ClientId = clientId;
        Name = name;
        DateOfBirth = EnsureUtc(dateOfBirth);
        Address = address;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public Guid ClientId { get; private set; }
    public CorporateClient? Client { get; private set; }
    public string Name { get; private set; } = default!;
    public DateTime DateOfBirth { get; private set; }
    public string? Address { get; private set; }
    public bool IsActive { get; private set; }

    public void Update(string name, DateTime dateOfBirth, string? address, bool isActive)
    {
        Name = name;
        DateOfBirth = EnsureUtc(dateOfBirth);
        Address = address;
        IsActive = isActive;
        MarkUpdated();
    }
}

public class CorporateOrderMeta : BaseEntity
{
    private CorporateOrderMeta() { }

    public CorporateOrderMeta(
        Guid companyId,
        Guid orderId,
        Guid clientId,
        CorporateBillingStatus billingStatus,
        Guid? employeeId,
        bool isAutoCreated,
        bool needsApproval,
        DateTime? automationDateUtc)
    {
        CompanyId = companyId;
        OrderId = orderId;
        ClientId = clientId;
        BillingStatus = billingStatus;
        EmployeeId = employeeId;
        IsAutoCreated = isAutoCreated;
        NeedsApproval = needsApproval;
        AutomationDateUtc = automationDateUtc.HasValue ? EnsureUtc(automationDateUtc.Value) : null;
        IsAccountingPosted = false;
        IsInventoryPosted = false;
    }

    public Guid CompanyId { get; private set; }
    public Guid OrderId { get; private set; }
    public Order? Order { get; private set; }
    public Guid ClientId { get; private set; }
    public CorporateClient? Client { get; private set; }
    public Guid? EmployeeId { get; private set; }
    public CorporateEmployee? Employee { get; private set; }
    public CorporateBillingStatus BillingStatus { get; private set; }
    public bool IsAutoCreated { get; private set; }
    public bool NeedsApproval { get; private set; }
    public DateTime? AutomationDateUtc { get; private set; }
    public bool IsAccountingPosted { get; private set; }
    public bool IsInventoryPosted { get; private set; }

    public void MarkApproved()
    {
        NeedsApproval = false;
        MarkUpdated();
    }

    public void MarkAccountingPosted()
    {
        IsAccountingPosted = true;
        MarkUpdated();
    }

    public void MarkInventoryPosted()
    {
        IsInventoryPosted = true;
        MarkUpdated();
    }

    public void MarkBillingStatus(CorporateBillingStatus status)
    {
        BillingStatus = status;
        MarkUpdated();
    }
}

public class CorporateInvoice : BaseEntity
{
    private readonly List<CorporateInvoiceLine> _lines = new();

    private CorporateInvoice() { }

    public CorporateInvoice(
        Guid companyId,
        Guid clientId,
        DateTime startDateUtc,
        DateTime endDateUtc,
        decimal totalAmount)
    {
        CompanyId = companyId;
        ClientId = clientId;
        StartDateUtc = EnsureUtc(startDateUtc);
        EndDateUtc = EnsureUtc(endDateUtc);
        TotalAmount = totalAmount;
        Status = CorporateInvoiceStatus.Draft;
    }

    public Guid CompanyId { get; private set; }
    public Guid ClientId { get; private set; }
    public CorporateClient? Client { get; private set; }
    public DateTime StartDateUtc { get; private set; }
    public DateTime EndDateUtc { get; private set; }
    public decimal TotalAmount { get; private set; }
    public CorporateInvoiceStatus Status { get; private set; }
    public DateTime? PaidAtUtc { get; private set; }

    public ICollection<CorporateInvoiceLine> Lines => _lines;

    public void AddLine(Guid orderId, string orderNumber, DateTime orderDateUtc, decimal amount)
    {
        _lines.Add(new CorporateInvoiceLine(CompanyId, Id, orderId, orderNumber, orderDateUtc, amount));
        MarkUpdated();
    }

    public void MarkSent()
    {
        Status = CorporateInvoiceStatus.Sent;
        MarkUpdated();
    }

    public void MarkPaid(DateTime paidAtUtc)
    {
        Status = CorporateInvoiceStatus.Paid;
        PaidAtUtc = EnsureUtc(paidAtUtc);
        MarkUpdated();
    }
}

public class CorporateInvoiceLine : BaseEntity
{
    private CorporateInvoiceLine() { }

    public CorporateInvoiceLine(
        Guid companyId,
        Guid invoiceId,
        Guid orderId,
        string orderNumber,
        DateTime orderDateUtc,
        decimal amount)
    {
        CompanyId = companyId;
        InvoiceId = invoiceId;
        OrderId = orderId;
        OrderNumber = orderNumber;
        OrderDateUtc = EnsureUtc(orderDateUtc);
        Amount = amount;
    }

    public Guid CompanyId { get; private set; }
    public Guid InvoiceId { get; private set; }
    public CorporateInvoice? Invoice { get; private set; }
    public Guid OrderId { get; private set; }
    public string OrderNumber { get; private set; } = default!;
    public DateTime OrderDateUtc { get; private set; }
    public decimal Amount { get; private set; }
}