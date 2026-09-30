using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class CloudDesignRepository : ICloudDesignRepository
{
    private readonly SumpoojDbContext _db;

    public CloudDesignRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<CloudDesign?> GetByIdAsync(Guid companyId, Guid id)
        => _db.CloudDesigns
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.Id == id && x.DeletedAtUtc == null);

    public Task<CloudDesign?> GetBySourceLibraryDesignIdAsync(Guid companyId, Guid sourceLibraryDesignId)
        => _db.CloudDesigns
            .FirstOrDefaultAsync(x => x.CompanyId == companyId && x.SourceLibraryDesignId == sourceLibraryDesignId && x.DeletedAtUtc == null);

    public Task<int> CountByCompanyAsync(Guid companyId)
        => _db.CloudDesigns.CountAsync(x => x.CompanyId == companyId);

    public async Task AddAsync(CloudDesign design)
    {
        _db.CloudDesigns.Add(design);
        await _db.SaveChangesAsync();
    }

    public async Task UpdateAsync(CloudDesign design)
    {
        _db.CloudDesigns.Update(design);
        await _db.SaveChangesAsync();
    }

    public async Task DeleteAsync(CloudDesign design)
    {
        _db.CloudDesigns.Remove(design);
        await _db.SaveChangesAsync();
    }
}
