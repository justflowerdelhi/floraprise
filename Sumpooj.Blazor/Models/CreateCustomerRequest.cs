namespace Sumpooj.Blazor.Models;

public class CreateCustomerRequest
{
    public string Name { get; set; } = "";
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? DefaultCardMessage { get; set; }
}
