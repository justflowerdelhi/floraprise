using Sumpooj.Application.Common;
using Sumpooj.Application.Tasks;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ITaskRepository
{
    Task<StaffTask?> GetByIdAsync(Guid companyId, Guid id);
    Task<PagedResult<TaskDto>> SearchAsync(Guid companyId, TaskSearchRequest request);
    Task<List<TaskDto>> GetByStaffIdAsync(Guid companyId, Guid staffId);
    Task<List<TaskDto>> GetPendingTasksAsync(Guid companyId, Guid? locationId = null);
    Task<int> GetPendingTaskCountAsync(Guid companyId);
    Task AddAsync(StaffTask task);
    Task UpdateAsync(StaffTask task);
}
