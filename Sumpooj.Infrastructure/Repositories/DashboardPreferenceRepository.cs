using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Dashboard;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class DashboardPreferenceRepository : IDashboardPreferenceRepository
{
    private readonly SumpoojDbContext _db;

    /// <summary>Default module list when no preference exists.</summary>
    private static readonly List<string> DefaultModules = new()
    {
        "POS", "Orders", "Inventory", "CRM", "Production",
        "Events", "Payments", "Reports", "Settings"
    };

    public DashboardPreferenceRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public async Task<DashboardPreferenceDto?> GetByUserAsync(Guid companyId, Guid userId)
    {
        var pref = await _db.UserDashboardPreferences
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.UserId == userId);

        if (pref is null) return null;

        return new DashboardPreferenceDto
        {
            VisibleModules = Deserialize(pref.VisibleModules),
            ModuleOrder = Deserialize(pref.ModuleOrder),
            IsDefault = false,
        };
    }

    public async Task<DashboardPreferenceDto> SaveAsync(
        Guid companyId,
        Guid userId,
        SaveDashboardPreferenceRequest request)
    {
        var pref = await _db.UserDashboardPreferences
            .FirstOrDefaultAsync(p => p.CompanyId == companyId && p.UserId == userId);

        var visibleJson = JsonSerializer.Serialize(request.VisibleModules);
        var orderJson = JsonSerializer.Serialize(request.ModuleOrder);

        if (pref is null)
        {
            pref = new UserDashboardPreference(companyId, userId);
            pref.Update(visibleJson, orderJson);
            _db.UserDashboardPreferences.Add(pref);
        }
        else
        {
            pref.Update(visibleJson, orderJson);
        }

        await _db.SaveChangesAsync();

        return new DashboardPreferenceDto
        {
            VisibleModules = request.VisibleModules,
            ModuleOrder = request.ModuleOrder,
            IsDefault = false,
        };
    }

    private static List<string> Deserialize(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? new List<string>(DefaultModules);
        }
        catch
        {
            return new List<string>(DefaultModules);
        }
    }
}
