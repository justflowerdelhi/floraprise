namespace Sumpooj.Domain.Entities;

public class RewardsSettings : BaseEntity
{
    private RewardsSettings() { }

    public RewardsSettings(
        Guid companyId,
        bool enabled = true,
        int earnSpendPaisePerPoint = 10000,
        int minimumBillPaise = 30000,
        int pointValuePaise = 100,
        int maximumRedemptionPercent = 20,
        int expiryDays = 365)
    {
        if (companyId == Guid.Empty)
            throw new ArgumentException("CompanyId is required.", nameof(companyId));

        CompanyId = companyId;
        Update(
            enabled,
            earnSpendPaisePerPoint,
            minimumBillPaise,
            pointValuePaise,
            maximumRedemptionPercent,
            expiryDays);
    }

    public Guid CompanyId { get; private set; }

    public bool Enabled { get; private set; } = true;
    public int EarnSpendPaisePerPoint { get; private set; } = 10000;
    public int MinimumBillPaise { get; private set; } = 30000;
    public int PointValuePaise { get; private set; } = 100;
    public int MaximumRedemptionPercent { get; private set; } = 20;
    public int ExpiryDays { get; private set; } = 365;

    public void Update(
        bool enabled,
        int earnSpendPaisePerPoint,
        int minimumBillPaise,
        int pointValuePaise,
        int maximumRedemptionPercent,
        int expiryDays)
    {
        Enabled = enabled;
        EarnSpendPaisePerPoint = earnSpendPaisePerPoint;
        MinimumBillPaise = minimumBillPaise;
        PointValuePaise = pointValuePaise;
        MaximumRedemptionPercent = maximumRedemptionPercent;
        ExpiryDays = expiryDays;
        MarkUpdated();
    }
}
