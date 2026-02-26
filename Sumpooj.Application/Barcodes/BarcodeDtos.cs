namespace Sumpooj.Application.Barcodes;

public class GenerateBarcodeRequest
{
    public string SourceType { get; set; } = default!;
    public Guid ReferenceId { get; set; }
    public string? Prefix { get; set; }
    public string? Format { get; set; }
}

public class GenerateBarcodeResponse
{
    public string Barcode { get; set; } = default!;
    public string Format { get; set; } = default!;
    public string SourceType { get; set; } = default!;
    public string CreatedAt { get; set; } = default!;
}

public class ValidateBarcodeRequest
{
    public string Barcode { get; set; } = default!;
    public string? Format { get; set; }
}

public class ValidateBarcodeResponse
{
    public bool IsValid { get; set; }
    public bool IsDuplicate { get; set; }
    public string Format { get; set; } = default!;
    public object? ExistingProduct { get; set; }
}

public class SearchBarcodeRequest
{
    public string Barcode { get; set; } = default!;
    public Guid? LocationId { get; set; }
    public bool IncludeOutOfStock { get; set; }
}

public class SearchBarcodeResponse
{
    public bool Found { get; set; }
    public ProductBarcodeInfo? Product { get; set; }
    public List<string> SearchedTypes { get; set; } = new();
}

public class ProductBarcodeInfo
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string Sku { get; set; } = default!;
    public string Unit { get; set; } = default!;
    public decimal UnitPrice { get; set; }
    public int StockLevel { get; set; }
    public string? ExternalBarcode { get; set; }
    public string? InternalBarcode { get; set; }
    public string FoundByType { get; set; } = default!;
}
