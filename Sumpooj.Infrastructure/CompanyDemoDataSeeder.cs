using Microsoft.EntityFrameworkCore;
using Sumpooj.Domain.Entities;
using Sumpooj.Infrastructure.Persistence;

namespace Sumpooj.Infrastructure;

/// <summary>
/// Populates ~5 realistic demo records in each major table for a given company.
/// Skips tables that already have data for that company (idempotent).
/// Used by Platform Super Admin to make a tenant portal look realistic for demos.
/// </summary>
public static class CompanyDemoDataSeeder
{
    public static async Task<DemoSeedResult> SeedAsync(SumpoojDbContext db, Guid companyId)
    {
        var company = await db.Companies.FindAsync(companyId)
            ?? throw new InvalidOperationException("Company not found");

        var result = new DemoSeedResult();

        result.Locations = await SeedLocationsAsync(db, companyId);
        result.TaxRules = await SeedTaxRulesAsync(db, companyId);
        result.Categories = await SeedCategoriesAsync(db, companyId);
        result.Suppliers = await SeedSuppliersAsync(db, companyId);
        result.Products = await SeedProductsAsync(db, companyId);
        result.Customers = await SeedCustomersAsync(db, companyId);
        result.Staff = await SeedStaffAsync(db, companyId);
        result.Accounts = await SeedAccountsAsync(db, companyId);
        result.Expenses = await SeedExpensesAsync(db, companyId);
        result.Orders = await SeedOrdersAsync(db, companyId);
        result.Events = await SeedEventsAsync(db, companyId);
        result.Recipes = await SeedRecipesAsync(db, companyId);
        result.DeliveryZones = await SeedDeliveryZonesAsync(db, companyId);

        return result;
    }

    /// <summary>
    /// Removes ALL company data from every major table (child rows first, then parents).
    /// Used when a demo company goes live and needs a clean slate.
    /// The Company row itself is NOT deleted — only its data.
    /// </summary>
    public static async Task<DemoPurgeResult> PurgeAsync(SumpoojDbContext db, Guid companyId)
    {
        _ = await db.Companies.FindAsync(companyId)
            ?? throw new InvalidOperationException("Company not found");

        var result = new DemoPurgeResult();

        // ── Child / junction tables first (FK dependencies) ─────

        // Order children
        var orderIds = await db.Orders.Where(o => o.CompanyId == companyId).Select(o => o.Id).ToListAsync();
        if (orderIds.Count > 0)
        {
            result.OrderItems = await RemoveAsync(db, db.OrderItems.Where(i => orderIds.Contains(EF.Property<Guid>(i, "OrderId"))));
            result.Payments = await RemoveAsync(db, db.Payments.Where(p => orderIds.Contains(p.OrderId)));
        }

        // Production children
        var recipeIds = await db.FloralRecipes.Where(r => r.CompanyId == companyId).Select(r => r.Id).ToListAsync();
        if (recipeIds.Count > 0)
            result.RecipeComponents = await RemoveAsync(db, db.RecipeComponents.Where(c => recipeIds.Contains(c.RecipeId)));

        // Proposal children
        var proposalIds = await db.Proposals.Where(p => p.CompanyId == companyId).Select(p => p.Id).ToListAsync();
        if (proposalIds.Count > 0)
            result.ProposalItems = await RemoveAsync(db, db.ProposalItems.Where(i => proposalIds.Contains(i.ProposalId)));

        // PurchaseOrder children
        var poIds = await db.PurchaseOrders.Where(p => p.CompanyId == companyId).Select(p => p.Id).ToListAsync();
        if (poIds.Count > 0)
            result.PurchaseOrderItems = await RemoveAsync(db, db.PurchaseOrderItems.Where(i => poIds.Contains(EF.Property<Guid>(i, "PurchaseOrderId"))));

        // ── Parent tables ───────────────────────────────────────

        result.Orders = await RemoveAsync(db, db.Orders.Where(o => o.CompanyId == companyId));
        result.Events = await RemoveAsync(db, db.Events.Where(e => e.CompanyId == companyId));
        result.Proposals = await RemoveAsync(db, db.Proposals.Where(p => p.CompanyId == companyId));
        result.WireOrders = await RemoveAsync(db, db.WireOrders.Where(w => w.CompanyId == companyId));
        result.Recipes = await RemoveAsync(db, db.FloralRecipes.Where(r => r.CompanyId == companyId));
        result.FinishedGoods = await RemoveAsync(db, db.FinishedGoodsBatches.Where(f => f.CompanyId == companyId));
        result.ProductionJobs = await RemoveAsync(db, db.ProductionJobs.Where(j => j.CompanyId == companyId));
        result.Expenses = await RemoveAsync(db, db.Expenses.Where(e => e.CompanyId == companyId));
        result.JournalEntries = await RemoveAsync(db, db.JournalEntries.Where(j => j.CompanyId == companyId));
        result.Accounts = await RemoveAsync(db, db.Accounts.Where(a => a.CompanyId == companyId));
        result.PurchaseOrders = await RemoveAsync(db, db.PurchaseOrders.Where(p => p.CompanyId == companyId));
        result.StockMovements = await RemoveAsync(db, db.StockMovements.Where(s => s.CompanyId == companyId));
        result.ProductBatches = await RemoveAsync(db, db.ProductBatches.Where(b => b.CompanyId == companyId));
        result.Products = await RemoveAsync(db, db.Products.Where(p => p.CompanyId == companyId));
        result.Customers = await RemoveAsync(db, db.Customers.Where(c => c.CompanyId == companyId));
        result.Suppliers = await RemoveAsync(db, db.Suppliers.Where(s => s.CompanyId == companyId));
        result.Staff = await RemoveAsync(db, db.Staff.Where(s => s.CompanyId == companyId));
        result.Shifts = await RemoveAsync(db, db.Shifts.Where(s => s.CompanyId == companyId));
        result.DeliveryZones = await RemoveAsync(db, db.DeliveryZones.Where(z => z.CompanyId == companyId));
        result.Categories = await RemoveAsync(db, db.ProductCategories.Where(c => c.CompanyId == companyId));
        result.TaxRules = await RemoveAsync(db, db.TaxRules.Where(t => t.CompanyId == companyId));
        result.Locations = await RemoveAsync(db, db.Locations.Where(l => l.CompanyId == companyId));

        return result;
    }

