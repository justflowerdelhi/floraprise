using Sumpooj.Application.Common;
using Sumpooj.Application.Staff;

namespace Sumpooj.Application.Interfaces;

public interface IStaffRepository
{
    Task<Domain.Entities.Staff?> GetByIdAsync(Guid companyId, Guid id);
    Task<PagedResult<StaffListDto>> SearchAsync(Guid companyId, StaffSearchRequest request);
    Task<List<StaffListDto>> GetAllActiveAsync(Guid companyId);
    Task<List<StaffListDto>> GetByRoleAsync(Guid companyId, string role);
    Task AddAsync(Domain.Entities.Staff staff);
    Task UpdateAsync(Domain.Entities.Staff staff);
}
