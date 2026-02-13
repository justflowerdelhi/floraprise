namespace Sumpooj.API.Models;

public class CreateCustomerRequest
{
    public string Name { get; set; } = default!;
    public string? Email { get; set; }
    public string? Phone { get; set; }
}