    /// <summary>Batch-remove all matching rows and return the count deleted.</summary>
    private static async Task<int> RemoveAsync<T>(SumpoojDbContext db, IQueryable<T> query) where T : class
    {
        var items = await query.ToListAsync();
        if (items.Count == 0) return 0;
        db.RemoveRange(items);
        await db.SaveChangesAsync();
        return items.Count;
    }

    // ─── Locations ──────────────────────────────────────────

    private static async Task<int> SeedLocationsAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Locations.AnyAsync(l => l.CompanyId == cid)) return 0;

        var items = new[]
        {
            new Location(cid, "Main Store", "MAIN-01", LocationType.Store, "123 Flower Street, Downtown"),
            new Location(cid, "Workshop", "WORK-01", LocationType.Workshop, "45 Industrial Road"),
            new Location(cid, "Cold Storage", "COLD-01", LocationType.ColdRoom, "45 Industrial Road, Unit B"),
            new Location(cid, "Display Cooler Front", "DISP-01", LocationType.DisplayCooler, "123 Flower Street"),
            new Location(cid, "Warehouse", "WH-01", LocationType.Warehouse, "78 Commerce Park"),
        };
        items[0].SetAsDefault();
        db.Locations.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Tax Rules ──────────────────────────────────────────

    private static async Task<int> SeedTaxRulesAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.TaxRules.AnyAsync(t => t.CompanyId == cid)) return 0;

        var items = new[]
        {
            new TaxRule(cid, "IN", "GST 18%", 18m, false),
            new TaxRule(cid, "IN", "GST 12%", 12m, false),
            new TaxRule(cid, "IN", "GST 5%", 5m, false),
            new TaxRule(cid, "IN", "Exempt", 0m, false),
        };
        db.TaxRules.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Categories ─────────────────────────────────────────

    private static async Task<int> SeedCategoriesAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.ProductCategories.AnyAsync(c => c.CompanyId == cid)) return 0;

        var items = new[]
        {
            new ProductCategoryEntity(cid, "Fresh Flowers", true, true),
            new ProductCategoryEntity(cid, "Bouquets & Arrangements", true, false),
            new ProductCategoryEntity(cid, "Plants & Succulents", false, false),
            new ProductCategoryEntity(cid, "Vases & Containers", false, false),
            new ProductCategoryEntity(cid, "Gift Items", false, false),
        };
        db.ProductCategories.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Suppliers ──────────────────────────────────────────

    private static async Task<int> SeedSuppliersAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Suppliers.AnyAsync(s => s.CompanyId == cid)) return 0;

        var s1 = new Supplier(cid, "Flora Farms India", "Rajesh Kumar", "rajesh@florafarms.com", "+91-98765-43210", "Ooty, Tamil Nadu");
        s1.SetPaymentTerms(30); s1.SetRating(SupplierRating.Excellent);
        var s2 = new Supplier(cid, "Bangalore Blooms", "Priya Sharma", "priya@bangaloreblooms.in", "+91-91234-56789", "Bangalore");
        s2.SetPaymentTerms(15); s2.SetRating(SupplierRating.Good);
        var s3 = new Supplier(cid, "Dutch Flower Imports", "Hans Van Berg", "hans@dutchflowers.com", "+31-20-555-1234", "Aalsmeer, Netherlands");
        s3.SetPaymentTerms(45); s3.SetRating(SupplierRating.Excellent);
        var s4 = new Supplier(cid, "Green Valley Nursery", "Meena Gupta", "meena@greenvalley.in", "+91-80-4567-8901", "Pune");
        s4.SetPaymentTerms(20); s4.SetRating(SupplierRating.Good);
        var s5 = new Supplier(cid, "Pacific Orchids", "David Chen", "david@pacificorchids.com", "+65-9876-5432", "Singapore");
        s5.SetPaymentTerms(30); s5.SetRating(SupplierRating.Fair);

        db.Suppliers.AddRange(s1, s2, s3, s4, s5);
        await db.SaveChangesAsync();
        return 5;
    }

    // ─── Products ───────────────────────────────────────────

    private static async Task<int> SeedProductsAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Products.AnyAsync(p => p.CompanyId == cid)) return 0;

        var products = new[]
        {
            new Product(cid, "Red Roses (Premium)", "ROSE-RED-001", ProductType.SingleFlower, ProductCategory.Roses, 60m, 25m, "Long-stem premium red roses"),
            new Product(cid, "White Lilies", "LILY-WHT-001", ProductType.SingleFlower, ProductCategory.Lilies, 120m, 45m, "Fragrant white oriental lilies"),
            new Product(cid, "Gerbera Daisies Mix", "GERB-MIX-001", ProductType.SingleFlower, ProductCategory.MixedFlowers, 40m, 15m, "Colorful gerbera mix"),
            new Product(cid, "Romantic Rose Bouquet", "BQ-ROM-001", ProductType.Bouquet, ProductCategory.Roses, 1999m, 800m, "24 premium roses with baby's breath"),
            new Product(cid, "Sunshine Mixed Bouquet", "BQ-SUN-001", ProductType.Bouquet, ProductCategory.MixedFlowers, 1499m, 600m, "Gerberas, lilies and roses"),
            new Product(cid, "White Sympathy Arrangement", "ARR-SYM-001", ProductType.Arrangement, ProductCategory.SymPathyFlowers, 2999m, 1200m, "Elegant white lilies and roses"),
            new Product(cid, "Crystal Glass Vase", "VASE-CRY-001", ProductType.Accessory, ProductCategory.Vases, 599m, 200m, "Elegant crystal glass vase, 25cm"),
            new Product(cid, "Premium Chocolate Box", "CHOC-PRM-001", ProductType.Gift, ProductCategory.ChocolatesAndGifts, 699m, 300m, "Assorted premium chocolates, 250g"),
            new Product(cid, "Orchid Phalaenopsis", "ORCH-PHA-001", ProductType.Plant, ProductCategory.Orchids, 550m, 280m, "White phalaenopsis orchid in ceramic pot"),
            new Product(cid, "Baby's Breath Bundle", "GYPS-BDL-001", ProductType.SingleFlower, ProductCategory.MixedFlowers, 80m, 30m, "Gypsophila filler bundle"),
        };
        db.Products.AddRange(products);
        await db.SaveChangesAsync();
        return products.Length;
    }

    // ─── Customers ──────────────────────────────────────────

    private static async Task<int> SeedCustomersAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Customers.AnyAsync(c => c.CompanyId == cid)) return 0;

        var c1 = new Customer(cid, "Amit Sharma", "amit.sharma@gmail.com", "+91-98765-43210");
        c1.UpdateDefaultCardMessage("With love and best wishes!");
        var c2 = new Customer(cid, "Priya Patel", "priya.patel@outlook.com", "+91-91234-56789");
        c2.UpdateDefaultCardMessage("Thinking of you always!");
        var c3 = new Customer(cid, "Raj Enterprises Ltd", "procurement@rajent.com", "+91-22-2654-3210");
        c3.UpdateDefaultCardMessage("Corporate Greetings from Raj Enterprises");
        var c4 = new Customer(cid, "Meera Singh", "meera.singh@yahoo.com", "+91-96543-21098");
        var c5 = new Customer(cid, "Taj Hotel Mumbai", "events@tajhotels.com", "+91-22-6654-3210");
        c5.UpdateDefaultCardMessage("With Compliments from The Taj");

        db.Customers.AddRange(c1, c2, c3, c4, c5);
        await db.SaveChangesAsync();
        return 5;
    }

    // ─── Staff ──────────────────────────────────────────────

    private static async Task<int> SeedStaffAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Staff.AnyAsync(s => s.CompanyId == cid)) return 0;

        var loc = await db.Locations.FirstOrDefaultAsync(l => l.CompanyId == cid && l.IsDefault);

        var st1 = new Staff(cid, "Vikram Patel", StaffRole.Designer, "vikram@demo.com", "+91-98765-00001", null);
        st1.SetCommission(CommissionType.Revenue, 5m); st1.SetHourlyRate(500m); st1.AssignLocation(loc?.Id);
        var st2 = new Staff(cid, "Anita Desai", StaffRole.Cashier, "anita@demo.com", "+91-98765-00002", null);
        st2.SetCommission(CommissionType.Revenue, 3m); st2.SetHourlyRate(400m); st2.AssignLocation(loc?.Id);
        var st3 = new Staff(cid, "Ramesh Kumar", StaffRole.Driver, "ramesh@demo.com", "+91-98765-00003", null);
        st3.SetHourlyRate(300m); st3.AssignLocation(loc?.Id);
        var st4 = new Staff(cid, "Sunita Reddy", StaffRole.Designer, "sunita@demo.com", "+91-98765-00004", null);
        st4.SetCommission(CommissionType.Revenue, 5m); st4.SetHourlyRate(500m); st4.AssignLocation(loc?.Id);
        var st5 = new Staff(cid, "Arjun Nair", StaffRole.Manager, "arjun@demo.com", "+91-98765-00005", null);
        st5.SetHourlyRate(600m); st5.AssignLocation(loc?.Id);

        db.Staff.AddRange(st1, st2, st3, st4, st5);
        await db.SaveChangesAsync();
        return 5;
    }

    // ─── Chart of Accounts ──────────────────────────────────

    private static async Task<int> SeedAccountsAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Accounts.AnyAsync(a => a.CompanyId == cid)) return 0;

        var items = new[]
        {
            new Account(cid, "1000", "Cash", "Asset"),
            new Account(cid, "1200", "Inventory", "Asset"),
            new Account(cid, "2100", "Tax Payable", "Liability"),
            new Account(cid, "4000", "Sales Revenue", "Income"),
            new Account(cid, "5000", "Cost of Goods Sold", "Expense"),
        };
        db.Accounts.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Expenses ───────────────────────────────────────────

    private static async Task<int> SeedExpensesAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Expenses.AnyAsync(e => e.CompanyId == cid)) return 0;

        var today = DateTime.UtcNow;
        var items = new[]
        {
            new Expense(cid, "Rent", 25000m, "Monthly shop rent – Main Store", today.AddDays(-5)),
            new Expense(cid, "Utilities", 4500m, "Electricity + water bill", today.AddDays(-3)),
            new Expense(cid, "Fuel", 3200m, "Delivery vehicle fuel", today.AddDays(-2)),
            new Expense(cid, "Packaging", 6800m, "Gift wrapping, boxes, ribbons", today.AddDays(-1)),
            new Expense(cid, "Marketing", 8000m, "Instagram ads + Google local", today),
        };
        db.Expenses.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Orders ─────────────────────────────────────────────

    private static async Task<int> SeedOrdersAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Orders.AnyAsync(o => o.CompanyId == cid)) return 0;

        var customers = await db.Customers.Where(c => c.CompanyId == cid).Take(5).ToListAsync();
        var products = await db.Products.Where(p => p.CompanyId == cid).Take(5).ToListAsync();
        if (customers.Count == 0 || products.Count == 0) return 0;

        var today = DateTime.UtcNow;
        var count = 0;
        var addresses = new[] {
            "12 MG Road, Bandra West",
            "45 Link Road, Andheri",
            "78 Marine Drive, Colaba",
            "23 Hill Road, Juhu",
            "56 FC Road, Pune"
        };

        for (int i = 0; i < Math.Min(5, customers.Count); i++)
        {
            var cust = customers[i];
            var prod = products[i % products.Count];
            var order = new Order(cid, cust.Id, today.AddDays(i + 1), addresses[i], null, cust.Name, null);
            order.AddItem(prod.Id, prod.Name, i + 1, prod.RetailPrice);
            order.SetDeliveryFee(99m);

            if (i < 3) { order.Confirm(); order.MarkPaid(); }
            if (i == 3) order.Confirm();
            // i == 4 stays Pending

            db.Orders.Add(order);
            count++;
        }

        await db.SaveChangesAsync();
        return count;
    }

    // ─── Events ─────────────────────────────────────────────

    private static async Task<int> SeedEventsAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.Events.AnyAsync(e => e.CompanyId == cid)) return 0;

        var today = DateTime.UtcNow;
        var items = new[]
        {
            new Event(cid, "Sharma Wedding Reception", EventType.Wedding, today.AddDays(30), "Amit Sharma", "+91-98765-43210", "Grand Hyatt Mumbai"),
            new Event(cid, "Infosys Annual Gala", EventType.Corporate, today.AddDays(14), "HR Team", "+91-80-4567-8901", "Infosys Campus, Pune"),
            new Event(cid, "Birthday Party – Priya", EventType.Party, today.AddDays(7), "Priya Patel", "+91-91234-56789", "Priya's Residence, Bandra"),
            new Event(cid, "Memorial Service – Gupta", EventType.Funeral, today.AddDays(3), "Rahul Gupta", "+91-98123-45678", "Shanti Ashram, Juhu"),
            new Event(cid, "Product Launch – TechCorp", EventType.Corporate, today.AddDays(21), "Marketing Dept", "+91-22-3456-7890", "Taj Lands End, Bandra"),
        };

        items[0].SetEventDetails(200, 150000m, "Red & Gold", "Grand wedding reception with premium floral decor", null);
        items[1].SetEventDetails(150, 80000m, "White & Blue", "Corporate annual celebration", null);
        items[2].SetEventDetails(30, 25000m, "Pink & Purple", "Birthday garden party theme", null);
        items[4].SetEventDetails(100, 60000m, "Green & White", "Minimalist tech product launch", null);

        db.Events.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Recipes ────────────────────────────────────────────

    private static async Task<int> SeedRecipesAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.FloralRecipes.AnyAsync(r => r.CompanyId == cid)) return 0;

        var items = new[]
        {
            new FloralRecipe(cid, "Classic Red Rose Bouquet", "Bouquets", 1999m, 150m),
            new FloralRecipe(cid, "Spring Garden Arrangement", "Arrangements", 2499m, 200m),
            new FloralRecipe(cid, "Wedding Table Centerpiece", "Wedding", 3499m, 300m),
            new FloralRecipe(cid, "Sympathy Wreath – White", "Sympathy", 2999m, 250m),
            new FloralRecipe(cid, "Tropical Paradise Bouquet", "Bouquets", 1799m, 180m),
        };
        db.FloralRecipes.AddRange(items);
        await db.SaveChangesAsync();
        return items.Length;
    }

    // ─── Delivery Zones ─────────────────────────────────────

    private static async Task<int> SeedDeliveryZonesAsync(SumpoojDbContext db, Guid cid)
    {
        if (await db.DeliveryZones.AnyAsync(z => z.CompanyId == cid)) return 0;

        var z1 = new DeliveryZone(cid, "Zone A – Central", "ZONE-A", 99m, 30);
        z1.Update("Zone A – Central", "ZONE-A", "400001,400002,400050,400051", "Downtown,Bandra,Khar", 99m, 2000m, 149m, 249m, 30, null, 1, null);
        var z2 = new DeliveryZone(cid, "Zone B – Suburbs", "ZONE-B", 149m, 45);
        z2.Update("Zone B – Suburbs", "ZONE-B", "400049,400053,400058,400069", "Juhu,Andheri,Versova", 149m, 3000m, 199m, 299m, 45, null, 2, null);
        var z3 = new DeliveryZone(cid, "Zone C – Extended", "ZONE-C", 249m, 60);
        z3.Update("Zone C – Extended", "ZONE-C", "400601,400602,400603", "Navi Mumbai,Thane", 249m, 5000m, 349m, 449m, 60, null, 3, null);

        db.DeliveryZones.AddRange(z1, z2, z3);
        await db.SaveChangesAsync();
        return 3;
    }
}

