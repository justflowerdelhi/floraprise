namespace Sumpooj.Application.Customers;

public class UpdateCustomerRequest
{
    public string Name { get; set; } = default!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? BirthdayMonthDay { get; set; }
    public string? AnniversaryMonthDay { get; set; }
    public string? CompanyName { get; set; }
    public string? Department { get; set; }
    public string? Notes { get; set; }
    public int TotalOrders { get; set; }
    public DateTime? LastOrderAtUtc { get; set; }
    public decimal PendingPaymentAmount { get; set; }
    public int RewardPoints { get; set; }
    public int LifetimeRewardPoints { get; set; }
    public int RedeemedRewardPoints { get; set; }
    public DateTime? LastRewardActivityAtUtc { get; set; }
}
