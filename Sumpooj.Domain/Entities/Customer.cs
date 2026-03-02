namespace Sumpooj.Domain.Entities;

public class Customer : BaseEntity
{
    private Customer() { } // EF Core

    public Customer(
    Guid companyId,
    string name,
    string? email,
    string? phone)
    {
        CompanyId = companyId;
        Name = name;
        Email = email;
        Phone = phone;
        IsActive = true;
    }


    public string Name { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }

    // CRM features
    public bool IsActive { get; private set; }

    // Feature #12 – Default card message
    public string? DefaultCardMessage { get; private set; }

    // Feature #19 – Order visibility (count only here)
    public int TotalOrders { get; private set; }
    public Guid CompanyId { get; private set; }

    // CRM – internal notes
    public string? Notes { get; private set; }

    public void UpdateContact(string? email, string? phone)
    {
        Email = email;
        Phone = phone;
        MarkUpdated();
    }

    public void UpdateDefaultCardMessage(string? message)
    {
        DefaultCardMessage = message;
        MarkUpdated();
    }

    public void UpdateNotes(string? notes)
    {
        Notes = notes;
        MarkUpdated();
    }

    // Feature #13 – Soft hide, NOT delete
    public void MarkInactive()
    {
        IsActive = false;
        MarkUpdated();
    }

    public void MarkActive()
    {
        IsActive = true;
        MarkUpdated();
    }

    public void IncrementOrderCount()
    {
        TotalOrders++;
        MarkUpdated();
    }
}
