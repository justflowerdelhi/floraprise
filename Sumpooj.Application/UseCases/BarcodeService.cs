using Sumpooj.Application.Barcodes;
using Sumpooj.Application.Common;
using Sumpooj.Application.Interfaces;
using Sumpooj.Domain.Entities;

namespace Sumpooj.Application.UseCases;

public class BarcodeService
{
    private const int MaxGenerationAttempts = 50;

    private readonly IProductRepository _productRepo;
    private readonly IBarcodeRepository _barcodeRepo;

    public BarcodeService(IProductRepository productRepo, IBarcodeRepository barcodeRepo)
    {
        _productRepo = productRepo;
        _barcodeRepo = barcodeRepo;
    }

    public static string FormatInternalBarcode(int sequence) => $"FL{sequence:D8}";

    /// <summary>
    /// Computes a candidate Internal barcode value that is not currently in use
    /// for the company. The database unique constraint on (CompanyId, Value) is
    /// the final safety net against a race between two concurrent creations.
    /// </summary>
    public async Task<string> GenerateUniqueInternalValueAsync(Guid companyId)
    {
        var startingSequence = await _barcodeRepo.CountByCompanyAndTypeAsync(companyId, BarcodeType.Internal) + 1;
        for (var attempt = 0; attempt < MaxGenerationAttempts; attempt++)
        {
            var candidate = FormatInternalBarcode(startingSequence + attempt);
            if (!await _barcodeRepo.ValueExistsAsync(companyId, candidate))
            {
                return candidate;
            }
        }

        throw new InvalidOperationException("Unable to generate a unique internal barcode after multiple attempts.");
    }

    /// <summary>
    /// Generates (and persists) an Internal barcode for an existing product.
    /// If one already exists, returns it unchanged rather than creating a second.
    /// </summary>
    public async Task<GenerateBarcodeResponse> GenerateAsync(Guid companyId, GenerateBarcodeRequest request)
    {
        if (!string.Equals(request.SourceType, "Product", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("Only Product barcode generation is supported.");

        var product = await _productRepo.GetByIdAsync(companyId, request.ReferenceId)
            ?? throw new InvalidOperationException("Product not found for this company.");

        var existing = (await _barcodeRepo.GetByProductIdAsync(product.Id))
            .FirstOrDefault(b => b.Type == BarcodeType.Internal);
        if (existing != null)
        {
            return ToResponse(existing);
        }

        for (var attempt = 0; attempt < MaxGenerationAttempts; attempt++)
        {
            var value = await GenerateUniqueInternalValueAsync(companyId);
            var barcode = new Barcode(companyId, product.Id, BarcodeType.Internal, value);
            try
            {
                await _barcodeRepo.AddAsync(barcode);
                return ToResponse(barcode);
            }
            catch (ConcurrencyConflictException)
            {
                // Another request took this value between our check and insert; retry.
            }
        }

        throw new InvalidOperationException("Unable to generate a unique internal barcode after multiple attempts.");
    }

    public async Task<ValidateBarcodeResponse> ValidateAsync(Guid companyId, ValidateBarcodeRequest request)
    {
        var value = request.Barcode?.Trim() ?? string.Empty;
        var existing = value.Length == 0 ? null : await _barcodeRepo.GetByCompanyAndValueAsync(companyId, value);
        Product? existingProduct = existing == null
            ? null
            : await _productRepo.GetByIdAsync(companyId, existing.ProductId);

        return new ValidateBarcodeResponse
        {
            IsValid = value.Length > 0,
            IsDuplicate = existing != null,
            Format = request.Format ?? "CODE128",
            ExistingProduct = existingProduct != null
                ? new { id = existingProduct.Id, name = existingProduct.Name, sku = existingProduct.Sku }
                : null
        };
    }

    public async Task<SearchBarcodeResponse> SearchAsync(Guid companyId, SearchBarcodeRequest request)
    {
        var searchedTypes = new List<string> { "MANUFACTURER", "INTERNAL" };
        var value = request.Barcode?.Trim() ?? string.Empty;

        var match = value.Length == 0 ? null : await _barcodeRepo.GetByCompanyAndValueAsync(companyId, value);
        if (match == null)
        {
            return new SearchBarcodeResponse { Found = false, SearchedTypes = searchedTypes };
        }

        var product = await _productRepo.GetByIdAsync(companyId, match.ProductId);
        if (product == null || (!request.IncludeOutOfStock && product.StockQuantity <= 0))
        {
            return new SearchBarcodeResponse { Found = false, SearchedTypes = searchedTypes };
        }

        var allBarcodes = await _barcodeRepo.GetByProductIdAsync(product.Id);
        return new SearchBarcodeResponse
        {
            Found = true,
            Product = new ProductBarcodeInfo
            {
                ProductId = product.Id,
                ProductName = product.Name,
                Sku = product.Sku,
                Unit = product.UnitOfMeasure.ToString(),
                UnitPrice = product.RetailPrice,
                StockLevel = product.StockQuantity,
                ExternalBarcode = allBarcodes.FirstOrDefault(b => b.Type == BarcodeType.Manufacturer)?.Value,
                InternalBarcode = allBarcodes.FirstOrDefault(b => b.Type == BarcodeType.Internal)?.Value,
                FoundByType = match.Type == BarcodeType.Manufacturer ? "MANUFACTURER" : "INTERNAL"
            },
            SearchedTypes = searchedTypes
        };
    }

    /// <summary>All persisted barcodes for a product, company-scoped.</summary>
    public async Task<List<Barcode>> GetProductBarcodesAsync(Guid companyId, Guid productId)
    {
        var product = await _productRepo.GetByIdAsync(companyId, productId)
            ?? throw new InvalidOperationException("Product not found for this company.");
        return await _barcodeRepo.GetByProductIdAsync(product.Id);
    }

    private static GenerateBarcodeResponse ToResponse(Barcode barcode) => new()
    {
        Barcode = barcode.Value,
        Format = "CODE128",
        SourceType = "Product",
        CreatedAt = barcode.CreatedAtUtc.ToString("o")
    };
}

