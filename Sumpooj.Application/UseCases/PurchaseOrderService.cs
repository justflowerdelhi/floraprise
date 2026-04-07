using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Application.Purchases;
using Sumpooj.Domain.Entities;
using System.Transactions;

namespace Sumpooj.Application.UseCases;

public class PurchaseOrderService
{
    private readonly IPurchaseOrderRepository _repo;
    private readonly ISupplierRepository _supplierRepo;
    private readonly IProductRepository _productRepo;
    private readonly IProductBatchRepository _batchRepo;
    private readonly InventoryEntryService _inventoryEntryService;
    private readonly ITenantContext _tenant;

    public PurchaseOrderService(
        IPurchaseOrderRepository repo,
        ISupplierRepository supplierRepo,
        IProductRepository productRepo,
        IProductBatchRepository batchRepo,
        InventoryEntryService inventoryEntryService,
        ITenantContext tenant)
    {
        _repo = repo;
        _supplierRepo = supplierRepo;
        _productRepo = productRepo;
        _batchRepo = batchRepo;
        _inventoryEntryService = inventoryEntryService;
        _tenant = tenant;
    }

    public async Task<PagedResult<PurchaseOrderListDto>> SearchAsync(PurchaseOrderSearchRequest request)
    {
        var (items, total) = await _repo.SearchAsync(
            request.Query,
            request.SupplierId,
            request.Status,
            request.FromDate,
            request.ToDate,
            request.Page,
            request.PageSize);

        var dtos = new List<PurchaseOrderListDto>();
        foreach (var po in items)
        {
            var supplier = await _supplierRepo.GetByIdAsync(po.SupplierId);
            dtos.Add(ToListDto(po, supplier?.Name ?? "Unknown"));
        }

        return new PagedResult<PurchaseOrderListDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<PurchaseOrderDto?> GetAsync(Guid id)
    {
        var po = await _repo.GetByIdWithItemsAsync(id);
        if (po == null) return null;

        var supplier = await _supplierRepo.GetByIdAsync(po.SupplierId);
        return await ToDto(po, supplier?.Name ?? "Unknown");
    }

    public async Task<Guid> CreateAsync(CreatePurchaseOrderRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var po = new PurchaseOrder(
            companyId: _tenant.CompanyId.Value,
            supplierId: request.SupplierId,
            expectedDeliveryDate: request.ExpectedDeliveryDate);

        if (!string.IsNullOrEmpty(request.Notes))
        {
            po.AddNotes(request.Notes);
        }

        // Add items — derive IsPerishable from product's category (source of truth)
        foreach (var item in request.Items)
        {
            po.AddItem(item.ProductId, item.ProductName, item.Quantity, item.CostPerUnit);

            // Get the last added item and set additional details
            var poItem = po.Items.Last();

            // Look up product to derive IsPerishable from its category
            var product = await _productRepo.GetByIdAsync(item.ProductId);
            var isPerishable = product?.ProductCategoryRef?.IsPerishable ?? false;

            poItem.SetProductDetails(item.Sku, item.Unit, isPerishable, item.ShelfLifeDays);
            if (!string.IsNullOrEmpty(item.BatchNumber) || item.ExpiryDate.HasValue)
            {
                poItem.SetBatchInfo(item.BatchNumber ?? "", item.ExpiryDate, item.StorageLocation);
            }
        }

        await _repo.AddAsync(po);
        return po.Id;
    }

    public async Task SubmitAsync(Guid id)
    {
        var po = await _repo.GetByIdWithItemsAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        po.Submit();
        await _repo.UpdateAsync(po);
    }

    public async Task ApproveAsync(Guid id)
    {
        var po = await _repo.GetByIdWithItemsAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        po.Approve();
        await _repo.UpdateAsync(po);
    }

    public async Task ReceiveAsync(Guid id, ReceivePurchaseOrderRequest request)
    {
        using var scope = new TransactionScope(TransactionScopeAsyncFlowOption.Enabled);

        var po = await _repo.GetByIdWithItemsAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        if (po.IsInventoryProcessed)
            return;

        if (po.Status == PurchaseOrderStatus.Received)
            throw new InvalidOperationException("Purchase order has already been received and cannot be received again");

        // Auto-advance through workflow so a single "Receive Stock" call works
        // regardless of the PO's current state.
        if (po.Status == PurchaseOrderStatus.Draft)
        {
            po.Submit();
            po.Approve();
        }
        else if (po.Status == PurchaseOrderStatus.Submitted)
        {
            po.Approve();
        }
        // If already Approved — proceed normally.

        // Mark as received
        po.MarkReceived(request.ActualDeliveryDate);

        // Update supplier stats
        var supplier = await _supplierRepo.GetByIdAsync(po.SupplierId);
        if (supplier != null)
        {
            supplier.RecordOrder(po.TotalAmount);
            await _supplierRepo.UpdateAsync(supplier);
        }

        // Create inventory entries for received items
        foreach (var item in po.Items)
        {
            var receiveItem = request.Items.FirstOrDefault(r => r.ProductId == item.ProductId);
            var receivedQty = receiveItem?.ReceivedQuantity ?? item.Quantity;

            if (receivedQty > 0)
            {
                item.UpdateReceivedQuantity(receivedQty);

                await _inventoryEntryService.CreateInventoryEntryAsync(new InventoryEntryRequest(
                    ProductId: item.ProductId,
                    Quantity: receivedQty,
                    CostPerUnit: item.UnitPrice,
                    SellingPricePerUnit: null,
                    ReceivedDate: request.ActualDeliveryDate,
                    ExpiryDate: receiveItem?.ExpiryDate,
                    ShelfLifeDays: item.ShelfLifeDays > 0 ? item.ShelfLifeDays : null,
                    SupplierId: po.SupplierId,
                    LocationId: null,
                    StorageLocation: receiveItem?.StorageLocation ?? item.StorageLocation,
                    Source: "POReceive",
                    PurchaseOrderId: po.Id,
                    MergeWithSameDayBatch: false));
            }
        }

        po.MarkInventoryProcessed();
        await _repo.UpdateAsync(po);
        scope.Complete();
    }

    public async Task CancelAsync(Guid id)
    {
        var po = await _repo.GetByIdAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        po.Cancel();
        await _repo.UpdateAsync(po);
    }

    private static PurchaseOrderListDto ToListDto(PurchaseOrder po, string supplierName) => new()
    {
        Id = po.Id,
        OrderNumber = po.OrderNumber,
        SupplierName = supplierName,
        OrderDate = po.OrderDate,
        ExpectedDeliveryDate = po.ExpectedDeliveryDate,
        Status = po.Status.ToString(),
        TotalAmount = po.TotalAmount,
        ItemCount = po.Items.Count
    };

    private async Task<PurchaseOrderDto> ToDto(PurchaseOrder po, string supplierName)
    {
        var dto = new PurchaseOrderDto
        {
            Id = po.Id,
            OrderNumber = po.OrderNumber,
            SupplierId = po.SupplierId,
            SupplierName = supplierName,
            OrderDate = po.OrderDate,
            ExpectedDeliveryDate = po.ExpectedDeliveryDate,
            ActualDeliveryDate = po.ActualDeliveryDate,
            Status = po.Status.ToString(),
            IsActive = po.IsActive,
            TotalAmount = po.TotalAmount,
            Notes = po.Notes,
            CreatedAtUtc = po.CreatedAtUtc
        };

        foreach (var item in po.Items)
        {
            dto.Items.Add(new PurchaseOrderItemDto
            {
                Id = item.Id,
                ProductId = item.ProductId,
                ProductName = item.ProductName,
                Sku = item.Sku,
                Unit = item.Unit,
                Quantity = item.Quantity,
                UnitPrice = item.UnitPrice,
                TotalPrice = item.TotalPrice,
                ReceivedQuantity = item.ReceivedQuantity,
                IsPerishable = item.IsPerishable,
                ShelfLifeDays = item.ShelfLifeDays,
                BatchNumber = item.BatchNumber,
                ExpiryDate = item.ExpiryDate,
                StorageLocation = item.StorageLocation
            });
        }

        dto.SubTotal = dto.Items.Sum(i => i.TotalPrice);
        return dto;
    }
}
