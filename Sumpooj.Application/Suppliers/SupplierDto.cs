namespace Sumpooj.Application.Suppliers;

public class SupplierDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public bool IsActive { get; set; }
    public string Rating { get; set; } = default!;
    public string? Notes { get; set; }
    public int PaymentTermsDays { get; set; }
    public string? TaxIdentifier { get; set; }
    public DateTime? LastOrderDate { get; set; }
    public int TotalOrdersCount { get; set; }
    public decimal TotalSpentAmount { get; set; }
    public DateTime CreatedAtUtc { get; set; }
}

public class SupplierListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public bool IsActive { get; set; }
    public string Rating { get; set; } = default!;
    public int TotalOrdersCount { get; set; }
}
