using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

public static class DataSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();

        var db = scope.ServiceProvider.GetRequiredService<SumpoojDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();

        // Ensure DB is up-to-date
        await db.Database.MigrateAsync();

        // ----------------------------
        // 1) Roles
        // ----------------------------
        var roles = new[]
        {
            "PlatformSuperAdmin",
            "PlatformSupport",
            "CompanyAdmin",
            "Manager",
            "Staff",
            "Delivery"
        };

        foreach (var role in roles)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new IdentityRole<Guid>(role));
            }
        }

        // ----------------------------
        // 2) Platform Super Admin
        // ----------------------------
        const string superAdminEmail = "sumit.singh@sumpooj.com";
        var superAdmin = await userManager.FindByEmailAsync(superAdminEmail);

        if (superAdmin == null)
        {
            superAdmin = new ApplicationUser
            {
                UserName = superAdminEmail,
                Email = superAdminEmail,
                CompanyId = null, // platform user
                EmailConfirmed = true,
                IsActive = true
            };

            await userManager.CreateAsync(superAdmin, "Admin@123");
            await userManager.AddToRoleAsync(superAdmin, "PlatformSuperAdmin");
        }

        // ----------------------------
        // 3) First Company
        // ----------------------------
        Company company;
        if (!await db.Companies.AnyAsync())
        {
            company = new Company(
                name: "Demo Florist",
                region: "IN",
                email: "info@demoflorist.com",
                phone: "9999999999",
                address: "Demo Address",
                shortDescription: "Demo florist company",
                logoPath: null,
                timeZone: "Asia/Kolkata",
                currencyCode: "INR",
                taxIdentifier: "GSTIN123"
            );

            db.Companies.Add(company);
            await db.SaveChangesAsync();
        }
        else
        {
            company = await db.Companies.FirstAsync();
        }

        // ----------------------------
        // 4) Company Admin
        // ----------------------------
        const string companyAdminEmail = "admin@demoflorist.com";
        var companyAdmin = await userManager.FindByEmailAsync(companyAdminEmail);

        if (companyAdmin == null)
        {
            companyAdmin = new ApplicationUser
            {
                UserName = companyAdminEmail,
                Email = companyAdminEmail,
                CompanyId = company.Id,
                EmailConfirmed = true,
                IsActive = true
            };

            await userManager.CreateAsync(companyAdmin, "Admin@123");
            await userManager.AddToRoleAsync(companyAdmin, "CompanyAdmin");
        }
    }
}
