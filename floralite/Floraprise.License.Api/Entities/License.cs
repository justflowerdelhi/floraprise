namespace Floraprise.License.Api.Entities;

public sealed class License
{
    public Guid Id { get; set; }
    public Guid CustomerId { get; set; }
    public LicensePlan Plan { get; set; }
    public LicenseStatus Status { get; set; }
    public DateTime TrialStart { get; set; }
    public DateTime TrialEnd { get; set; }
    public DateTime? LicenseStart { get; set; }
    public DateTime? LicenseEnd { get; set; }
    public DateTime CreatedAt { get; set; }

    public Customer? Customer { get; set; }
}

public enum LicensePlan
{
    Trial,
    HalfYearly,
    Yearly
}

public enum LicenseStatus
{
    Trial,
    Active,
    Expired,
    Suspended
}