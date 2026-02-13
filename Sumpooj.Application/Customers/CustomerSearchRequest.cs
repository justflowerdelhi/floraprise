namespace Sumpooj.Application.Customers;

public class CustomerSearchRequest
{
    public string? Query { get; set; }

    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
