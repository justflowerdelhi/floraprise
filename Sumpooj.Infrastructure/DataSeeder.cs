using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Identity;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

/// <summary>
/// Seeds initial data for the application.
/// Note: Database schema is managed via Database/sumpooj_complete_schema.sql (Database-First approach)
/// This seeder creates roles (if not already seeded via SQL), users, and demo data.
/// For comprehensive demo data, also run Database/005_demo_data_seed.sql
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
            var connectionString = db.Database.GetConnectionString();
            var host = "unknown";
            if (connectionString != null)
            {
                var hostMatch = System.Text.RegularExpressions.Regex.Match(connectionString, @"Host=([^;]+)");
                if (hostMatch.Success) host = hostMatch.Groups[1].Value;
            }

            throw new InvalidOperationException(
                $"Cannot connect to database at Host={host}. " +
                "Ensure PostgreSQL is running and the connection string in appsettings.json is correct. " +
                "Run Database/sumpooj_complete_schema.sql to create the schema.");
        }

        await SeedRolesAsync(roleManager);
        await SeedPlatformAdminAsync(userManager);
        var demoCompany = await SeedDemoCompanyAsync(db);
        await SeedCompanyUsersAsync(userManager, demoCompany);
        await SeedLocationsAsync(db, demoCompany);
        await SeedTaxRulesAsync(db, demoCompany);
        await SeedProductCategoriesAsync(db, demoCompany);
        await SeedSuppliersAsync(db, demoCompany);
        await SeedProductsAsync(db, demoCompany);
        await SeedCustomersAsync(db, demoCompany);
        await SeedStaffAsync(db, demoCompany);
        await SeedDeliveryZonesAsync(db, demoCompany);
    }

    private static async Task SeedRolesAsync(RoleManager<IdentityRole<Guid>> roleManager)
    {
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
    }

    private static async Task SeedPlatformAdminAsync(UserManager<ApplicationUser> userManager)
    {
        const string superAdminEmail = "sumit.singh@sumpooj.com";
        var superAdmin = await userManager.FindByEmailAsync(superAdminEmail);

        if (superAdmin == null)
        {
            superAdmin = new ApplicationUser
            {
                UserName = superAdminEmail,
                Email = superAdminEmail,
                CompanyId = null,
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(superAdmin, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(superAdmin, "PlatformSuperAdmin");
            }
        }
    }

    private static async Task<Company> SeedDemoCompanyAsync(SumpoojDbContext db)
    {
        var company = await db.Companies.FirstOrDefaultAsync(c => c.Name == "Demo Florist");

        if (company == null)
        {
            company = new Company(
                name: "Demo Florist",
                region: "IN",
                email: "info@demoflorist.com",
                phone: "+91-9999999999",
                address: "123 Flower Street, Bandra West, Mumbai, Maharashtra 400050",
                shortDescription: "Premium flower arrangements and gifts for all occasions",
                logoPath: null,
                timeZone: "Asia/Kolkata",
                currencyCode: "INR",
                taxIdentifier: "GSTIN27AADCD1234A1ZM"
            );

            db.Companies.Add(company);
            await db.SaveChangesAsync();
        }

        return company;
    }

    private static async Task SeedCompanyUsersAsync(UserManager<ApplicationUser> userManager, Company company)
    {
        // Company Admin
        const string adminEmail = "admin@demoflorist.com";
        if (await userManager.FindByEmailAsync(adminEmail) == null)
        {
            var admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                CompanyId = company.Id,
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(admin, "Admin@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(admin, "CompanyAdmin");
            }
        }

        // Manager
        const string managerEmail = "manager@demoflorist.com";
        if (await userManager.FindByEmailAsync(managerEmail) == null)
        {
            var manager = new ApplicationUser
            {
                UserName = managerEmail,
                Email = managerEmail,
                CompanyId = company.Id,
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(manager, "Manager@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(manager, "Manager");
            }
        }

        // Staff User
        const string staffEmail = "staff@demoflorist.com";
        if (await userManager.FindByEmailAsync(staffEmail) == null)
        {
            var staff = new ApplicationUser
            {
                UserName = staffEmail,
                Email = staffEmail,
                CompanyId = company.Id,
                EmailConfirmed = true,
                IsActive = true
            };

            var result = await userManager.CreateAsync(staff, "Staff@123");
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(staff, "Staff");
            }
        }
    }

    private static async Task SeedLocationsAsync(SumpoojDbContext db, Company company)
    {
        if (await db.Locations.AnyAsync(l => l.CompanyId == company.Id))
            return;

        var locations = new[]
        {
            new Location(company.Id, "Bandra Main Store", "BANDRA-01", LocationType.Store, "123 Flower Street, Bandra West, Mumbai 400050"),
            new Location(company.Id, "Andheri Warehouse", "ANDH-WH", LocationType.Warehouse, "45 Industrial Area, Andheri East, Mumbai 400069"),
            new Location(company.Id, "Juhu Outlet", "JUHU-01", LocationType.Store, "78 Beach Road, Juhu, Mumbai 400049")
        };

        locations[0].SetAsDefault();

        db.Locations.AddRange(locations);
        await db.SaveChangesAsync();
    }

    private static async Task SeedTaxRulesAsync(SumpoojDbContext db, Company company)
    {
        if (await db.TaxRules.AnyAsync(t => t.CompanyId == company.Id))
            return;

        var taxRules = new[]
        {
            new TaxRule(company.Id, "IN", "GST 18%", 18.0000m, false),
            new TaxRule(company.Id, "IN", "GST 12%", 12.0000m, false),
            new TaxRule(company.Id, "IN", "GST 5%", 5.0000m, false),
            new TaxRule(company.Id, "IN", "Exempt", 0m, false)
        };

        db.TaxRules.AddRange(taxRules);
        await db.SaveChangesAsync();
    }

    private static async Task SeedProductCategoriesAsync(SumpoojDbContext db, Company company)
    {
        if (await db.ProductCategories.AnyAsync(c => c.CompanyId == company.Id))
            return;

        var categories = new[]
        {
            new ProductCategoryEntity(company.Id, "Fresh Flowers", true, true),
            new ProductCategoryEntity(company.Id, "Bouquets & Arrangements", true, false),
            new ProductCategoryEntity(company.Id, "Plants & Succulents", false, false),
            new ProductCategoryEntity(company.Id, "Vases & Containers", false, false),
            new ProductCategoryEntity(company.Id, "Gift Items", false, false),
            new ProductCategoryEntity(company.Id, "Greens & Fillers", true, true)
        };

        db.ProductCategories.AddRange(categories);
        await db.SaveChangesAsync();
    }

    private static async Task SeedSuppliersAsync(SumpoojDbContext db, Company company)
    {
        if (await db.Suppliers.AnyAsync(s => s.CompanyId == company.Id))
            return;

        var supplier1 = new Supplier(company.Id, "Flora Farms India", "Rajesh Kumar", 
            "rajesh@florafarmsindia.com", "+91-9876543210", "Ooty Flower Market, Tamil Nadu");
        supplier1.SetPaymentTerms(30);
        supplier1.SetTaxIdentifier("GSTIN33AABCD1234E1ZM");
        supplier1.SetRating(SupplierRating.Excellent);

        var supplier2 = new Supplier(company.Id, "Bangalore Blooms", "Priya Sharma",
            "priya@bangaloreblooms.in", "+91-9123456789", "45 Flower Market Road, Bangalore 560001");
        supplier2.SetPaymentTerms(15);
        supplier2.SetTaxIdentifier("GSTIN29AABCB5678F1ZM");
        supplier2.SetRating(SupplierRating.Good);

        var supplier3 = new Supplier(company.Id, "Dutch Flower Imports", "Hans Van Der Berg",
            "hans@dutchflowerimports.com", "+31-20-555-1234", "Aalsmeer Flower Auction, Netherlands");
        supplier3.SetPaymentTerms(45);
        supplier3.SetTaxIdentifier("NL123456789B01");
        supplier3.SetRating(SupplierRating.Excellent);

        db.Suppliers.AddRange(supplier1, supplier2, supplier3);
        await db.SaveChangesAsync();
    }

    private static async Task SeedProductsAsync(SumpoojDbContext db, Company company)
    {
        if (await db.Products.AnyAsync(p => p.CompanyId == company.Id))
            return;

        var products = new List<Product>
        {
            // Fresh Flowers
            new Product(company.Id, "Red Roses", "ROSE-RED-001", ProductType.SingleFlower, ProductCategory.Roses, 60m, 25m, "Premium long-stem red roses"),
            new Product(company.Id, "White Roses", "ROSE-WHT-001", ProductType.SingleFlower, ProductCategory.Roses, 65m, 28m, "Elegant white roses for weddings"),
            new Product(company.Id, "White Oriental Lilies", "LILY-WHT-001", ProductType.SingleFlower, ProductCategory.Lilies, 120m, 45m, "Fragrant white oriental lilies"),
            new Product(company.Id, "Gerbera Daisies Mix", "GERBERA-MIX-001", ProductType.SingleFlower, ProductCategory.MixedFlowers, 40m, 15m, "Colorful mix of gerbera daisies"),
            new Product(company.Id, "Red Carnations", "CARN-RED-001", ProductType.SingleFlower, ProductCategory.Carnations, 30m, 12m, "Classic red carnations"),

            // Bouquets
            new Product(company.Id, "Romantic Red Rose Bouquet", "BQ-ROMANTIC-001", ProductType.Bouquet, ProductCategory.Roses, 1999m, 800m, "24 premium red roses with baby breath"),
            new Product(company.Id, "Sunshine Mixed Bouquet", "BQ-MIXED-001", ProductType.Bouquet, ProductCategory.MixedFlowers, 1499m, 600m, "Cheerful mix of gerberas, lilies, and roses"),
            new Product(company.Id, "White Sympathy Arrangement", "ARR-SYMPATHY-001", ProductType.Arrangement, ProductCategory.SymPathyFlowers, 2999m, 1200m, "Elegant white lilies and roses"),

            // Gift Items
            new Product(company.Id, "Crystal Glass Vase", "VASE-GLASS-001", ProductType.Accessory, ProductCategory.Vases, 599m, 200m, "Elegant crystal glass vase, 25cm"),
            new Product(company.Id, "Premium Chocolate Box", "CHOC-BOX-001", ProductType.Gift, ProductCategory.ChocolatesAndGifts, 699m, 300m, "Assorted premium chocolates, 250g"),
            new Product(company.Id, "Medium Teddy Bear", "TEDDY-MED-001", ProductType.Gift, ProductCategory.ChocolatesAndGifts, 599m, 250m, "Soft plush teddy bear, 30cm")
        };

        db.Products.AddRange(products);
        await db.SaveChangesAsync();
    }

    private static async Task SeedCustomersAsync(SumpoojDbContext db, Company company)
    {
        if (await db.Customers.AnyAsync(c => c.CompanyId == company.Id))
            return;

        var customer1 = new Customer(company.Id, "Amit Sharma", "amit.sharma@gmail.com", "+91-9876543210");
        customer1.UpdateDefaultCardMessage("With love and best wishes!");

        var customer2 = new Customer(company.Id, "Priya Patel", "priya.patel@outlook.com", "+91-9123456789");
        customer2.UpdateDefaultCardMessage("Thinking of you!");

        var customer3 = new Customer(company.Id, "Raj Enterprises Ltd", "procurement@rajenterprises.com", "+91-22-26543210");
        customer3.UpdateDefaultCardMessage("Corporate Greetings from Raj Enterprises");

        var customer4 = new Customer(company.Id, "Meera Singh", "meera.singh@yahoo.com", "+91-9654321098");

        var customer5 = new Customer(company.Id, "Taj Hotel Mumbai", "events@tajhotels.com", "+91-22-66543210");
        customer5.UpdateDefaultCardMessage("With Compliments from The Taj");

        db.Customers.AddRange(customer1, customer2, customer3, customer4, customer5);
        await db.SaveChangesAsync();
    }

    private static async Task SeedStaffAsync(SumpoojDbContext db, Company company)
    {
        if (await db.Staff.AnyAsync(s => s.CompanyId == company.Id))
            return;

        var location = await db.Locations.FirstOrDefaultAsync(l => l.CompanyId == company.Id && l.IsDefault);

        var staff1 = new Staff(company.Id, "Vikram Designer", StaffRole.Designer, "vikram@demoflorist.com", "+91-9876500001", null);
        staff1.SetCommission(CommissionType.Revenue, 5m);
        staff1.SetHourlyRate(500m);
        staff1.AssignLocation(location?.Id);

        var staff2 = new Staff(company.Id, "Anita Cashier", StaffRole.Cashier, "anita@demoflorist.com", "+91-9876500002", null);
        staff2.SetCommission(CommissionType.Revenue, 3m);
        staff2.SetHourlyRate(400m);
        staff2.AssignLocation(location?.Id);

        var staff3 = new Staff(company.Id, "Ramesh Driver", StaffRole.Driver, "ramesh@demoflorist.com", "+91-9876500003", null);
        staff3.SetHourlyRate(300m);
        staff3.AssignLocation(location?.Id);

        db.Staff.AddRange(staff1, staff2, staff3);
        await db.SaveChangesAsync();
    }

    private static async Task SeedDeliveryZonesAsync(SumpoojDbContext db, Company company)
    {
        if (await db.DeliveryZones.AnyAsync(z => z.CompanyId == company.Id))
            return;

        // Create basic zones with constructor, use Update for full data
        var zone1 = new DeliveryZone(company.Id, "Bandra & Khar", "ZONE-A", 99m, 30);
        zone1.Update("Bandra & Khar", "ZONE-A", "400050,400051,400052", "Bandra West,Bandra East,Khar",
            99m, 2000m, 149m, 249m, 30, null, 1, null);

        var zone2 = new DeliveryZone(company.Id, "Andheri & Juhu", "ZONE-B", 149m, 45);
        zone2.Update("Andheri & Juhu", "ZONE-B", "400049,400053,400058,400069", "Juhu,Andheri West,Andheri East,Versova",
            149m, 3000m, 199m, 299m, 45, null, 2, null);

        var zone3 = new DeliveryZone(company.Id, "South Mumbai", "ZONE-C", 199m, 60);
        zone3.Update("South Mumbai", "ZONE-C", "400001,400002,400003,400004,400005,400020,400021", "Colaba,Fort,Churchgate,Marine Lines",
            199m, 5000m, 299m, 399m, 60, null, 3, null);

        db.DeliveryZones.AddRange(zone1, zone2, zone3);
        await db.SaveChangesAsync();
    }
}

