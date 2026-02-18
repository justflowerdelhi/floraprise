namespace Sumpooj.Application.Suppliers;

public class CreateSupplierRequest
{
    public string Name { get; set; } = default!;
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public int PaymentTermsDays { get; set; } = 30;
    public string? TaxIdentifier { get; set; }
}

public class UpdateSupplierRequest
{
    public string? Name { get; set; }
    public string? ContactPerson { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public int? PaymentTermsDays { get; set; }
    public string? TaxIdentifier { get; set; }
    public string? Rating { get; set; }
}

public class SupplierSearchRequest
{
    public string? Query { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
