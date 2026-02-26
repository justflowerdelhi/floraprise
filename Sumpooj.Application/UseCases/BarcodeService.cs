using Sumpooj.Application.Barcodes;
using Sumpooj.Application.Interfaces;

namespace Sumpooj.Application.UseCases;

public class BarcodeService
{
    private readonly IProductRepository _productRepo;

    public BarcodeService(IProductRepository productRepo)
    {
        _productRepo = productRepo;
    }

    public Task<GenerateBarcodeResponse> GenerateAsync(GenerateBarcodeRequest request)
    {
        var prefix = request.Prefix ?? "INT";
        var barcode = $"{prefix}-{DateTime.UtcNow:yyyyMMddHHmmss}-{Guid.NewGuid().ToString("N")[..6].ToUpper()}";

        return Task.FromResult(new GenerateBarcodeResponse
        {
            Barcode = barcode,
            Format = request.Format ?? "CODE128",
            SourceType = request.SourceType,
            CreatedAt = DateTime.UtcNow.ToString("o")
        });
    }

    public async Task<ValidateBarcodeResponse> ValidateAsync(Guid companyId, ValidateBarcodeRequest request)
    {
        // Check if any product already has this barcode
        var existing = await _productRepo.GetByBarcodeAsync(request.Barcode);

        return new ValidateBarcodeResponse
        {
            IsValid = !string.IsNullOrWhiteSpace(request.Barcode),
            IsDuplicate = existing != null,
            Format = request.Format ?? "CODE128",
            ExistingProduct = existing != null
                ? new { id = existing.Id, name = existing.Name, sku = existing.Sku }
                : null
        };
    }

    public async Task<SearchBarcodeResponse> SearchAsync(Guid companyId, SearchBarcodeRequest request)
    {
        var searchedTypes = new List<string> { "EXTERNAL", "INTERNAL" };

        // Search by barcode field on Product
        var product = await _productRepo.GetByBarcodeAsync(request.Barcode);

        if (product != null && (request.IncludeOutOfStock || product.StockQuantity > 0))
        {
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
                    ExternalBarcode = product.Barcode,
                    FoundByType = "EXTERNAL"
                },
                SearchedTypes = searchedTypes
            };
        }

        return new SearchBarcodeResponse
        {
            Found = false,
            SearchedTypes = searchedTypes
        };
    }
}
