namespace Sumpooj.Domain.Entities;

public class Supplier : BaseEntity
{
    private Supplier() { }

    public Supplier(
        Guid companyId,
        string name,
        string? contactPerson,
        string? email,
        string? phone,
        string? address)
    {
        CompanyId = companyId;
        Name = name;
        ContactPerson = contactPerson;
        Email = email;
        Phone = phone;
        Address = address;
        IsActive = true;
        Rating = SupplierRating.NotRated;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public string? ContactPerson { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public string? Address { get; private set; }
    public bool IsActive { get; private set; }

    public SupplierRating Rating { get; private set; }
    public string? Notes { get; private set; }

    // Payment terms
    public int PaymentTermsDays { get; private set; }
    public string? TaxIdentifier { get; private set; }

    // Relationship metrics
    public DateTime? LastOrderDate { get; private set; }
    public int TotalOrdersCount { get; private set; }
    public decimal TotalSpentAmount { get; private set; }

    public void UpdateContactInfo(
        string? contactPerson,
        string? email,
        string? phone,
        string? address)
    {
        ContactPerson = contactPerson;
        Email = email;
        Phone = phone;
        Address = address;
        MarkUpdated();
    }

    public void SetPaymentTerms(int days)
    {
        if (days < 0)
            throw new ArgumentException("Payment terms cannot be negative");

        PaymentTermsDays = days;
        MarkUpdated();
    }

    public void SetTaxIdentifier(string? taxId)
    {
        TaxIdentifier = taxId;
        MarkUpdated();
    }

    public void SetRating(SupplierRating rating)
    {
        Rating = rating;
        MarkUpdated();
    }

    public void AddNote(string note)
    {
        Notes = string.IsNullOrEmpty(Notes)
            ? note
            : $"{Notes}\n{note}";
        MarkUpdated();
    }

    public void RecordOrder(decimal amount)
    {
        LastOrderDate = DateTime.UtcNow;
        TotalOrdersCount++;
        TotalSpentAmount += amount;
        MarkUpdated();
    }

    public void Deactivate()
    {
        IsActive = false;
        MarkUpdated();
    }

    public void Activate()
    {
        IsActive = true;
        MarkUpdated();
    }
}
