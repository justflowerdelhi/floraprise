namespace Sumpooj.Application.Dashboard;

/// <summary>
/// DTO returned by GET /api/dashboard-preference.
/// </summary>
public class DashboardPreferenceDto
{
    /// <summary>Module keys the user has chosen to show (empty = use defaults).</summary>
    public List<string> VisibleModules { get; set; } = new();

    /// <summary>Module keys in the user's preferred display order.</summary>
    public List<string> ModuleOrder { get; set; } = new();

    /// <summary>True when the user has no saved preference yet (defaults returned).</summary>
    public bool IsDefault { get; set; }
}

/// <summary>
/// Request body for POST /api/dashboard-preference.
/// </summary>
public class SaveDashboardPreferenceRequest
{
    public List<string> VisibleModules { get; set; } = new();
    public List<string> ModuleOrder { get; set; } = new();
}
