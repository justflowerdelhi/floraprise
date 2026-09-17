namespace Sumpooj.Application.Customers;
using System.Collections.Generic;

public class CustomerSearchRequest
{
    public string? Query { get; set; }
    public List<string>? PurchasedCategories { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
