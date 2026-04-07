using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Domain.Entities;
using System.Transactions;

namespace Sumpooj.Application.UseCases;

/// <summary>
/// Handles quick stock intake flows that bypass the full PO lifecycle:
///   1. QuickReceive  — supplier-optional fast intake, creates PO record in Received state.
///   2. DirectAdd     — ultra-fast entry with no PO at all.
/// </summary>
public class StockReceiveService
{
    private readonly IProductRepository _productRepo;
    private readonly ISupplierRepository _supplierRepo;
    private readonly IPurchaseOrderRepository _poRepo;
    private readonly InventoryEntryService _inventoryEntryService;
    private readonly ITenantContext _tenant;

    public StockReceiveService(
        IProductRepository productRepo,
        ISupplierRepository supplierRepo,
        IPurchaseOrderRepository poRepo,
        InventoryEntryService inventoryEntryService,
        ITenantContext tenant)
    {
        _productRepo = productRepo;
        _supplierRepo = supplierRepo;
        _poRepo = poRepo;
        _inventoryEntryService = inventoryEntryService;
        _tenant = tenant;
    }

    // ─── Feature 1: Quick Receive ────────────────────────────────────────────

    public async Task<QuickReceiveResult> QuickReceiveAsync(QuickReceiveRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var companyId = _tenant.CompanyId.Value;
        var receivedDate = DateTime.UtcNow;
        var result = new QuickReceiveResult();

        // Validate items
        if (request.Items == null || request.Items.Count == 0)
            throw new InvalidOperationException("At least one item is required");

        using var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled);

        // Optionally create a PurchaseOrder record (supplier must exist)
        PurchaseOrder? po = null;
        if (request.SupplierId.HasValue && request.SupplierId.Value != Guid.Empty)
        {
            po = new PurchaseOrder(
                companyId: companyId,
                supplierId: request.SupplierId.Value,
                expectedDeliveryDate: receivedDate);

            po.AddNotes("Source:QuickReceive");

            foreach (var item in request.Items)
            {
                var product = await _productRepo.GetByIdAsync(item.ProductId)
                    ?? throw new KeyNotFoundException($"Product {item.ProductId} not found");

                po.AddItem(item.ProductId, product.Name, item.Quantity, item.CostPerUnit);

                var poItem = po.Items.Last();
                var isPerishable = product.ProductCategoryRef?.IsPerishable ?? false;
                poItem.SetProductDetails(product.Sku, item.Unit, isPerishable, item.ShelfLifeDays ?? product.ShelfLifeDays ?? 0);
            }

            // Force through Draft → Submitted → Approved → Received
            po.Submit();
            po.Approve();
            po.MarkReceived(receivedDate);

            await _poRepo.AddAsync(po);

            result.PurchaseOrderId = po.Id;
            result.PurchaseOrderNumber = po.OrderNumber;
        }

        // Create batches for each item
        foreach (var item in request.Items)
        {
            var product = await _productRepo.GetByIdAsync(item.ProductId)
                ?? throw new KeyNotFoundException($"Product {item.ProductId} not found");

                var created = await _inventoryEntryService.CreateInventoryEntryAsync(new InventoryEntryRequest(
                    ProductId: item.ProductId,
                    Quantity: item.Quantity,
                    CostPerUnit: item.CostPerUnit,
                    SellingPricePerUnit: item.SellingPricePerUnit,
                    ReceivedDate: receivedDate,
                    ExpiryDate: item.ExpiryDate,
                    ShelfLifeDays: item.ShelfLifeDays,
                    SupplierId: request.SupplierId,
                    LocationId: request.LocationId,
                    StorageLocation: item.StorageLocation,
                    Source: "QuickReceive",
                    PurchaseOrderId: po?.Id,
                    MergeWithSameDayBatch: item.MergeWithSameDayBatch));

                result.BatchIds.Add(created.BatchId);
        }

        scope.Complete();

        result.ItemsReceived = request.Items.Count;
        return result;
    }

    // ─── Feature 2: Direct Stock Add ─────────────────────────────────────────

    public async Task<DirectAddResult> DirectAddAsync(DirectAddRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var companyId = _tenant.CompanyId.Value;
        var receivedDate = DateTime.UtcNow;

        using var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled);

        var product = await _productRepo.GetByIdAsync(request.ProductId)
            ?? throw new KeyNotFoundException($"Product {request.ProductId} not found");

        var manualSupplier = await EnsureManualEntrySupplierAsync(companyId);

        var po = new PurchaseOrder(
            companyId: companyId,
            supplierId: manualSupplier.Id,
            expectedDeliveryDate: receivedDate);

        po.AddNotes("Source:DirectAdd;Hidden:true");
        po.AddItem(product.Id, product.Name, request.Quantity, request.CostPerUnit);

        var poItem = po.Items.Last();
        poItem.SetProductDetails(product.Sku, product.UnitOfMeasure.ToString(), product.IsPerishable, product.ShelfLifeDays ?? 0);

        po.Submit();
        po.Approve();
        po.MarkReceived(receivedDate);

        await _poRepo.AddAsync(po);

        var created = await _inventoryEntryService.CreateInventoryEntryAsync(new InventoryEntryRequest(
            ProductId: request.ProductId,
            Quantity: request.Quantity,
            CostPerUnit: request.CostPerUnit,
            SellingPricePerUnit: null,
            ReceivedDate: receivedDate,
            ExpiryDate: request.ExpiryDate,
            ShelfLifeDays: null,
            SupplierId: manualSupplier.Id,
            LocationId: request.LocationId,
            StorageLocation: request.StorageLocation,
            Source: "DirectAdd",
            PurchaseOrderId: po.Id,
            MergeWithSameDayBatch: request.MergeWithSameDayBatch));

        po.MarkInventoryProcessed();
        await _poRepo.UpdateAsync(po);

        scope.Complete();

        return new DirectAddResult
        {
            BatchId = created.BatchId,
            BatchNumber = created.BatchNumber,
        };
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private async Task<Supplier> EnsureManualEntrySupplierAsync(Guid companyId)
    {
        var activeSuppliers = await _supplierRepo.GetAllActiveAsync();
        var existing = activeSuppliers.FirstOrDefault(s =>
            string.Equals(s.Name, "Manual Entry", StringComparison.OrdinalIgnoreCase));

        if (existing != null)
            return existing;

        var supplier = new Supplier(
            companyId,
            "Manual Entry",
            contactPerson: null,
            email: null,
            phone: null,
            address: "System-generated supplier for direct stock add");

        supplier.AddNote("Auto-created for DirectAdd flow");
        await _supplierRepo.AddAsync(supplier);
        return supplier;
    }
}
