using Microsoft.AspNetCore.Identity;

namespace Sumpooj.Infrastructure.Identity;

public class ApplicationUser : IdentityUser<Guid>
{
    // NULL → Platform (Super Admin / Support)
    // NOT NULL → Company user
    public Guid? CompanyId { get; set; }

    public bool IsActive { get; set; } = true;
}
