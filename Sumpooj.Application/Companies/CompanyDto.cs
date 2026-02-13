namespace Sumpooj.Application.Companies;

public class CompanyDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Region { get; set; } = default!;
    public bool IsActive { get; set; }
}
