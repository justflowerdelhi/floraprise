using Sumpooj.Application.Dashboard;

namespace Sumpooj.Application.Interfaces;

public interface IDashboardPreferenceRepository
{
    Task<DashboardPreferenceDto?> GetByUserAsync(Guid companyId, Guid userId);
    Task<DashboardPreferenceDto> SaveAsync(Guid companyId, Guid userId, SaveDashboardPreferenceRequest request);
}
