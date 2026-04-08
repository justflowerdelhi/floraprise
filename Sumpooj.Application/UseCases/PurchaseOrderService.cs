using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Application.Purchases;
using Sumpooj.Application.Services;
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
    private readonly PurchaseOrderPdfService _pdfService;

    public PurchaseOrderService(
        IPurchaseOrderRepository repo,
        ISupplierRepository supplierRepo,
        IProductRepository productRepo,
        IProductBatchRepository batchRepo,
        InventoryEntryService inventoryEntryService,
        ITenantContext tenant,
        PurchaseOrderPdfService pdfService)
    {
        _repo = repo;
        _supplierRepo = supplierRepo;
        _productRepo = productRepo;
        _batchRepo = batchRepo;
        _inventoryEntryService = inventoryEntryService;
        _tenant = tenant;
        _pdfService = pdfService;
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
            var expectedCost = item.ResolveExpectedCostPerUnit();
            po.AddItem(item.ProductId, item.ProductName, item.Quantity, expectedCost);

            // Get the last added item and set additional details
            var poItem = po.Items.Last();

            // Look up product to derive IsPerishable from its category
            var product = await _productRepo.GetByIdAsync(item.ProductId);
            var isPerishable = product?.ProductCategoryRef?.IsPerishable ?? false;
            var shelfLifeDays = item.ShelfLifeDays;
            if (product?.ShelfLifeDays is int derivedShelfLife && derivedShelfLife > 0)
            {
                shelfLifeDays = derivedShelfLife;
            }

            poItem.SetProductDetails(item.Sku, item.Unit, isPerishable, shelfLifeDays);
        }

        await _repo.AddAsync(po);
        return po.Id;
    }

    public async Task<PurchaseOrderSubmitResult> SubmitAsync(Guid id)
    {
        var po = await _repo.GetByIdWithItemsAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        po.Submit();

        var pdfBytes = _pdfService.GeneratePdf(po);
        var fileName = $"PO-{po.OrderNumber}.pdf";
        var filesDir = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "files");
        Directory.CreateDirectory(filesDir);

        var filePath = Path.Combine(filesDir, fileName);
        await File.WriteAllBytesAsync(filePath, pdfBytes);

        await _repo.UpdateAsync(po);

        return new PurchaseOrderSubmitResult
        {
            Success = true,
            PdfUrl = "/files/" + fileName,
        };
    }

    public async Task<(byte[] Content, string FileName)> GeneratePdfAsync(Guid id)
    {
        var po = await _repo.GetByIdWithItemsAsync(id)
            ?? throw new KeyNotFoundException("Purchase order not found");

        var pdfBytes = _pdfService.GeneratePdf(po);
        return (pdfBytes, $"{po.OrderNumber}.pdf");
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

        if (po.Status == PurchaseOrderStatus.Draft)
            throw new InvalidOperationException("Please submit the purchase order before receiving stock.");

        if (po.Status != PurchaseOrderStatus.Submitted && po.Status != PurchaseOrderStatus.Approved)
            throw new InvalidOperationException("Only submitted or approved purchase orders can be received.");

        // Mark as received
        po.MarkReceived(request.ActualDeliveryDate);
        if (!string.IsNullOrWhiteSpace(request.InvoiceNumber))
        {
            po.SetInvoiceNumber(request.InvoiceNumber);
        }

        // Create inventory entries for received items
        foreach (var item in po.Items)
        {
            var receiveItem = request.Items.FirstOrDefault(r => r.ProductId == item.ProductId);
            if (receiveItem == null)
                throw new InvalidOperationException($"Receive details are required for product {item.ProductName}.");

            var receivedQty = receiveItem.ReceivedQuantity;

            if (receivedQty <= 0)
                throw new InvalidOperationException("Received quantity must be greater than 0");

            if (string.IsNullOrWhiteSpace(receiveItem.BatchNumber))
                throw new InvalidOperationException("Batch number is required");

            if (!receiveItem.ActualCostPerUnit.HasValue || receiveItem.ActualCostPerUnit.Value <= 0)
                throw new InvalidOperationException("Actual cost must be greater than 0");

            if (item.IsPerishable && !receiveItem.ExpiryDate.HasValue)
                throw new InvalidOperationException("Expiry date is required for perishable items");

            var expectedPrice = item.ExpectedPrice;
            var actualPrice = receiveItem.ActualCostPerUnit.Value;
            item.SetMismatchFlags(
                receivedQty != item.Quantity,
                Math.Abs(actualPrice - expectedPrice) > 0.0001m);

            if (receivedQty > 0)
            {
                item.ApplyReceive(receivedQty, actualPrice);

                await _inventoryEntryService.CreateInventoryEntryAsync(new InventoryEntryRequest(
                    ProductId: item.ProductId,
                    Quantity: receivedQty,
                    CostPerUnit: actualPrice,
                    SellingPricePerUnit: null,
                    ReceivedDate: request.ActualDeliveryDate,
                    ExpiryDate: receiveItem.ExpiryDate,
                    ShelfLifeDays: item.ShelfLifeDays > 0 ? item.ShelfLifeDays : null,
                    SupplierId: po.SupplierId,
                    LocationId: null,
                    StorageLocation: receiveItem.StorageLocation,
                    Source: "POReceive",
                    PurchaseOrderId: po.Id,
                    MergeWithSameDayBatch: false));
            }
        }

        // Recompute PO total based on received qty * actual price lines.
        po.RecalculateTotalsFromItems();

        // Update supplier stats with actual received total.
        var supplier = await _supplierRepo.GetByIdAsync(po.SupplierId);
        if (supplier != null)
        {
            supplier.RecordOrder(po.TotalAmount);
            await _supplierRepo.UpdateAsync(supplier);
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

    private static PurchaseOrderListDto ToListDto(PurchaseOrder po, string supplierName)
    {
        var computedTotal = po.Items.Count > 0 ? po.Items.Sum(i => i.TotalPrice) : po.TotalAmount;

        return new PurchaseOrderListDto
        {
            Id = po.Id,
            OrderNumber = po.OrderNumber,
            SupplierName = supplierName,
            OrderDate = po.OrderDate,
            ExpectedDeliveryDate = po.ExpectedDeliveryDate,
            Status = po.Status.ToString(),
            TotalAmount = computedTotal,
            ItemCount = po.Items.Count
        };
    }

    private async Task<PurchaseOrderDto> ToDto(PurchaseOrder po, string supplierName)
    {
        var invoiceNumber = po.InvoiceNumber;
        if (string.IsNullOrWhiteSpace(invoiceNumber) && !string.IsNullOrWhiteSpace(po.Notes))
        {
            invoiceNumber = ExtractInvoiceNumber(po.Notes);
        }

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
            InvoiceNumber = invoiceNumber,
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
                ExpectedPrice = item.ExpectedPrice,
                UnitPrice = item.ExpectedPrice,
                ActualPrice = item.ActualUnitPrice,
                TotalPrice = item.TotalPrice,
                ActualTotalPrice = item.TotalPrice,
                ReceivedQuantity = item.ReceivedQuantity,
                IsPerishable = item.IsPerishable,
                ShelfLifeDays = item.ShelfLifeDays,
                IsQuantityMismatch = item.IsQuantityMismatch ?? false,
                IsPriceMismatch = item.IsPriceMismatch ?? false
            });
        }

        dto.SubTotal = dto.Items.Sum(i => i.TotalPrice);
        dto.TotalAmount = dto.SubTotal;
        return dto;
    }

    private static string? ExtractInvoiceNumber(string? notes)
    {
        if (string.IsNullOrWhiteSpace(notes)) return null;

        const string marker = "[InvoiceNumber]";
        var line = notes
            .Split('\n', StringSplitOptions.RemoveEmptyEntries)
            .Select(x => x.Trim())
            .FirstOrDefault(x => x.StartsWith(marker, StringComparison.OrdinalIgnoreCase));

        if (line == null) return null;
        return line.Substring(marker.Length).Trim();
    }
}
