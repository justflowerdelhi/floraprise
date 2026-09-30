using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface ICloudDesignRepository
{
    Task<CloudDesign?> GetByIdAsync(Guid companyId, Guid id);
    Task<CloudDesign?> GetBySourceLibraryDesignIdAsync(Guid companyId, Guid sourceLibraryDesignId);
    Task<int> CountByCompanyAsync(Guid companyId);
    Task AddAsync(CloudDesign design);
    Task UpdateAsync(CloudDesign design);
    Task DeleteAsync(CloudDesign design);
}