/// <summary>Summary of how many records were seeded per table.</summary>
public class DemoSeedResult
{
    public int Locations { get; set; }
    public int TaxRules { get; set; }
    public int Categories { get; set; }
    public int Suppliers { get; set; }
    public int Products { get; set; }
    public int Customers { get; set; }
    public int Staff { get; set; }
    public int Accounts { get; set; }
    public int Expenses { get; set; }
    public int Orders { get; set; }
    public int Events { get; set; }
    public int Recipes { get; set; }
    public int DeliveryZones { get; set; }

    public int TotalSeeded => Locations + TaxRules + Categories + Suppliers + Products
        + Customers + Staff + Accounts + Expenses + Orders + Events + Recipes + DeliveryZones;
}

/// <summary>Summary of how many records were purged per table.</summary>
public class DemoPurgeResult
{
    // Child / junction
    public int OrderItems { get; set; }
    public int Payments { get; set; }
    public int RecipeComponents { get; set; }
    public int ProposalItems { get; set; }
    public int PurchaseOrderItems { get; set; }

    // Parent tables
    public int Locations { get; set; }
    public int TaxRules { get; set; }
    public int Categories { get; set; }
    public int Suppliers { get; set; }
    public int Products { get; set; }
    public int ProductBatches { get; set; }
    public int StockMovements { get; set; }
    public int Customers { get; set; }
    public int Staff { get; set; }
    public int Shifts { get; set; }
    public int Accounts { get; set; }
    public int Expenses { get; set; }
    public int JournalEntries { get; set; }
    public int Orders { get; set; }
    public int Events { get; set; }
    public int Proposals { get; set; }
    public int WireOrders { get; set; }
    public int PurchaseOrders { get; set; }
    public int Recipes { get; set; }
    public int FinishedGoods { get; set; }
    public int ProductionJobs { get; set; }
    public int DeliveryZones { get; set; }

    public int TotalPurged => OrderItems + Payments + RecipeComponents + ProposalItems + PurchaseOrderItems
        + Locations + TaxRules + Categories + Suppliers + Products + ProductBatches + StockMovements
        + Customers + Staff + Shifts + Accounts + Expenses + JournalEntries
        + Orders + Events + Proposals + WireOrders + PurchaseOrders
        + Recipes + FinishedGoods + ProductionJobs + DeliveryZones;
}
