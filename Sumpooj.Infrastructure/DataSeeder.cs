using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

/// <summary>
/// Seeds initial data for the application.
/// Note: Database schema and roles are managed via Database/sumpooj_complete_schema.sql (Database-First approach)
/// This seeder only creates initial users and demo data that can't be done in SQL.
/// </summary>
public static class DataSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();

        var db = scope.ServiceProvider.GetRequiredService<SumpoojDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();

        // Database-First: Schema is managed via SQL script
        if (!await db.Database.CanConnectAsync())
        {
            throw new InvalidOperationException(
                "Cannot connect to database. Ensure PostgreSQL is running and the connection string is correct. " +
                "Run Database/sumpooj_complete_schema.sql to create the schema.");
        }

        // Verify roles exist (seeded by SQL script)
        // If roles don't exist, the SQL script wasn't run
        if (!await roleManager.RoleExistsAsync("PlatformSuperAdmin"))
        {
            throw new InvalidOperationException(
                "Roles not found in database. Please run Database/sumpooj_complete_schema.sql first.");
        }

        // ----------------------------
        // 1) Platform Super Admin User
        // ----------------------------
        const string superAdminEmail = "sumit.singh@sumpooj.com";
        var superAdmin = await userManager.FindByEmailAsync(superAdminEmail);

        if (superAdmin == null)
        {
            superAdmin = new ApplicationUser
            {
                UserName = superAdminEmail,
                Email = superAdminEmail,
                CompanyId = null, // platform user - no company
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(superAdmin, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(superAdmin, "PlatformSuperAdmin");
            }
        }

        // ----------------------------
        // 2) Demo Company
        // ----------------------------
        Company company;
        if (!await db.Companies.AnyAsync())
        {
            company = new Company(
                name: "Demo Florist",
                region: "IN",
                email: "info@demoflorist.com",
                phone: "9999999999",
                address: "123 Flower Street, Mumbai, Maharashtra 400001",
                shortDescription: "A demo florist company for testing",
                logoPath: null,
                timeZone: "Asia/Kolkata",
                currencyCode: "INR",
                taxIdentifier: "GSTIN123456789"
            );

            db.Companies.Add(company);
            await db.SaveChangesAsync();
        }
        else
        {
            company = await db.Companies.FirstAsync();
        }

        // ----------------------------
        // 3) Company Admin User
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

            var result = await userManager.CreateAsync(companyAdmin, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(companyAdmin, "CompanyAdmin");
            }
        }

        // ----------------------------
        // 4) Default Location for Company
        // ----------------------------
        if (!await db.Locations.AnyAsync(l => l.CompanyId == company.Id))
        {
            var defaultLocation = new Location(
                companyId: company.Id,
                name: "Main Store",
                code: "MAIN",
                locationType: LocationType.Store,
                address: "123 Flower Street, Mumbai"
            );
            defaultLocation.SetAsDefault();

            db.Locations.Add(defaultLocation);
            await db.SaveChangesAsync();
        }
    }
}

