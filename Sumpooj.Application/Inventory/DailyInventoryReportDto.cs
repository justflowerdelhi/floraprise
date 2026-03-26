namespace Sumpooj.Application.Inventory;

public class DailyInventoryReportDto
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;

    public int OpeningStock { get; set; }
    public int Purchased { get; set; }
    public int Sold { get; set; }
    public int Adjustments { get; set; }
    public int ClosingStock { get; set; }
}
