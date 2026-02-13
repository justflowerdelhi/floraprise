namespace Sumpooj.Application.Interfaces;

public interface ITenantContext
{
    Guid? CompanyId { get; }
    bool IsPlatformUser { get; }
    string? Region { get; }
}
