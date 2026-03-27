using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Application.Inventory;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class InventoryService
{
    private readonly IProductBatchRepository _batchRepo;
    private readonly IInventoryAdjustmentRepository _adjustmentRepo;
    private readonly IProductRepository _productRepo;
    private readonly ITenantContext _tenant;
    private readonly IInventoryLedgerRepository _ledgerRepo;

    public InventoryService(
        IProductBatchRepository batchRepo,
        IInventoryAdjustmentRepository adjustmentRepo,
        IProductRepository productRepo,
        ITenantContext tenant,
        IInventoryLedgerRepository ledgerRepo)
    {
        _batchRepo = batchRepo;
        _adjustmentRepo = adjustmentRepo;
        _productRepo = productRepo;
        _tenant = tenant;
        _ledgerRepo = ledgerRepo;
    }

    #region Batches

    public async Task<PagedResult<ProductBatchDto>> SearchBatchesAsync(BatchSearchRequest request)
    {
        var (items, total) = await _batchRepo.SearchAsync(
            request.Query,
            request.ProductId,
            request.SupplierId,
            request.LocationId,
            request.IsActive,
            request.ExpiringOnly,
            request.ExpiringWithinDays,
            request.Page,
            request.PageSize);

        var dtos = new List<ProductBatchDto>();
        foreach (var batch in items)
        {
            var product = await _productRepo.GetByIdAsync(batch.ProductId);
            dtos.Add(ToBatchDto(batch, product?.Name ?? "Unknown", product?.ProductType.ToString()));
        }

        return new PagedResult<ProductBatchDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<ProductBatchDto?> GetBatchAsync(Guid id)
    {
        var batch = await _batchRepo.GetByIdAsync(id);
        if (batch == null) return null;

        var product = await _productRepo.GetByIdAsync(batch.ProductId);
        return ToBatchDto(batch, product?.Name ?? "Unknown", product?.ProductType.ToString());
    }

    public async Task<List<ProductBatchDto>> GetBatchesByProductAsync(Guid productId)
    {
        var batches = await _batchRepo.GetBatchesByProductIdAsync(productId);
        var product = await _productRepo.GetByIdAsync(productId);
        
        return batches.Select(b => ToBatchDto(b, product?.Name ?? "Unknown", product?.ProductType.ToString())).ToList();
    }

    public async Task<Guid> CreateBatchAsync(CreateBatchRequest request)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var batchNumber = string.IsNullOrEmpty(request.BatchNumber)
            ? await _batchRepo.GenerateBatchNumberAsync(request.ProductId)
            : request.BatchNumber;

        var batch = new ProductBatch(
            companyId: _tenant.CompanyId.Value,
            productId: request.ProductId,
            batchNumber: batchNumber,
            quantityReceived: request.Quantity,
            costPerUnit: request.CostPerUnit,
            receivedDate: request.ReceivedDate,
            expiryDate: request.ExpiryDate,
            supplierId: request.SupplierId,
            locationId: request.LocationId,
            storageLocation: request.StorageLocation);

        if (request.SellingPricePerUnit.HasValue)
        {
            batch.SetSellingPrice(request.SellingPricePerUnit.Value);
        }

        // Update product stock quantity
        var product = await _productRepo.GetByIdAsync(request.ProductId);
        if (product != null && product.TrackInventory)
        {
            product.AdjustStock(request.Quantity);
            await _productRepo.UpdateAsync(product);
        }

        await _batchRepo.AddAsync(batch);
        return batch.Id;
    }

    public async Task<List<ExpiryAlertDto>> GetExpiryAlertsAsync(int criticalDays = 2, int warningDays = 5, int upcomingDays = 14)
    {
        var alerts = new List<ExpiryAlertDto>();

        var expiringBatches = await _batchRepo.GetExpiringBatchesAsync(upcomingDays);
        
        foreach (var batch in expiringBatches)
        {
            var product = await _productRepo.GetByIdAsync(batch.ProductId);
            if (product == null || !batch.ExpiryDate.HasValue) continue;

            var daysUntilExpiry = (batch.ExpiryDate.Value.Date - DateTime.UtcNow.Date).Days;
            var alertLevel = daysUntilExpiry <= criticalDays ? "Critical"
                : daysUntilExpiry <= warningDays ? "Warning"
                : "Upcoming";

            alerts.Add(new ExpiryAlertDto
            {
                BatchId = batch.Id,
                ProductId = batch.ProductId,
                ProductName = product.Name,
                BatchNumber = batch.BatchNumber,
                QuantityRemaining = batch.QuantityRemaining,
                ExpiryDate = batch.ExpiryDate.Value,
                DaysUntilExpiry = daysUntilExpiry,
                CostPerUnit = batch.CostPerUnit,
                TotalValue = batch.QuantityRemaining * batch.CostPerUnit,
                StorageLocation = batch.StorageLocation,
                AlertLevel = alertLevel
            });
        }

        return alerts.OrderBy(a => a.DaysUntilExpiry).ToList();
    }

    public async Task<InventorySummaryDto> GetInventorySummaryAsync()
    {
        var (batches, _) = await _batchRepo.SearchAsync(null, null, null, null, true, null, null, 1, int.MaxValue);
        var lowStockProducts = await _productRepo.GetLowStockProductsAsync();
        var expiringBatches = await _batchRepo.GetExpiringBatchesAsync(7);
        var expiredBatches = await _batchRepo.GetExpiredBatchesAsync();

        return new InventorySummaryDto
        {
            TotalProducts = batches.Select(b => b.ProductId).Distinct().Count(),
            TotalBatches = batches.Count,
            LowStockProducts = lowStockProducts.Count,
            ExpiringBatches = expiringBatches.Count,
            ExpiredBatches = expiredBatches.Count,
            TotalInventoryValue = batches.Sum(b => b.QuantityRemaining * b.CostPerUnit),
            TotalRetailValue = batches.Sum(b => b.QuantityRemaining * b.SellingPricePerUnit)
        };
    }

    public async Task<List<InventoryReconciliationDto>> GetStockReconciliationAsync(bool mismatchesOnly = true)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var companyId = _tenant.CompanyId.Value;
        var products = await _productRepo.GetAllAsync(companyId);
        var (batches, _) = await _batchRepo.SearchAsync(null, null, null, null, true, null, null, 1, int.MaxValue);

        var batchByProduct = batches
            .GroupBy(b => b.ProductId)
            .ToDictionary(g => g.Key, g => new
            {
                Quantity = g.Sum(x => x.QuantityRemaining),
                Count = g.Count()
            });

        var rows = new List<InventoryReconciliationDto>();

        foreach (var product in products.Where(p => p.IsActive && p.TrackInventory))
        {
            var hasBatch = batchByProduct.TryGetValue(product.Id, out var batchInfo);
            var batchQty = hasBatch ? batchInfo!.Quantity : 0;
            var batchCount = hasBatch ? batchInfo!.Count : 0;
            var diff = product.StockQuantity - batchQty;

            if (mismatchesOnly && diff == 0)
                continue;

            rows.Add(new InventoryReconciliationDto
            {
                ProductId = product.Id,
                ProductName = product.Name,
                TrackInventory = product.TrackInventory,
                TrackBatch = product.TrackBatch,
                ProductStockQuantity = product.StockQuantity,
                BatchStockQuantity = batchQty,
                Difference = diff,
                BatchCount = batchCount,
            });
        }

        return rows
            .OrderByDescending(r => Math.Abs(r.Difference))
            .ThenBy(r => r.ProductName)
            .ToList();
    }

    public async Task<ReconciliationApplyResultDto> ApplyReconciliationFixAsync(ReconciliationApplyRequest request, Guid userId)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var product = await _productRepo.GetByIdAsync(request.ProductId)
            ?? throw new KeyNotFoundException("Product not found");

        if (!product.TrackInventory)
            throw new InvalidOperationException("Product is not inventory-tracked");

        var batches = await _batchRepo.GetBatchesByProductIdAsync(product.Id);
        var batchStock = batches.Sum(b => b.QuantityRemaining);
        var beforeDiff = product.StockQuantity - batchStock;

        if (request.ExpectedDifference.HasValue && request.ExpectedDifference.Value != beforeDiff)
            throw new InvalidOperationException(
                $"Reconciliation changed since page load. Expected {request.ExpectedDifference.Value}, current {beforeDiff}.");

        if (beforeDiff == 0)
        {
            return new ReconciliationApplyResultDto
            {
                ProductId = product.Id,
                ProductName = product.Name,
                BeforeDifference = beforeDiff,
                AppliedQuantity = 0,
                AfterDifference = 0,
                AppliedAdjustmentType = "NONE"
            };
        }

        // Policy: align Batch stock to Product stock so inventory batch dashboard reflects corrected quantity.
        // beforeDiff = Product - Batch
        // beforeDiff > 0 => batch is short, add to batch
        // beforeDiff < 0 => batch is high, deduct from batch
        var quantity = Math.Abs(beforeDiff);
        var reason = string.IsNullOrWhiteSpace(request.Reason)
            ? "Stock reconciliation correction"
            : request.Reason.Trim();

        var noteParts = new List<string>
        {
            $"Reconciliation fix applied. BeforeDiff={beforeDiff}, ProductStock={product.StockQuantity}, BatchStock={batchStock}."
        };

        if (!string.IsNullOrWhiteSpace(request.Notes))
            noteParts.Add(request.Notes.Trim());

        if (beforeDiff > 0)
        {
            // Batch stock lower than product stock -> add to latest batch (or create one).
            var targetBatch = batches
                .OrderByDescending(b => b.ReceivedDate)
                .FirstOrDefault();

            if (targetBatch == null)
            {
                var batchNumber = await _batchRepo.GenerateBatchNumberAsync(product.Id);
                targetBatch = new ProductBatch(
                    companyId: _tenant.CompanyId.Value,
                    productId: product.Id,
                    batchNumber: batchNumber,
                    quantityReceived: quantity,
                    costPerUnit: product.CostPrice,
                    receivedDate: DateTime.UtcNow,
                    expiryDate: null,
                    supplierId: null,
                    locationId: null,
                    storageLocation: "Reconciliation");
                await _batchRepo.AddAsync(targetBatch);
            }
            else
            {
                targetBatch.AddQuantity(quantity);
                await _batchRepo.UpdateAsync(targetBatch);
            }

            var addAdjustment = new InventoryAdjustment(
                companyId: _tenant.CompanyId.Value,
                productId: product.Id,
                batchId: targetBatch.Id,
                adjustmentType: AdjustmentType.Correction,
                quantity: quantity,
                costPerUnit: targetBatch.CostPerUnit,
                reason: reason,
                adjustedByUserId: userId);
            addAdjustment.AddNotes(string.Join(" ", noteParts));
            await _adjustmentRepo.AddAsync(addAdjustment);
        }
        else
        {
            // Batch stock higher than product stock -> deduct from batches FIFO.
            var remaining = quantity;
            foreach (var batch in batches.OrderBy(b => b.ExpiryDate ?? DateTime.MaxValue).ThenBy(b => b.ReceivedDate))
            {
                if (remaining <= 0) break;

                var deduct = Math.Min(batch.QuantityRemaining, remaining);
                if (deduct <= 0) continue;

                batch.DeductQuantity(deduct);
                await _batchRepo.UpdateAsync(batch);

                var deductAdjustment = new InventoryAdjustment(
                    companyId: _tenant.CompanyId.Value,
                    productId: product.Id,
                    batchId: batch.Id,
                    adjustmentType: AdjustmentType.Correction,
                    quantity: deduct,
                    costPerUnit: batch.CostPerUnit,
                    reason: reason,
                    adjustedByUserId: userId);
                deductAdjustment.AddNotes(string.Join(" ", noteParts));
                await _adjustmentRepo.AddAsync(deductAdjustment);

                remaining -= deduct;
            }

            if (remaining > 0)
                throw new InvalidOperationException($"Unable to deduct enough batch stock for product {product.Name}");
        }

        var refreshedBatches = await _batchRepo.GetBatchesByProductIdAsync(product.Id);
        var afterBatchStock = refreshedBatches.Sum(b => b.QuantityRemaining);
        var afterDiff = product.StockQuantity - afterBatchStock;

        return new ReconciliationApplyResultDto
        {
            ProductId = product.Id,
            ProductName = product.Name,
            BeforeDifference = beforeDiff,
            AppliedQuantity = quantity,
            AfterDifference = afterDiff,
            AppliedAdjustmentType = "CORRECTION"
        };
    }

    public async Task<List<InventoryBatchProjection>> GetBatchSummaryAsync()
    {
        var (batches, _) = await _batchRepo.SearchAsync(null, null, null, null, true, null, null, 1, int.MaxValue);
        var projections = new List<InventoryBatchProjection>();

        foreach (var batch in batches)
        {
            var product = await _productRepo.GetByIdAsync(batch.ProductId);
            if (product == null) continue;

            projections.Add(new InventoryBatchProjection
            {
                BatchId = batch.Id,
                ProductId = batch.ProductId,
                ProductName = product.Name,
                BatchNumber = batch.BatchNumber,
                StemsInStock = batch.StemsInStock,
                TotalUnits = batch.GetTotalUnits(product),
                UsedUnits = batch.UsedUnits,
                DamagedUnits = batch.DamagedUnits,
                ReservedUnits = batch.ReservedUnits,
                AvailableUnits = batch.GetAvailableUnits(product),
                ConsumedStems = batch.GetConsumedStems(product),
                RemainingStems = batch.GetRemainingStems(product),
                PartialUsedUnits = batch.GetPartialUsedUnits(product)
            });
        }

        return projections;
    }

    #endregion

    #region Adjustments

    public async Task<PagedResult<InventoryAdjustmentDto>> SearchAdjustmentsAsync(AdjustmentSearchRequest request)
    {
        var (items, total) = await _adjustmentRepo.SearchAsync(
            request.ProductId,
            request.BatchId,
            request.AdjustmentType,
            request.FromDate,
            request.ToDate,
            request.Page,
            request.PageSize);

        var dtos = new List<InventoryAdjustmentDto>();
        foreach (var adj in items)
        {
            var product = await _productRepo.GetByIdAsync(adj.ProductId);
            var batch = adj.BatchId.HasValue ? await _batchRepo.GetByIdAsync(adj.BatchId.Value) : null;
            dtos.Add(ToAdjustmentDto(adj, product?.Name ?? "Unknown", batch?.BatchNumber));
        }

        return new PagedResult<InventoryAdjustmentDto>
        {
            Items = dtos,
            TotalCount = total,
            Page = request.Page,
            PageSize = request.PageSize
        };
    }

    public async Task<List<InventoryAdjustmentDto>> GetRecentAdjustmentsAsync(int count = 10)
    {
        var adjustments = await _adjustmentRepo.GetRecentAdjustmentsAsync(count);
        var dtos = new List<InventoryAdjustmentDto>();

        foreach (var adj in adjustments)
        {
            var product = await _productRepo.GetByIdAsync(adj.ProductId);
            var batch = adj.BatchId.HasValue ? await _batchRepo.GetByIdAsync(adj.BatchId.Value) : null;
            dtos.Add(ToAdjustmentDto(adj, product?.Name ?? "Unknown", batch?.BatchNumber));
        }

        return dtos;
    }

    public async Task<Guid> CreateAdjustmentAsync(CreateAdjustmentRequest request, Guid userId)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var adjustmentType = ParseAdjustmentType(request.AdjustmentType);

        var adjustment = new InventoryAdjustment(
            companyId: _tenant.CompanyId.Value,
            productId: request.ProductId,
            batchId: request.BatchId,
            adjustmentType: adjustmentType,
            quantity: request.Quantity,
            costPerUnit: request.CostPerUnit,
            reason: request.Reason,
            adjustedByUserId: userId);

        if (!string.IsNullOrEmpty(request.Notes))
        {
            adjustment.AddNotes(request.Notes);
        }

        // Update batch quantity if batch is specified
        if (request.BatchId.HasValue)
        {
            var batch = await _batchRepo.GetByIdAsync(request.BatchId.Value);
            if (batch != null)
            {
                // Negative adjustments (like spoiled, damaged) reduce quantity
                if (IsNegativeAdjustment(adjustmentType))
                {
                    batch.DeductQuantity(request.Quantity);
                }
                else
                {
                    batch.AddQuantity(request.Quantity);
                }
                await _batchRepo.UpdateAsync(batch);
            }
        }

        // Update product stock quantity
        var product = await _productRepo.GetByIdAsync(request.ProductId);
        if (product != null && product.TrackInventory)
        {
            var stockChange = IsNegativeAdjustment(adjustmentType) ? -request.Quantity : request.Quantity;
            product.AdjustStock(stockChange);
            await _productRepo.UpdateAsync(product);
        }

        await _adjustmentRepo.AddAsync(adjustment);
        return adjustment.Id;
    }

    public async Task<List<DailyInventoryReportDto>> GetDailyInventoryReportAsync(DateTime date)
    {
        if (_tenant.CompanyId == null)
            throw new InvalidOperationException("Company context required");

        var companyId = _tenant.CompanyId.Value;

        var start = date.Date;
        var end = start.AddDays(1);

        var products = await _productRepo.GetAllAsync(companyId);

        var result = new List<DailyInventoryReportDto>();

        foreach (var product in products)
        {
            var ledger = await _ledgerRepo.GetByProductAsync(companyId, product.Id);

            // Opening Stock (all ledger entries before this day)
            var opening = ledger
                .Where(x => x.CreatedAtUtc < start)
                .Sum(x => x.QuantityChange);

            // Today's entries
            var today = ledger
                .Where(x => x.CreatedAtUtc >= start && x.CreatedAtUtc < end)
                .ToList();

            // Purchased (positive entries of type PURCHASE)
            var purchased = today
                .Where(x => x.QuantityChange > 0 && x.ReferenceType == "PURCHASE")
                .Sum(x => x.QuantityChange);

            // Sold (negative entries of type SALE)
            var sold = today
                .Where(x => x.ReferenceType == "SALE")
                .Sum(x => Math.Abs(x.QuantityChange));

            // Adjustments (damage, spoil, etc.)
            var adjustments = today
                .Where(x => x.ReferenceType == "ADJUSTMENT")
                .Sum(x => x.QuantityChange);

            // Closing
            var closing = opening + purchased + adjustments - sold;

            result.Add(new DailyInventoryReportDto
            {
                ProductId = product.Id,
                ProductName = product.Name,
                OpeningStock = opening,
                Purchased = purchased,
                Sold = sold,
                Adjustments = adjustments,
                ClosingStock = closing
            });
        }

        return result;
    }

    #endregion

    #region Private Methods

    private static ProductBatchDto ToBatchDto(ProductBatch b, string productName, string? productType)
    {
        var daysUntilExpiry = b.ExpiryDate.HasValue
            ? (int?)(b.ExpiryDate.Value.Date - DateTime.UtcNow.Date).Days
            : null;

        return new ProductBatchDto
        {
            Id = b.Id,
            ProductId = b.ProductId,
            ProductName = productName,
            ProductType = productType,
            BatchNumber = b.BatchNumber,
            QuantityReceived = b.QuantityReceived,
            QuantityRemaining = b.QuantityRemaining,
            CostPerUnit = b.CostPerUnit,
            SellingPricePerUnit = b.SellingPricePerUnit,
            ReceivedDate = b.ReceivedDate,
            ExpiryDate = b.ExpiryDate,
            DaysUntilExpiry = daysUntilExpiry,
            IsExpired = b.IsExpired(),
            IsExpiringSoon = b.IsExpiringSoon(7),
            SupplierId = b.SupplierId,
            LocationId = b.LocationId,
            StorageLocation = b.StorageLocation,
            IsActive = b.IsActive,
            CreatedAtUtc = b.CreatedAtUtc
        };
    }

    private static InventoryAdjustmentDto ToAdjustmentDto(InventoryAdjustment a, string productName, string? batchNumber) => new()
    {
        Id = a.Id,
        ProductId = a.ProductId,
        ProductName = productName,
        BatchId = a.BatchId,
        BatchNumber = batchNumber,
        AdjustmentType = a.AdjustmentType.ToString(),
        Quantity = a.Quantity,
        CostPerUnit = a.CostPerUnit,
        TotalValue = a.TotalValue,
        Reason = a.Reason,
        AdjustmentDate = a.AdjustmentDate,
        Notes = a.Notes,
        CreatedAtUtc = a.CreatedAtUtc
    };

    private static AdjustmentType ParseAdjustmentType(string value)
    {
        var normalized = string.Concat(value.Split('_').Select(s =>
            char.ToUpper(s[0]) + s.Substring(1).ToLower()));

        if (Enum.TryParse<AdjustmentType>(normalized, true, out var result))
            return result;

        if (Enum.TryParse<AdjustmentType>(value, true, out result))
            return result;

        return AdjustmentType.Other;
    }

    private static bool IsNegativeAdjustment(AdjustmentType type)
    {
        return type switch
        {
            AdjustmentType.Damaged => true,
            AdjustmentType.Spoiled => true,
            AdjustmentType.Expired => true,
            AdjustmentType.UsedForEvent => true,
            AdjustmentType.UsedForSample => true,
            AdjustmentType.Lost => true,
            AdjustmentType.Theft => true,
            AdjustmentType.TransferOut => true,
            _ => false
        };
    }

    #endregion
}
