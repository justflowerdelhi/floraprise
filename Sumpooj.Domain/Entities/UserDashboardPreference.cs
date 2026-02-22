namespace Sumpooj.Domain.Entities;

/// <summary>
/// Stores per-user dashboard module visibility and ordering.
/// Each user within a company can choose which modules appear
/// on their /home Control Center and in what order.
/// </summary>
public class UserDashboardPreference : BaseEntity
{
    private UserDashboardPreference() { }

    public UserDashboardPreference(Guid companyId, Guid userId)
    {
        CompanyId = companyId;
        UserId = userId;
        VisibleModules = "[]";
        ModuleOrder = "[]";
    }

    /// <summary>Company (tenant) this preference belongs to.</summary>
    public Guid CompanyId { get; private set; }

    /// <summary>The ASP.NET Identity user.</summary>
    public Guid UserId { get; private set; }

    /// <summary>JSON array of visible module keys, e.g. ["POS","Orders","Inventory"].</summary>
    public string VisibleModules { get; private set; } = "[]";

    /// <summary>JSON array defining tile display order, e.g. ["POS","CRM","Orders"].</summary>
    public string ModuleOrder { get; private set; } = "[]";

    // ─── Mutations ──────────────────────────────────────

    public void Update(string visibleModules, string moduleOrder)
    {
        VisibleModules = visibleModules;
        ModuleOrder = moduleOrder;
        MarkUpdated();
    }
}
