using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public record InventoryEntryRequest(
    Guid ProductId,
    int Quantity,
    decimal CostPerUnit,
    decimal? SellingPricePerUnit,
    DateTime ReceivedDate,
    DateTime? ExpiryDate,
    int? ShelfLifeDays,
    Guid? SupplierId,
    Guid? LocationId,
    string? StorageLocation,
    string Source,
    Guid? PurchaseOrderId,
    bool MergeWithSameDayBatch = false
);

public record InventoryEntryResult(Guid BatchId, string BatchNumber, bool MergedIntoExistingBatch);

/// <summary>
/// Shared inventory entry pipeline used by QuickReceive, DirectAdd and PO receive.
/// Keeps batch creation, stock updates and ledger writes consistent across flows.
/// </summary>
public class InventoryEntryService
{
    private readonly IProductRepository _productRepo;
    private readonly IProductBatchRepository _batchRepo;
    private readonly IInventoryLedgerRepository _ledgerRepo;
    private readonly ITenantContext _tenant;

    public InventoryEntryService(
        IProductRepository productRepo,
        IProductBatchRepository batchRepo,
        IInventoryLedgerRepository ledgerRepo,
        ITenantContext tenant)
    {
        _productRepo = productRepo;
        _batchRepo = batchRepo;
        _ledgerRepo = ledgerRepo;
        _tenant = tenant;
    }

    public async Task<InventoryEntryResult> CreateInventoryEntryAsync(InventoryEntryRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        if (request.Quantity <= 0)
            throw new InvalidOperationException("Quantity must be greater than zero");

        var companyId = _tenant.CompanyId.Value;
        var product = await _productRepo.GetByIdAsync(request.ProductId)
            ?? throw new KeyNotFoundException($"Product {request.ProductId} not found");

        var expiryDate = ResolveExpiryDate(
            request.ExpiryDate,
            request.ShelfLifeDays,
            product.ShelfLifeDays,
            request.ReceivedDate);

        if (request.MergeWithSameDayBatch)
        {
            var mergeCandidate = await _batchRepo.GetLatestActiveByProductAndDateAsync(request.ProductId, request.ReceivedDate);
            if (mergeCandidate != null)
            {
                mergeCandidate.ReceiveAdditionalQuantity(request.Quantity);
                await _batchRepo.UpdateAsync(mergeCandidate);

                await UpdateStockAndLedgerAsync(
                    companyId,
                    product,
                    request.Quantity,
                    request.Source,
                    mergeCandidate.BatchNumber,
                    mergedIntoExisting: true);

                return new InventoryEntryResult(mergeCandidate.Id, mergeCandidate.BatchNumber, true);
            }
        }

        var batchNumber = await GenerateUniqueBatchNumberAsync(product, request.ReceivedDate);

        var batch = new ProductBatch(
            companyId: companyId,
            productId: request.ProductId,
            batchNumber: batchNumber,
            quantityReceived: request.Quantity,
            costPerUnit: request.CostPerUnit,
            receivedDate: request.ReceivedDate,
            expiryDate: expiryDate,
            supplierId: request.SupplierId,
            locationId: request.LocationId,
            storageLocation: request.StorageLocation);

        if (request.SellingPricePerUnit.HasValue)
            batch.SetSellingPrice(request.SellingPricePerUnit.Value);

        if (request.PurchaseOrderId.HasValue)
            batch.LinkToPurchaseOrder(request.PurchaseOrderId.Value);

        await _batchRepo.AddAsync(batch);

        await UpdateStockAndLedgerAsync(
            companyId,
            product,
            request.Quantity,
            request.Source,
            batchNumber,
            mergedIntoExisting: false);

        return new InventoryEntryResult(batch.Id, batchNumber, false);
    }

    private async Task UpdateStockAndLedgerAsync(
        Guid companyId,
        Product product,
        int quantity,
        string source,
        string batchNumber,
        bool mergedIntoExisting)
    {
        if (!product.TrackInventory)
            return;

        product.AdjustStock(quantity);
        await _productRepo.UpdateAsync(product);

        var note = mergedIntoExisting
            ? $"Merged same-day batch:{batchNumber}"
            : $"Batch:{batchNumber}";

        await _ledgerRepo.AddAsync(new InventoryLedger(
            companyId,
            product.Id,
            source,
            "IN",
            quantity,
            product.StockQuantity,
            note));
    }

    private static DateTime? ResolveExpiryDate(
        DateTime? providedExpiry,
        int? requestShelfLife,
        int? productShelfLife,
        DateTime receivedDate)
    {
        if (providedExpiry.HasValue)
            return providedExpiry.Value;

        var days = requestShelfLife ?? productShelfLife;
        if (days.HasValue && days.Value > 0)
            return receivedDate.AddDays(days.Value);

        return null;
    }

    private async Task<string> GenerateUniqueBatchNumberAsync(Product product, DateTime receivedDate)
    {
        var skuPrefix = string.IsNullOrWhiteSpace(product.Sku)
            ? "NOSKU"
            : product.Sku.Trim().Replace(" ", "-").ToUpperInvariant();

        for (var attempt = 0; attempt < 8; attempt++)
        {
            var random = Random.Shared.Next(0, 16 * 16 * 16).ToString("X3");
            var candidate = $"{skuPrefix}-{receivedDate:yyyyMMdd-HHmmss}-{random}";

            var exists = await _batchRepo.BatchNumberExistsAsync(product.Id, candidate);
            if (!exists)
                return candidate;
        }

        throw new InvalidOperationException("Could not allocate a unique batch number. Please retry.");
    }
}
