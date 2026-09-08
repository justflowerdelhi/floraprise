namespace Sumpooj.Application.Mobile;

public sealed record MobileLowStockProductDto(
    Guid ProductId,
    string Name,
    string? Sku,
    int CurrentQuantity,
    int MinimumQuantity,
    string Status);
