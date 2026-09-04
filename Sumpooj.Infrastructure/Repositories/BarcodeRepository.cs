using Microsoft.EntityFrameworkCore;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure.Repositories;

public class BarcodeRepository : IBarcodeRepository
{
    private readonly SumpoojDbContext _db;

    public BarcodeRepository(SumpoojDbContext db)
    {
        _db = db;
    }

    public Task<List<Barcode>> GetByProductIdAsync(Guid productId)
        => _db.Barcodes.Where(b => b.ProductId == productId).ToListAsync();

    public Task<Barcode?> GetByCompanyAndValueAsync(Guid companyId, string value)
        => _db.Barcodes.FirstOrDefaultAsync(b => b.CompanyId == companyId && b.Value == value);

    public async Task<bool> ValueExistsAsync(Guid companyId, string value, Guid? excludeBarcodeId = null)
    {
        var query = _db.Barcodes.Where(b => b.CompanyId == companyId && b.Value == value);
        if (excludeBarcodeId.HasValue)
        {
            query = query.Where(b => b.Id != excludeBarcodeId.Value);
        }
        return await query.AnyAsync();
    }

    public Task<int> CountByCompanyAndTypeAsync(Guid companyId, BarcodeType type)
        => _db.Barcodes.CountAsync(b => b.CompanyId == companyId && b.Type == type);

    public async Task AddAsync(Barcode barcode)
    {
        _db.Barcodes.Add(barcode);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex)
        {
            throw new ConcurrencyConflictException($"Barcode '{barcode.Value}' is already in use.", ex);
        }
    }

    public async Task UpdateAsync(Barcode barcode)
    {
        _db.Barcodes.Update(barcode);
        await _db.SaveChangesAsync();
    }
}
