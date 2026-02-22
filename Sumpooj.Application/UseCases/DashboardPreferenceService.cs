using Sumpooj.Application.Dashboard;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.UseCases;

/// <summary>
/// Reads / writes per-user dashboard module preferences.
/// </summary>
public class DashboardPreferenceService
{
    private readonly IDashboardPreferenceRepository _repo;

    /// <summary>Default module list when the user has no saved preference.</summary>
    private static readonly List<string> DefaultModules = new()
    {
        "POS", "Orders", "Inventory", "CRM", "Production",
        "Events", "Payments", "Reports", "Settings"
    };

    public DashboardPreferenceService(IDashboardPreferenceRepository repo)
    {
        _repo = repo;
    }

    /// <summary>
    /// Returns the user's saved preference, or the default module list if none exists.
    /// </summary>
    public async Task<DashboardPreferenceDto> GetAsync(Guid companyId, Guid userId)
    {
        var pref = await _repo.GetByUserAsync(companyId, userId);

        if (pref is not null) return pref;

        return new DashboardPreferenceDto
        {
            VisibleModules = new List<string>(DefaultModules),
            ModuleOrder = new List<string>(DefaultModules),
            IsDefault = true,
        };
    }

    /// <summary>
    /// Creates or updates the user's dashboard preference.
    /// </summary>
    public async Task<DashboardPreferenceDto> SaveAsync(
        Guid companyId,
        Guid userId,
        SaveDashboardPreferenceRequest request)
    {
        return await _repo.SaveAsync(companyId, userId, request);
    }
}
