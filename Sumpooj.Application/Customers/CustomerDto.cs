namespace Sumpooj.Application.Customers;

public class CustomerDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
}
