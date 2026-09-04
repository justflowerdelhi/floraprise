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
    public string? BirthdayMonthDay { get; private set; }
    public string? AnniversaryMonthDay { get; private set; }
    public string? CompanyName { get; private set; }
    public string? Department { get; private set; }
    public DateTime? LastOrderAtUtc { get; private set; }
    public decimal PendingPaymentAmount { get; private set; }
    public int RewardPoints { get; private set; }
    public int LifetimeRewardPoints { get; private set; }
    public int RedeemedRewardPoints { get; private set; }
    public DateTime? LastRewardActivityAtUtc { get; private set; }

    public void UpdateContact(string? email, string? phone, string name)
    {
        Name = name;
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

    public void UpdateMobileCrm(string? birthdayMonthDay, string? anniversaryMonthDay, string? companyName,
        string? department, string? notes, int totalOrders, DateTime? lastOrderAtUtc, decimal pendingPaymentAmount,
        int rewardPoints, int lifetimeRewardPoints, int redeemedRewardPoints, DateTime? lastRewardActivityAtUtc)
    {
        if (totalOrders < 0 || pendingPaymentAmount < 0 || rewardPoints < 0 || lifetimeRewardPoints < 0 || redeemedRewardPoints < 0)
            throw new ArgumentOutOfRangeException(nameof(totalOrders), "Customer balances and counts cannot be negative.");
        BirthdayMonthDay = NormalizeMonthDay(birthdayMonthDay); AnniversaryMonthDay = NormalizeMonthDay(anniversaryMonthDay);
        CompanyName = NullIfWhiteSpace(companyName); Department = NullIfWhiteSpace(department); Notes = NullIfWhiteSpace(notes);
        TotalOrders = totalOrders; LastOrderAtUtc = EnsureUtc(lastOrderAtUtc); PendingPaymentAmount = pendingPaymentAmount;
        RewardPoints = rewardPoints; LifetimeRewardPoints = lifetimeRewardPoints; RedeemedRewardPoints = redeemedRewardPoints;
        LastRewardActivityAtUtc = EnsureUtc(lastRewardActivityAtUtc); MarkUpdated();
    }

    private static string? NormalizeMonthDay(string? value)
    {
        if (string.IsNullOrWhiteSpace(value)) return null;
        var trimmed = value.Trim();
        if (trimmed.Length != 5 || trimmed[2] != '-' || !int.TryParse(trimmed[..2], out var month) || !int.TryParse(trimmed[3..], out var day) || month is < 1 or > 12 || day is < 1 or > 31)
            throw new InvalidOperationException("Birthday and anniversary must use MM-dd.");
        return trimmed;
    }
    private static string? NullIfWhiteSpace(string? value) => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

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
