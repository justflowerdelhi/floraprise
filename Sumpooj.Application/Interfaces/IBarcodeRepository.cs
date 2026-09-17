using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.Interfaces;

public interface IBarcodeRepository
{
    /// <summary>All barcodes (Manufacturer + Internal, if present) for a product, company-scoped.</summary>
    Task<List<Barcode>> GetByProductIdAsync(Guid productId);

    /// <summary>Batch retrieval of all barcodes for a set of product IDs, company-scoped.</summary>
    Task<List<Barcode>> GetByProductIdsAsync(IEnumerable<Guid> productIds);

    /// <summary>Looks up a barcode by its value within a company. Never crosses company boundaries.</summary>
    Task<Barcode?> GetByCompanyAndValueAsync(Guid companyId, string value);

    Task<bool> ValueExistsAsync(Guid companyId, string value, Guid? excludeBarcodeId = null);

    /// <summary>Used as the starting point for Internal barcode sequence generation.</summary>
    Task<int> CountByCompanyAndTypeAsync(Guid companyId, BarcodeType type);

    Task AddAsync(Barcode barcode);

    Task UpdateAsync(Barcode barcode);

    Task DeleteAsync(Barcode barcode);
}
