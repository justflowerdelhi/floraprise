using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

/// <summary>
/// One-time data migration that ensures every existing Product has a valid CategoryId.
///
/// For each product where CategoryId IS NULL:
///   1. Look up (or create) a ProductCategoryEntity whose Name matches the
///      existing ProductCategory enum or ProductType enum value.
///   2. Assign the CategoryId.
///
/// IsPerishable is now derived from Category at read-time — no sync needed.
///
/// The service is idempotent — subsequent runs are no-ops once all products
/// have been assigned.
/// </summary>
public static class CategoryMigrationService
{
    /// <summary>
    /// Well-known category definitions keyed by the legacy ProductCategory enum
    /// or ProductType enum name (case-insensitive).
    /// Bool = IsPerishable, second bool = TrackBatchByDefault.
    /// </summary>
    private static readonly Dictionary<string, (string DisplayName, bool IsPerishable, bool TrackBatch)> KnownCategories = new(StringComparer.OrdinalIgnoreCase)
    {
        // ProductCategory enum values
        ["Roses"]               = ("Roses",                 true,  true),
        ["Lilies"]              = ("Lilies",                true,  true),
        ["Tulips"]              = ("Tulips",                true,  true),
        ["Orchids"]             = ("Orchids",               true,  true),
        ["Carnations"]          = ("Carnations",            true,  true),
        ["MixedFlowers"]        = ("Mixed Flowers",         true,  true),
        ["Seasonal"]            = ("Seasonal",              true,  true),
        ["Exotic"]              = ("Exotic",                true,  true),
        ["WeddingFlowers"]      = ("Wedding Flowers",       true,  true),
        ["SymPathyFlowers"]     = ("Sympathy Flowers",      true,  true),
        ["CelebrationFlowers"]  = ("Celebration Flowers",   true,  true),
        ["IndoorPlants"]        = ("Indoor Plants",         false, false),
        ["OutdoorPlants"]       = ("Outdoor Plants",        false, false),
        ["Vases"]               = ("Vases",                 false, false),
        ["Ribbons"]             = ("Ribbons",               false, false),
        ["Cards"]               = ("Cards",                 false, false),
        ["ChocolatesAndGifts"]  = ("Chocolates & Gifts",    false, false),
        ["Other"]               = ("Other",                 false, false),

        // ProductType enum values (fallback matching)
        ["SingleFlower"]        = ("Single Flower",         true,  true),
        ["Bouquet"]             = ("Bouquet",               true,  true),
        ["Arrangement"]         = ("Arrangement",           true,  true),
        ["Plant"]               = ("Plant",                 false, false),
        ["Gift"]                = ("Gift",                  false, false),
        ["Accessory"]           = ("Accessory",             false, false),
    };

    public static async Task MigrateAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SumpoojDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<SumpoojDbContext>>();

        // Fetch all products that still have no CategoryId (bypass tenant filter)
        var orphanProducts = await db.Products
            .IgnoreQueryFilters()
            .Where(p => p.CategoryId == null)
            .ToListAsync();

        if (orphanProducts.Count == 0)
        {
            logger.LogInformation("[CategoryMigration] All products already have CategoryId. Nothing to do.");
            return;
        }

        logger.LogInformation("[CategoryMigration] Found {Count} product(s) without CategoryId. Starting migration…", orphanProducts.Count);

        // Group by CompanyId so we create per-company categories
        var byCompany = orphanProducts.GroupBy(p => p.CompanyId);

        foreach (var companyGroup in byCompany)
        {
            var companyId = companyGroup.Key;

            // Load existing dynamic categories for this company (bypass tenant filter)
            var existingCategories = await db.ProductCategories
                .IgnoreQueryFilters()
                .Where(c => c.CompanyId == companyId)
                .ToListAsync();

            var categoryByName = existingCategories
                .ToDictionary(c => c.Name, c => c, StringComparer.OrdinalIgnoreCase);

            foreach (var product in companyGroup)
            {
                // Try matching by ProductCategory enum first, then ProductType
                var enumName = product.Category.ToString();
                if (!KnownCategories.TryGetValue(enumName, out var definition))
                {
                    // Fallback: match by ProductType
                    var typeName = product.ProductType.ToString();
                    if (!KnownCategories.TryGetValue(typeName, out definition))
                    {
                        // Last resort — use "Other"
                        definition = KnownCategories["Other"];
                    }
                }

                // Find or create the dynamic category
                if (!categoryByName.TryGetValue(definition.DisplayName, out var category))
                {
                    category = new ProductCategoryEntity(
                        companyId: companyId,
                        name: definition.DisplayName,
                        isPerishable: definition.IsPerishable,
                        trackBatchByDefault: definition.TrackBatch);

                    db.ProductCategories.Add(category);
                    categoryByName[definition.DisplayName] = category;

                    logger.LogInformation(
                        "[CategoryMigration] Created category '{Name}' (perishable={P}) for company {Company}",
                        definition.DisplayName, definition.IsPerishable, companyId);
                }

                // Assign CategoryId (IsPerishable is derived from category at query time)
                product.SetCategoryId(category.Id);
            }
        }

        await db.SaveChangesAsync();
        logger.LogInformation("[CategoryMigration] Migration complete. {Count} product(s) updated.", orphanProducts.Count);
    }
}
