namespace Sumpooj.Domain.Entities;

public class Staff : BaseEntity
{
    private Staff() { }

    public Staff(
        Guid companyId,
        string name,
        StaffRole role,
        string? email,
        string? phone,
        Guid? userId)
    {
        CompanyId = companyId;
        Name = name;
        Role = role;
        Email = email;
        Phone = phone;
        UserId = userId;
        IsActive = true;
    }

    public Guid CompanyId { get; private set; }
    public string Name { get; private set; }
    public StaffRole Role { get; private set; }
    public string? Email { get; private set; }
    public string? Phone { get; private set; }
    public Guid? UserId { get; private set; }

    /// <summary>
    /// Optional link to ASP.NET Identity user (ApplicationUser.Id).
    /// Allows a staff member to log in to the system.
    /// Navigation property configured in SumpoojDbContext (Infrastructure layer).
    /// </summary>
    public Guid? IdentityUserId { get; private set; }

    public bool IsActive { get; private set; }

    // Commission Settings
    public CommissionType? CommissionType { get; private set; }
    public decimal? CommissionRate { get; private set; }
    public decimal? HourlyRate { get; private set; }

    // Location Assignment
    public Guid? PrimaryLocationId { get; private set; }

    public void UpdateDetails(string name, string? email, string? phone)
    {
        Name = name;
        Email = email;
        Phone = phone;
        MarkUpdated();
    }

    public void SetRole(StaffRole role)
    {
        Role = role;
        MarkUpdated();
    }

    public void SetCommission(CommissionType? type, decimal? rate)
    {
        CommissionType = type;
        CommissionRate = rate;
        MarkUpdated();
    }

    public void SetHourlyRate(decimal? rate)
    {
        HourlyRate = rate;
        MarkUpdated();
    }

    public void AssignLocation(Guid? locationId)
    {
        PrimaryLocationId = locationId;
        MarkUpdated();
    }

    public void LinkUser(Guid userId)
    {
        UserId = userId;
        MarkUpdated();
    }

    /// <summary>
    /// Link this staff member to an ASP.NET Identity user for login access.
    /// </summary>
    public void LinkIdentityUser(Guid identityUserId)
    {
        IdentityUserId = identityUserId;
        MarkUpdated();
    }

    /// <summary>
    /// Remove the identity link (staff can no longer log in).
    /// </summary>
    public void UnlinkIdentityUser()
    {
        IdentityUserId = null;
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
