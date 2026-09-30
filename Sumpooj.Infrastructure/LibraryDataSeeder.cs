using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

/// <summary>
/// Seeds initial global Floraprise Library V1 reference catalog data using
/// the canonical Sumpooj.Infrastructure/Data/starter_catalogue.json dataset.
/// Library categories and products are global reference data (no CompanyId).
/// All operations are deterministic, idempotent, and non-destructive.
/// </summary>
public static class LibraryDataSeeder
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public static async Task<LibrarySeedResult> SeedAsync(SumpoojDbContext db)
    {
        var result = new LibrarySeedResult();

        // 1. Ensure Categories & Category Hierarchy
        await EnsureCategoryTaxonomyAsync(db, result);

        // 2. Load category lookup by slug
        var categoryMap = await db.LibraryCategories.ToDictionaryAsync(c => c.Slug, c => c.Id);

        // 3. Load Canonical Solo Starter Catalogue JSON
        var soloProducts = LoadCanonicalStarterCatalogue();

        // 4. Seed and Reconcile Solo Products into Library
        foreach (var item in soloProducts)
        {
            var slug = GenerateSlug(item.Name);
            var categoryId = ResolveCategoryId(item, categoryMap);
            var standardUnit = MapUnitOfMeasure(item.DefaultUnit);
            var productType = MapProductType(item);
            var standardSku = GenerateStandardSku(item);

            var existing = await db.LibraryProducts.FirstOrDefaultAsync(p => p.Slug == slug || p.Name == item.Name);
            if (existing == null)
            {
                var product = new LibraryProduct(
                    name: item.Name,
                    slug: slug,
                    categoryId: categoryId,
                    productType: productType,
                    standardUnit: standardUnit,
                    standardSku: standardSku,
                    description: $"Standard {item.Name} catalog reference item.",
                    referenceImageUrl: null,
                    thumbnailUrl: null,
                    searchKeywords: GenerateKeywords(item),
                    sortOrder: 0
                );
                db.LibraryProducts.Add(product);
                result.ProductsCreated++;
            }
            else
            {
                // Reconcile existing record if source-owned properties require update
                var needsUpdate = existing.CategoryId != categoryId ||
                                  existing.StandardUnit != standardUnit ||
                                  existing.ProductType != productType;

                if (needsUpdate)
                {
                    existing.Update(
                        name: existing.Name,
                        slug: existing.Slug,
                        categoryId: categoryId ?? existing.CategoryId,
                        productType: productType,
                        standardUnit: standardUnit,
                        standardSku: existing.StandardSku ?? standardSku,
                        description: existing.Description,
                        referenceImageUrl: existing.ReferenceImageUrl,
                        thumbnailUrl: existing.ThumbnailUrl,
                        searchKeywords: existing.SearchKeywords,
                        sortOrder: existing.SortOrder
                    );
                    result.ProductsReconciled++;
                }
                else
                {
                    result.ProductsRetainedUnchanged++;
                }
            }
        }

        // 5. Retain existing non-Solo Library products (e.g. curated bouquets & gifts)
        var soloNames = new HashSet<string>(soloProducts.Select(p => p.Name), StringComparer.OrdinalIgnoreCase);
        var existingNonSolo = await db.LibraryProducts.Where(p => !soloNames.Contains(p.Name)).ToListAsync();
        result.ProductsRetainedNonSolo = existingNonSolo.Count;

        // 6. Ensure Global Florist Festivals Calendar
        await EnsureFestivalsAsync(db, result);

        // 7. Ensure Global Auspicious Wedding Dates (Muhurats) Calendar
        await EnsureWeddingDatesAsync(db, result);

        await db.SaveChangesAsync();
        return result;
    }

    public static List<CanonicalStarterProduct> LoadCanonicalStarterCatalogue()
    {
        var assembly = typeof(LibraryDataSeeder).Assembly;

        // Try manifest resource stream first
        using (var stream = assembly.GetManifestResourceStream("Sumpooj.Infrastructure.Data.starter_catalogue.json")
                            ?? assembly.GetManifestResourceStream("Data.starter_catalogue.json"))
        {
            if (stream != null)
            {
                using var reader = new StreamReader(stream);
                var json = reader.ReadToEnd();
                var items = JsonSerializer.Deserialize<List<CanonicalStarterProduct>>(json, JsonOptions);
                if (items != null && items.Count > 0)
                {
                    return items;
                }
            }
        }

        // Fallback to file search across typical runtime/development probe paths
        var probePaths = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Data", "starter_catalogue.json"),
            Path.Combine(AppContext.BaseDirectory, "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Data", "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "Sumpooj.Infrastructure", "Data", "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "Sumpooj.Infrastructure", "Data", "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "Sumpooj.Infrastructure", "Data", "starter_catalogue.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "..", "..", "..", "..", "Sumpooj.Infrastructure", "Data", "starter_catalogue.json")
        };

        foreach (var path in probePaths)
        {
            if (File.Exists(path))
            {
                var json = File.ReadAllText(path);
                var items = JsonSerializer.Deserialize<List<CanonicalStarterProduct>>(json, JsonOptions);
                if (items != null && items.Count > 0)
                {
                    return items;
                }
            }
        }

        throw new InvalidOperationException(
            "Canonical starter_catalogue.json not found in assembly resources or file path. " +
            "Ensure starter_catalogue.json is embedded and copied to output directory.");
    }

    private static async Task EnsureCategoryTaxonomyAsync(SumpoojDbContext db, LibrarySeedResult result)
    {
        // 1. Top-Level Core Categories
        var topCategories = new (string Name, string Slug, string Description, int SortOrder)[]
        {
            ("Flowers", "flowers", "Fresh cut stems, blooms, and floral greens", 1),
            ("Supplies", "supplies", "Florist supplies, packaging, and floral accessories", 2),
            ("Finished Products", "finished-products", "Arrangements, plants, chocolates, cakes, and gifts", 3),
            // Useful platform categories preserved non-destructively
            ("Bouquets", "bouquets", "Hand-tied bouquets, bunches, and floral wraps", 4),
            ("Plants", "plants", "Potted plants, succulents, and flowering indoor plants", 5),
            ("Gifts", "gifts", "Add-on gifts, soft toys, hampers, and packaging", 6),
            ("Chocolate", "chocolate", "Artisan chocolates, truffles, and confectionery boxes", 7),
            ("Cakes", "cakes", "Celebration cakes, cupcakes, and bakery items", 8),
            ("Vases", "vases", "Glass, ceramic, and decorative floral vessels", 9),
            ("Cards", "cards", "Printed greeting cards and message tags", 10),
            ("Occasions", "occasions", "Curated floral collections by special event", 11),
            ("Weddings", "weddings", "Bridal bouquets, centerpieces, and wedding florals", 12),
            ("Corporate", "corporate", "Office arrangements, reception flowers, and corporate gifts", 13),
            ("Sympathy", "sympathy", "Condolence wreaths, sympathy sprays, and standing tributes", 14),
            ("Birthday", "birthday", "Vibrant and celebratory birthday florals", 15),
            ("Anniversary", "anniversary", "Romantic and milestone anniversary arrangements", 16),
            ("Love & Romance", "love-romance", "Passionate roses and romantic expressions", 17),
        };

        foreach (var (name, slug, description, sortOrder) in topCategories)
        {
            var existing = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == slug);
            if (existing == null)
            {
                var cat = new LibraryCategory(name, slug, description, null, null, null, sortOrder);
                db.LibraryCategories.Add(cat);
                result.CategoriesCreated++;
            }
        }
        await db.SaveChangesAsync();

        // 2. Child Categories under Flowers
        var flowers = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "flowers");
        if (flowers != null)
        {
            var flowerChildren = new (string Name, string Slug, string Description, int SortOrder)[]
            {
                ("Fillers", "fillers", "Floral filler stems like Gypsophila, Statice, Solidago", 1),
                ("Foliage", "foliage", "Greenery, leaves, ferns, and decorative foliage", 2),
                ("Roses", "roses", "Cut roses across single and spray varieties", 3),
                ("Lilies", "lilies", "Fragrant Oriental, Asiatic, and LA hybrid lilies", 4),
                ("Carnations", "carnations", "Standard and spray carnations in diverse shades", 5),
                ("Orchids", "orchids", "Dendrobium, Phalaenopsis, and Cymbidium orchids", 6),
            };

            foreach (var (name, slug, description, sortOrder) in flowerChildren)
            {
                var existing = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == slug);
                if (existing == null)
                {
                    var cat = new LibraryCategory(name, slug, description, null, null, flowers.Id, sortOrder);
                    db.LibraryCategories.Add(cat);
                    result.CategoriesCreated++;
                }
                else if (existing.ParentCategoryId != flowers.Id)
                {
                    existing.Update(existing.Name, existing.Slug, existing.Description, existing.ImageUrl, existing.IconKey, flowers.Id, existing.SortOrder);
                }
            }
        }

        // 3. Child Categories under Supplies
        var supplies = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == "supplies");
        if (supplies != null)
        {
            var suppliesChildren = new (string Name, string Slug, string Description, int SortOrder)[]
            {
                ("Packing", "packing", "Wrapping papers, cellophane, boxes, and ribbons", 1),
                ("Accessories", "accessories", "Floral foam, tapes, wires, pins, and tools", 2),
            };

            foreach (var (name, slug, description, sortOrder) in suppliesChildren)
            {
                var existing = await db.LibraryCategories.FirstOrDefaultAsync(c => c.Slug == slug);
                if (existing == null)
                {
                    var cat = new LibraryCategory(name, slug, description, null, null, supplies.Id, sortOrder);
                    db.LibraryCategories.Add(cat);
                    result.CategoriesCreated++;
                }
                else if (existing.ParentCategoryId != supplies.Id)
                {
                    existing.Update(existing.Name, existing.Slug, existing.Description, existing.ImageUrl, existing.IconKey, supplies.Id, existing.SortOrder);
                }
            }
        }

        await db.SaveChangesAsync();
    }

    private static Guid? ResolveCategoryId(CanonicalStarterProduct item, Dictionary<string, Guid> categoryMap)
    {
        Guid? Cat(string slug) => categoryMap.TryGetValue(slug, out var id) ? id : null;

        var nameLower = item.Name.ToLowerInvariant();
        var catLower = item.Category.ToLowerInvariant();

        if (catLower == "flowers")
        {
            if (nameLower.Contains("rose")) return Cat("roses");
            if (nameLower.Contains("lily") || nameLower.Contains("lilies")) return Cat("lilies");
            if (nameLower.Contains("carnation")) return Cat("carnations");
            if (nameLower.Contains("orchid")) return Cat("orchids");
            return Cat("flowers");
        }

        if (catLower == "fillers") return Cat("fillers") ?? Cat("flowers");
        if (catLower == "foliage") return Cat("foliage") ?? Cat("flowers");
        if (catLower == "packing") return Cat("packing") ?? Cat("supplies");
        if (catLower == "accessories") return Cat("accessories") ?? Cat("supplies");

        if (catLower == "finished products")
        {
            if (nameLower.Contains("bamboo") || nameLower.Contains("lily") || nameLower.Contains("plant") || nameLower.Contains("succulent"))
                return Cat("plants") ?? Cat("finished-products");
            if (nameLower.Contains("rocher") || nameLower.Contains("cadbury") || nameLower.Contains("chocolate") || nameLower.Contains("celebrations"))
                return Cat("chocolate") ?? Cat("finished-products");
            if (nameLower.Contains("cake"))
                return Cat("cakes") ?? Cat("finished-products");
            if (nameLower.Contains("teddy") || nameLower.Contains("toy"))
                return Cat("gifts") ?? Cat("finished-products");
            return Cat("finished-products");
        }

        return Cat("flowers");
    }

    private static UnitOfMeasure MapUnitOfMeasure(string unit)
    {
        return unit.Trim().ToLowerInvariant() switch
        {
            "stem" => UnitOfMeasure.Stem,
            "bunch" => UnitOfMeasure.Bunch,
            "piece" => UnitOfMeasure.Piece,
            "roll" => UnitOfMeasure.Roll,
            "packet" or "pack" => UnitOfMeasure.Pack,
            "pot" => UnitOfMeasure.Piece,
            "box" => UnitOfMeasure.Box,
            "meter" => UnitOfMeasure.Meter,
            _ => UnitOfMeasure.Piece
        };
    }

    private static ProductType MapProductType(CanonicalStarterProduct item)
    {
        var cat = item.Category.Trim().ToLowerInvariant();
        var name = item.Name.Trim().ToLowerInvariant();

        if (cat is "flowers" or "fillers" or "foliage")
            return ProductType.SingleFlower;

        if (cat is "packing" or "accessories")
            return ProductType.Accessory;

        if (cat == "finished products")
        {
            if (name.Contains("plant") || name.Contains("bamboo") || name.Contains("succulent"))
                return ProductType.Plant;
            if (name.Contains("bouquet"))
                return ProductType.Bouquet;
            if (name.Contains("arrangement") || name.Contains("basket") || name.Contains("vase"))
                return ProductType.Arrangement;
            return ProductType.Gift;
        }

        return ProductType.SingleFlower;
    }

    private static string GenerateStandardSku(CanonicalStarterProduct item)
    {
        var raw = Regex.Replace(item.Name.ToUpperInvariant(), @"[^A-Z0-9]+", "-").Trim('-');
        var parts = raw.Split('-', StringSplitOptions.RemoveEmptyEntries);
        var shortCode = string.Join("-", parts.Take(4));
        return shortCode.Length > 30 ? shortCode[..30].TrimEnd('-') : shortCode;
    }

    private static string GenerateSlug(string name)
    {
        var slug = Regex.Replace(name.ToLowerInvariant(), @"[^a-z0-9]+", "-").Trim('-');
        return string.IsNullOrWhiteSpace(slug) ? "product" : slug;
    }

    private static string GenerateKeywords(CanonicalStarterProduct item)
    {
        var terms = new List<string> { item.Name.ToLowerInvariant(), item.Category.ToLowerInvariant() };
        var nameParts = item.Name.ToLowerInvariant().Split(new[] { ' ', '-', '(', ')' }, StringSplitOptions.RemoveEmptyEntries);
        terms.AddRange(nameParts);
        return string.Join(", ", terms.Distinct());
    }

    private static async Task EnsureFestivalsAsync(SumpoojDbContext db, LibrarySeedResult result)
    {
        var festivals = new (string Name, string Slug, int Month, int Day, string Description, string FlowerDemands, int SortOrder)[]
        {
            ("New Year's Day", "new-year", 1, 1, "Global New Year celebration. High demand for party bouquets, carnations, roses and mixed hampers.", "Roses, Carnations, Lilies, Orchids", 1),
            ("Makar Sankranti & Pongal", "makar-sankranti", 1, 14, "Harvest and sun festival. Traditional floral offerings, yellow and orange marigold garlands.", "Marigold, Chrysanthemums, Jasmine", 2),
            ("Republic Day", "republic-day", 1, 26, "National celebration. Tri-color floral arrangements for corporate and government ceremonies.", "Orange Marigold, White Carnations, Green Chrysanthemums", 3),
            ("Rose Day", "rose-day", 2, 7, "First day of Valentine's week. Peak demand for fresh cut long-stem red, pink, yellow, and white roses.", "Dutch Roses, Spray Roses, Rose Bouquets", 4),
            ("Valentine's Day", "valentines-day", 2, 14, "Highest volume single-day flower gifting event of the year. Premium red roses, luxury boxes and teddy combos.", "Red Roses, Asiatic Lilies, Gypsophila, Hydrangea", 5),
            ("Maha Shivratri", "maha-shivratri", 2, 26, "Auspicious Hindu festival dedicated to Lord Shiva. Bael patra, datura, white flowers and garlands.", "White Lilies, Chrysanthemums, Marigold, Lotus", 6),
            ("International Women's Day", "womens-day", 3, 8, "Corporate and personal gifting honoring women. Purple, pink and pastel bouquets.", "Pink Roses, Purple Orchids, Carnations, Tulips", 7),
            ("Holi (Festival of Colors)", "holi", 3, 14, "Spring festival. Floral gulal, vibrant multi-colored floral baskets and home centerpieces.", "Yellow Marigold, Gerberas, Bright Carnations", 8),
            ("Gudi Padwa & Ugadi", "gudi-padwa-ugadi", 3, 30, "Hindu Lunar New Year in Maharashtra and South India. Mango leaves, neem flowers and marigold torans.", "Marigold Torans, Jasmine Strings, Red Roses", 9),
            ("Easter Sunday", "easter", 4, 20, "Christian spring resurrection celebration. White lilies and pastel seasonal blooms.", "White Lilies, Daisies, Pastel Carnations", 10),
            ("Mother's Day", "mothers-day", 5, 10, "Top global flower gifting occasion. Carnations, pink roses, orchids, and personalized gift tags.", "Pink Carnations, Orchids, Lilies, Sweet Avalanche Roses", 11),
            ("Father's Day", "fathers-day", 6, 21, "Celebration honoring fathers and father figures. Tropical arrangements and elegant indoor plants.", "Anthuriums, Peace Lily, Bamboo, Blue Orchids", 12),
            ("Guru Purnima", "guru-purnima", 7, 29, "Day of gratitude to spiritual masters and teachers. Floral malas and yellow bouquets.", "Yellow Roses, Marigold Malas, Carnations", 13),
            ("Friendship Day", "friendship-day", 8, 2, "Celebration of friendship. Yellow roses, mixed gerbera bunches and flower bracelets.", "Yellow Roses, Colorful Gerberas, Statice", 14),
            ("Independence Day", "independence-day", 8, 15, "National independence anniversary. Tri-color stage decorations and flag-theme wreaths.", "Saffron Marigold, White Gladiolus, Green Foliage", 15),
            ("Raksha Bandhan", "raksha-bandhan", 8, 28, "Celebration of sibling bonds. Floral rakhis, sweets combos and celebratory bouquets.", "Roses, Orchids, Carnations, Floral Rakhis", 16),
            ("Janmashtami", "janmashtami", 9, 4, "Birth celebration of Lord Krishna. Elaborate temple floral jhulas and peacock-hued arrangements.", "Blue Orchids, Lotus, Jasmine, Marigold Jhulas", 17),
            ("Teacher's Day", "teachers-day", 9, 5, "Honoring teachers and educators. Single rose stems, carnation bouquets and table pots.", "Single Dutch Roses, Carnations, Orchids", 18),
            ("Ganesh Chaturthi", "ganesh-chaturthi", 9, 14, "10-day festival honoring Lord Ganesha. Huge demand for Hibiscus, Durva grass, and daily fresh marigold garlands.", "Red Hibiscus, Marigold, Chrysanthemums, Lotus", 19),
            ("Navratri Ghatasthapana", "navratri", 10, 11, "Nine nights of divine feminine energy. Daily floral mandap decoration and fresh pooja flowers.", "Red Roses, Yellow Marigold, Shewanti, Jasmine", 20),
            ("Dussehra / Vijayadashami", "dussehra", 10, 20, "Victory of good over evil. Vehicle marigold garlands, office doorway torans, and festive marigold blooms.", "Orange/Yellow Marigold, Apta leaves, Mango Torans", 21),
            ("Karwa Chauth", "karwa-chauth", 10, 29, "Traditional celebration of marital love. Red rose bouquets, sargi floral hampers and pooja thali florals.", "Premium Red Roses, Red Carnations, Jasmine Gajras", 22),
            ("Dhanteras", "dhanteras", 11, 7, "Auspicious beginning of Diwali. Doorstep floral rangolis and auspicious marigold/lotus arrangements.", "Lotus, Marigold, Golden Chrysanthemums", 23),
            ("Diwali (Festival of Lights)", "diwali", 11, 9, "Largest festival of lights and gifting in India. Bulk marigold, corporate hampers, and door torans.", "Marigold Garlands, Lotus, Luxury Mixed Hampers", 24),
            ("Bhai Dooj", "bhai-dooj", 11, 11, "Culmination of Diwali honoring brother-sister bond. Gift bouquets and flower-sweet hampers.", "Roses, Lilies, Carnations", 25),
            ("Tulsi Vivah (Wedding Season Start)", "tulsi-vivah", 11, 21, "Ceremonial marriage of Tulsi plant marking the official opening of the Hindu wedding season.", "Sugarcane, Marigold, Lotus, Mango Leaves", 26),
            ("Christmas Eve & Day", "christmas", 12, 25, "Global Christmas celebration. Poinsettias, pine wreaths, red and white roses, and festive centerpieces.", "Poinsettias, Red Roses, White Lilies, Pine Greens", 27),
            ("New Year's Eve", "new-years-eve", 12, 31, "Year-end party arrangements, countdown bouquets, and midnight delivery arrangements.", "Luxury Roses, Orchids, Lilies, Champagne Florals", 28)
        };

        var currentYear = DateTime.UtcNow.Year;
        foreach (var (name, slug, month, day, desc, flowers, sortOrder) in festivals)
        {
            var date = new DateTime(currentYear, month, day, 0, 0, 0, DateTimeKind.Utc);
            var existing = await db.LibraryFestivals.FirstOrDefaultAsync(f => f.Slug == slug);
            if (existing == null)
            {
                var fest = new LibraryFestival(
                    name: name,
                    slug: slug,
                    festivalDate: date,
                    month: month,
                    day: day,
                    description: desc,
                    isRecurring: true,
                    flowerDemands: flowers,
                    searchKeywords: $"{name}, {flowers}, festival, florist calendar",
                    imageUrl: null,
                    sortOrder: sortOrder);
                db.LibraryFestivals.Add(fest);
                result.FestivalsCreated++;
            }
            else
            {
                existing.Update(
                    name: name,
                    slug: slug,
                    festivalDate: date,
                    month: month,
                    day: day,
                    description: desc,
                    isRecurring: true,
                    flowerDemands: flowers,
                    searchKeywords: $"{name}, {flowers}, festival, florist calendar",
                    imageUrl: existing.ImageUrl,
                    sortOrder: sortOrder);
                result.FestivalsRetained++;
            }
        }
    }

    private static async Task EnsureWeddingDatesAsync(SumpoojDbContext db, LibrarySeedResult result)
    {
        var muhurats = new (string Title, string Slug, int Year, int Month, int Day, string Tithi, string Nakshatra, string Season, string Demand, string Notes, int SortOrder)[]
        {
            // Winter 2026 Season (Magh / Phalgun)
            ("Shubh Vivah Muhurat - Jan 18", "wedding-2026-01-18", 2026, 1, 18, "Amavasya / Pratipada", "Uttara Ashadha", "Winter", "High", "High demand for winter wedding mandaps, red roses and baby's breath.", 1),
            ("Shubh Vivah Muhurat - Jan 22", "wedding-2026-01-22", 2026, 1, 22, "Panchami", "Revati", "Winter", "Peak", "Peak weekend wedding date across major banquet venues.", 2),
            ("Shubh Vivah Muhurat - Jan 29", "wedding-2026-01-29", 2026, 1, 29, "Dwadashi", "Rohini", "Winter", "High", "Auspicious Rohini Nakshatra vivah muhurat.", 3),
            ("Shubh Vivah Muhurat - Feb 5", "wedding-2026-02-05", 2026, 2, 5, "Chaturthi", "Hasta", "Winter", "High", "Early February wedding date preceding Valentine week rush.", 4),
            ("Shubh Vivah Muhurat - Feb 11", "wedding-2026-02-11", 2026, 2, 11, "Navami", "Anuradha", "Winter", "Peak", "Massive demand coinciding with Valentine's season floral procurement.", 5),
            ("Shubh Vivah Muhurat - Feb 18", "wedding-2026-02-18", 2026, 2, 18, "Dwitiya", "Uttara Bhadrapada", "Winter", "High", "Auspicious post-Valentine vivah muhurat.", 6),
            ("Shubh Vivah Muhurat - Feb 24", "wedding-2026-02-24", 2026, 2, 24, "Ashtami", "Rohini", "Winter", "High", "Final high-volume winter lagna date before Holi.", 7),

            // Spring / Summer 2026 Season (Chaitra / Baisakh / Jyeshtha)
            ("Shubh Vivah Muhurat - Apr 18", "wedding-2026-04-18", 2026, 4, 18, "Shukla Pratipada", "Rohini", "Spring", "High", "Opening of spring Baisakh lagna season. High demand for pastel florals.", 8),
            ("Shubh Vivah Muhurat - Apr 22", "wedding-2026-04-22", 2026, 4, 22, "Shukla Panchami", "Mrigashirsha", "Spring", "High", "Auspicious mid-week wedding date with high varmala demand.", 9),
            ("Shubh Vivah Muhurat - Apr 28", "wedding-2026-04-28", 2026, 4, 28, "Shukla Ekadashi", "Uttara Phalguni", "Spring", "Peak", "Mohini Ekadashi auspicious lagna muhurat. Peak floral volume.", 10),
            ("Shubh Vivah Muhurat - May 3", "wedding-2026-05-03", 2026, 5, 3, "Krishna Dwitiya", "Anuradha", "Spring", "Peak", "Peak May Sunday wedding date. Car decorations and stage setups.", 11),
            ("Shubh Vivah Muhurat - May 8", "wedding-2026-05-08", 2026, 5, 8, "Krishna Saptami", "Shravana", "Spring", "High", "High destination wedding booking date.", 12),
            ("Shubh Vivah Muhurat - May 14", "wedding-2026-05-14", 2026, 5, 14, "Krishna Trayodashi", "Revati", "Spring", "High", "Auspicious Revati Nakshatra muhurat.", 13),
            ("Shubh Vivah Muhurat - May 21", "wedding-2026-05-21", 2026, 5, 21, "Shukla Panchami", "Pushya", "Spring", "Peak", "Pushya Nakshatra auspicious vivah date.", 14),
            ("Shubh Vivah Muhurat - Jun 2", "wedding-2026-06-02", 2026, 6, 2, "Krishna Dwitiya", "Mula", "Summer", "High", "Early summer wedding muhurat.", 15),
            ("Shubh Vivah Muhurat - Jun 10", "wedding-2026-06-10", 2026, 6, 10, "Krishna Dashami", "Uttara Ashadha", "Summer", "High", "Final summer lagna muhurat before monsoon Chaturmas.", 16),

            // Autumn / Winter 2026 Peak Season (Dev Uthani / Margashirsha)
            ("Shubh Vivah Muhurat - Nov 21", "wedding-2026-11-21", 2026, 11, 21, "Dev Uthani Ekadashi", "Uttara Bhadrapada", "Autumn", "Peak", "Official grand opening of winter wedding season. Historic peak in flower prices.", 17),
            ("Shubh Vivah Muhurat - Nov 24", "wedding-2026-11-24", 2026, 11, 24, "Purnima", "Rohini", "Autumn", "Peak", "Kartik Purnima auspicious wedding date.", 18),
            ("Shubh Vivah Muhurat - Nov 28", "wedding-2026-11-28", 2026, 11, 28, "Krishna Chaturthi", "Punarvasu", "Autumn", "High", "High volume weekend reception date.", 19),
            ("Shubh Vivah Muhurat - Dec 3", "wedding-2026-12-03", 2026, 12, 3, "Krishna Dashami", "Hasta", "Winter", "Peak", "Peak December wedding date.", 20),
            ("Shubh Vivah Muhurat - Dec 7", "wedding-2026-12-07", 2026, 12, 7, "Krishna Trayodashi", "Anuradha", "Winter", "High", "Major pre-Christmas wedding date.", 21),
            ("Shubh Vivah Muhurat - Dec 11", "wedding-2026-12-11", 2026, 12, 11, "Shukla Dwitiya", "Mula", "Winter", "High", "Final auspicious wedding muhurat of 2026 before Dhanu Sankranti.", 22),

            // Early 2027 Muhurats
            ("Shubh Vivah Muhurat - Jan 17", "wedding-2027-01-17", 2027, 1, 17, "Shukla Dashami", "Rohini", "Winter", "Peak", "Opening of 2027 winter wedding season post Makar Sankranti.", 23),
            ("Shubh Vivah Muhurat - Jan 21", "wedding-2027-01-21", 2027, 1, 21, "Shukla Chaturdashi", "Punarvasu", "Winter", "High", "High demand banquet hall wedding date.", 24),
            ("Shubh Vivah Muhurat - Jan 26", "wedding-2027-01-26", 2027, 1, 26, "Krishna Panchami", "Uttara Phalguni", "Winter", "High", "Republic Day long weekend wedding celebrations.", 25),
            ("Shubh Vivah Muhurat - Feb 4", "wedding-2027-02-04", 2027, 2, 4, "Krishna Trayodashi", "Uttara Ashadha", "Winter", "High", "Early February wedding muhurat.", 26),
            ("Shubh Vivah Muhurat - Feb 10", "wedding-2027-02-10", 2027, 2, 10, "Shukla Chaturthi", "Revati", "Winter", "Peak", "Peak wedding date in Valentine's week 2027.", 27),
            ("Shubh Vivah Muhurat - Feb 15", "wedding-2027-02-15", 2027, 2, 15, "Shukla Navami", "Rohini", "Winter", "High", "Auspicious post-Valentine lagna muhurat.", 28)
        };

        foreach (var (title, slug, year, month, day, tithi, nakshatra, season, demand, notes, sortOrder) in muhurats)
        {
            var date = new DateTime(year, month, day, 0, 0, 0, DateTimeKind.Utc);
            var existing = await db.LibraryWeddingDates.FirstOrDefaultAsync(w => w.Slug == slug);
            if (existing == null)
            {
                var wedding = new LibraryWeddingDate(
                    title: title,
                    slug: slug,
                    weddingDate: date,
                    tithi: tithi,
                    nakshatra: nakshatra,
                    notes: notes,
                    season: season,
                    demandLevel: demand,
                    searchKeywords: $"{title}, {tithi}, {nakshatra}, {season}, wedding, muhurat, vivah",
                    sortOrder: sortOrder);
                db.LibraryWeddingDates.Add(wedding);
                result.WeddingDatesCreated++;
            }
            else
            {
                existing.Update(
                    title: title,
                    slug: slug,
                    weddingDate: date,
                    tithi: tithi,
                    nakshatra: nakshatra,
                    notes: notes,
                    season: season,
                    demandLevel: demand,
                    searchKeywords: $"{title}, {tithi}, {nakshatra}, {season}, wedding, muhurat, vivah",
                    sortOrder: sortOrder);
                result.WeddingDatesRetained++;
            }
        }
    }
}

public class CanonicalStarterProduct
{
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string DefaultUnit { get; set; } = "Piece";
    public int SellingPricePaise { get; set; }
    public int? PurchasePricePaise { get; set; }
    public int GstPercent { get; set; } = 12;
    public string ManufacturerBarcode { get; set; } = string.Empty;
    public bool TrackInventory { get; set; } = true;
    public int MinStock { get; set; } = 5;
    public string Supplier { get; set; } = string.Empty;
}

public class LibrarySeedResult
{
    public int CategoriesCreated { get; set; }
    public int ProductsCreated { get; set; }
    public int ProductsReconciled { get; set; }
    public int ProductsRetainedUnchanged { get; set; }
    public int ProductsRetainedNonSolo { get; set; }
    public int FestivalsCreated { get; set; }
    public int FestivalsRetained { get; set; }
    public int WeddingDatesCreated { get; set; }
    public int WeddingDatesRetained { get; set; }
}

