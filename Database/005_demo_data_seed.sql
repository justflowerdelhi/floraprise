-- =====================================================
-- SUMPOOJ FLORIST ERP - Demo Data Seed Script
-- Run this AFTER schema creation scripts
-- =====================================================

-- =====================================================
-- DEMO COMPANY DATA
-- =====================================================

-- Demo Company (if not exists)
INSERT INTO "Companies" ("Id", "Name", "IsActive", "Region", "Email", "Phone", "Address", "ShortDescription", "TimeZone", "CurrencyCode", "TaxIdentifier", "CreatedAtUtc")
SELECT 
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Demo Florist',
    TRUE,
    'IN',
    'info@demoflorist.com',
    '+91-9999999999',
    '123 Flower Street, Bandra West, Mumbai, Maharashtra 400050',
    'Premium flower arrangements and gifts for all occasions',
    'Asia/Kolkata',
    'INR',
    'GSTIN27AADCD1234A1ZM',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Companies" WHERE "Id" = '11111111-1111-1111-1111-111111111111'::uuid);

-- USA Demo Company
INSERT INTO "Companies" ("Id", "Name", "IsActive", "Region", "Email", "Phone", "Address", "ShortDescription", "TimeZone", "CurrencyCode", "TaxIdentifier", "CreatedAtUtc")
SELECT 
    '22222222-2222-2222-2222-222222222222'::uuid,
    'Bloom & Petals NYC',
    TRUE,
    'US',
    'hello@bloompetalnyc.com',
    '+1-212-555-0123',
    '456 Madison Avenue, New York, NY 10022',
    'Luxury floral designs for Manhattan',
    'America/New_York',
    'USD',
    'EIN-12-3456789',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Companies" WHERE "Id" = '22222222-2222-2222-2222-222222222222'::uuid);

-- UAE Demo Company
INSERT INTO "Companies" ("Id", "Name", "IsActive", "Region", "Email", "Phone", "Address", "ShortDescription", "TimeZone", "CurrencyCode", "TaxIdentifier", "CreatedAtUtc")
SELECT 
    '33333333-3333-3333-3333-333333333333'::uuid,
    'Desert Rose Dubai',
    TRUE,
    'AE',
    'info@desertrosedubai.ae',
    '+971-4-555-1234',
    'Shop 101, Dubai Mall, Downtown Dubai',
    'Premium flowers and gifts in Dubai',
    'Asia/Dubai',
    'AED',
    'TRN-100123456789003',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Companies" WHERE "Id" = '33333333-3333-3333-3333-333333333333'::uuid);

-- =====================================================
-- LOCATIONS
-- =====================================================

-- Demo Florist Locations
INSERT INTO "Locations" ("Id", "CompanyId", "Name", "Code", "LocationType", "Address", "IsActive", "IsDefault", "CreatedAtUtc")
SELECT 
    'a1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Bandra Main Store',
    'BANDRA-01',
    0, -- Store
    '123 Flower Street, Bandra West, Mumbai 400050',
    TRUE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Locations" WHERE "Id" = 'a1111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Locations" ("Id", "CompanyId", "Name", "Code", "LocationType", "Address", "IsActive", "IsDefault", "CreatedAtUtc")
SELECT 
    'a1111111-1111-1111-1111-111111111112'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Andheri Warehouse',
    'ANDH-WH',
    1, -- Warehouse
    '45 Industrial Area, Andheri East, Mumbai 400069',
    TRUE,
    FALSE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Locations" WHERE "Id" = 'a1111111-1111-1111-1111-111111111112'::uuid);

INSERT INTO "Locations" ("Id", "CompanyId", "Name", "Code", "LocationType", "Address", "IsActive", "IsDefault", "CreatedAtUtc")
SELECT 
    'a1111111-1111-1111-1111-111111111113'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Juhu Outlet',
    'JUHU-01',
    0, -- Store
    '78 Beach Road, Juhu, Mumbai 400049',
    TRUE,
    FALSE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Locations" WHERE "Id" = 'a1111111-1111-1111-1111-111111111113'::uuid);

-- =====================================================
-- TAX RULES
-- =====================================================

-- India GST
INSERT INTO "tax_rules" ("Id", "CompanyId", "Name", "Rate", "CountryCode", "IsInclusive", "IsActive", "CreatedAtUtc")
SELECT 
    'b1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GST 18%',
    18.0000,
    'IN',
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "tax_rules" WHERE "Id" = 'b1111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "tax_rules" ("Id", "CompanyId", "Name", "Rate", "CountryCode", "IsInclusive", "IsActive", "CreatedAtUtc")
SELECT 
    'b1111111-1111-1111-1111-111111111112'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GST 12%',
    12.0000,
    'IN',
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "tax_rules" WHERE "Id" = 'b1111111-1111-1111-1111-111111111112'::uuid);

INSERT INTO "tax_rules" ("Id", "CompanyId", "Name", "Rate", "CountryCode", "IsInclusive", "IsActive", "CreatedAtUtc")
SELECT 
    'b1111111-1111-1111-1111-111111111113'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GST 5%',
    5.0000,
    'IN',
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "tax_rules" WHERE "Id" = 'b1111111-1111-1111-1111-111111111113'::uuid);

-- USA Tax
INSERT INTO "tax_rules" ("Id", "CompanyId", "Name", "Rate", "CountryCode", "IsInclusive", "IsActive", "CreatedAtUtc")
SELECT 
    'b2222222-2222-2222-2222-222222222221'::uuid,
    '22222222-2222-2222-2222-222222222222'::uuid,
    'NY State Tax',
    8.8750,
    'US',
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "tax_rules" WHERE "Id" = 'b2222222-2222-2222-2222-222222222221'::uuid);

-- UAE VAT
INSERT INTO "tax_rules" ("Id", "CompanyId", "Name", "Rate", "CountryCode", "IsInclusive", "IsActive", "CreatedAtUtc")
SELECT 
    'b3333333-3333-3333-3333-333333333331'::uuid,
    '33333333-3333-3333-3333-333333333333'::uuid,
    'UAE VAT 5%',
    5.0000,
    'AE',
    TRUE, -- UAE VAT is typically inclusive
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "tax_rules" WHERE "Id" = 'b3333333-3333-3333-3333-333333333331'::uuid);

-- =====================================================
-- PRODUCT CATEGORIES
-- =====================================================

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Fresh Flowers',
    TRUE,
    TRUE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111112'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Bouquets & Arrangements',
    TRUE,
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111112'::uuid);

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111113'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Plants & Succulents',
    FALSE,
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111113'::uuid);

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111114'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Vases & Containers',
    FALSE,
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111114'::uuid);

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111115'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Gift Items',
    FALSE,
    FALSE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111115'::uuid);

INSERT INTO "ProductCategories" ("Id", "CompanyId", "Name", "IsPerishable", "TrackBatchByDefault", "IsActive", "CreatedAtUtc")
SELECT 
    'c1111111-1111-1111-1111-111111111116'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Greens & Fillers',
    TRUE,
    TRUE,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "ProductCategories" WHERE "Id" = 'c1111111-1111-1111-1111-111111111116'::uuid);

-- =====================================================
-- SUPPLIERS
-- =====================================================

INSERT INTO "Suppliers" ("Id", "CompanyId", "Name", "ContactPerson", "Email", "Phone", "Address", "TaxIdentifier", "PaymentTermsDays", "Rating", "IsActive", "CreatedAtUtc")
SELECT 
    'd1111111-1111-1111-1111-111111111111'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Flora Farms India',
    'Rajesh Kumar',
    'rajesh@florafarmsindia.com',
    '+91-9876543210',
    'Ooty Flower Market, Tamil Nadu',
    'GSTIN33AABCD1234E1ZM',
    30,
    5,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Suppliers" WHERE "Id" = 'd1111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Suppliers" ("Id", "CompanyId", "Name", "ContactPerson", "Email", "Phone", "Address", "TaxIdentifier", "PaymentTermsDays", "Rating", "IsActive", "CreatedAtUtc")
SELECT 
    'd1111111-1111-1111-1111-111111111112'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Bangalore Blooms',
    'Priya Sharma',
    'priya@bangaloreblooms.in',
    '+91-9123456789',
    '45 Flower Market Road, Bangalore 560001',
    'GSTIN29AABCB5678F1ZM',
    15,
    4,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Suppliers" WHERE "Id" = 'd1111111-1111-1111-1111-111111111112'::uuid);

INSERT INTO "Suppliers" ("Id", "CompanyId", "Name", "ContactPerson", "Email", "Phone", "Address", "TaxIdentifier", "PaymentTermsDays", "Rating", "IsActive", "CreatedAtUtc")
SELECT 
    'd1111111-1111-1111-1111-111111111113'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Dutch Flower Imports',
    'Hans Van Der Berg',
    'hans@dutchflowerimports.com',
    '+31-20-555-1234',
    'Aalsmeer Flower Auction, Netherlands',
    'NL123456789B01',
    45,
    5,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Suppliers" WHERE "Id" = 'd1111111-1111-1111-1111-111111111113'::uuid);

-- =====================================================
-- PRODUCTS - Fresh Flowers
-- =====================================================

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'ROSE-RED-001',
    'Red Roses',
    'Premium long-stem red roses, perfect for romantic occasions',
    1, -- Flower
    0, -- RawMaterial
    'c1111111-1111-1111-1111-111111111111'::uuid,
    25.00, -- Cost
    60.00, -- Retail
    40.00, -- Wholesale
    500,
    100,
    200,
    1, -- Stem
    TRUE,
    7,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    0, -- Standard
    'b1111111-1111-1111-1111-111111111111'::uuid, -- GST 18%
    0, -- AllYear
    'Red',
    'Freedom',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'ROSE-RED-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111102'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'ROSE-WHT-001',
    'White Roses',
    'Elegant white roses for weddings and sympathy',
    1, 0,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    28.00, 65.00, 45.00,
    300, 100, 200, 1, TRUE, 7, TRUE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    0, 'White', 'Avalanche',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'ROSE-WHT-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111103'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'LILY-WHT-001',
    'White Oriental Lilies',
    'Fragrant white oriental lilies with large blooms',
    1, 0,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    45.00, 120.00, 80.00,
    150, 50, 100, 1, TRUE, 10, TRUE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    0, 'White', 'Casa Blanca',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'LILY-WHT-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111104'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GERBERA-MIX-001',
    'Gerbera Daisies Mix',
    'Colorful mix of gerbera daisies',
    1, 0,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    15.00, 40.00, 25.00,
    400, 100, 200, 1, TRUE, 7, TRUE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    0, 'Mixed', 'Standard',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'GERBERA-MIX-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111105'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'CARN-RED-001',
    'Red Carnations',
    'Classic red carnations for all occasions',
    1, 0,
    'c1111111-1111-1111-1111-111111111111'::uuid,
    12.00, 30.00, 20.00,
    600, 150, 300, 1, TRUE, 14, TRUE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    0, 'Red', 'Standard',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'CARN-RED-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WholesalePrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "SeasonalAvailability", "Color", "Variety", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111106'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'ORCHID-WHT-001',
    'White Phalaenopsis Orchid',
    'Elegant white orchid plant in ceramic pot',
    3, -- Plant
    0,
    'c1111111-1111-1111-1111-111111111113'::uuid,
    350.00, 800.00, 550.00,
    25, 10, 15, 3, -- Each/Piece
    FALSE, NULL, TRUE, FALSE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    0, 'White', 'Phalaenopsis',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'ORCHID-WHT-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

-- =====================================================
-- PRODUCTS - Bouquets & Arrangements (Finished Products)
-- =====================================================

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WeddingEventPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "EstimatedMinutesToAssemble", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111201'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'BQ-ROMANTIC-001',
    'Romantic Red Rose Bouquet',
    '24 premium red roses with baby breath and greenery',
    0, -- Arrangement
    1, -- FinishedProduct
    'c1111111-1111-1111-1111-111111111112'::uuid,
    800.00, 1999.00, 2499.00,
    0, 0, 0, 3, TRUE, 3, FALSE, FALSE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    30,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'BQ-ROMANTIC-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WeddingEventPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "EstimatedMinutesToAssemble", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111202'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'BQ-MIXED-001',
    'Sunshine Mixed Bouquet',
    'Cheerful mix of gerberas, lilies, and roses',
    0, 1,
    'c1111111-1111-1111-1111-111111111112'::uuid,
    600.00, 1499.00, 1799.00,
    0, 0, 0, 3, TRUE, 3, FALSE, FALSE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    25,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'BQ-MIXED-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "WeddingEventPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "ShelfLifeDays", "TrackInventory", "TrackBatch", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "EstimatedMinutesToAssemble", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111203'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'ARR-SYMPATHY-001',
    'White Sympathy Arrangement',
    'Elegant white lilies and roses arrangement',
    0, 1,
    'c1111111-1111-1111-1111-111111111112'::uuid,
    1200.00, 2999.00, NULL,
    0, 0, 0, 3, TRUE, 3, FALSE, FALSE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    45,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'ARR-SYMPATHY-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

-- =====================================================
-- PRODUCTS - Gift Items
-- =====================================================

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "TrackInventory", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111301'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'VASE-GLASS-001',
    'Crystal Glass Vase',
    'Elegant crystal glass vase, 25cm height',
    7, -- Container
    2, -- Accessory
    'c1111111-1111-1111-1111-111111111114'::uuid,
    200.00, 599.00,
    50, 10, 20, 3, FALSE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'VASE-GLASS-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "TrackInventory", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111302'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'CHOC-BOX-001',
    'Premium Chocolate Box',
    'Assorted premium chocolates, 250g',
    8, -- Gift
    2,
    'c1111111-1111-1111-1111-111111111115'::uuid,
    300.00, 699.00,
    100, 20, 40, 3, FALSE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'CHOC-BOX-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

INSERT INTO "Products" ("Id", "CompanyId", "Sku", "Name", "Description", "Category", "ProductType", "CategoryId", "CostPrice", "RetailPrice", "StockQuantity", "MinimumStockLevel", "ReorderLevel", "UnitOfMeasure", "IsPerishable", "TrackInventory", "IsActive", "AvailableOnline", "TaxCategory", "TaxRuleId", "CreatedAtUtc")
SELECT 
    'e1111111-1111-1111-1111-111111111303'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'TEDDY-MED-001',
    'Medium Teddy Bear',
    'Soft plush teddy bear, 30cm',
    8, 2,
    'c1111111-1111-1111-1111-111111111115'::uuid,
    250.00, 599.00,
    30, 10, 15, 3, FALSE, TRUE, TRUE, TRUE, 0,
    'b1111111-1111-1111-1111-111111111111'::uuid,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Products" WHERE "Sku" = 'TEDDY-MED-001' AND "CompanyId" = '11111111-1111-1111-1111-111111111111'::uuid);

-- =====================================================
-- CUSTOMERS
-- =====================================================

INSERT INTO "Customers" ("Id", "CompanyId", "Name", "Email", "Phone", "DefaultCardMessage", "TotalOrders", "IsActive", "CreatedAtUtc")
SELECT 
    'f1111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Amit Sharma',
    'amit.sharma@gmail.com',
    '+91-9876543210',
    'With love and best wishes!',
    12,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Customers" WHERE "Id" = 'f1111111-1111-1111-1111-111111111101'::uuid);

INSERT INTO "Customers" ("Id", "CompanyId", "Name", "Email", "Phone", "DefaultCardMessage", "TotalOrders", "IsActive", "CreatedAtUtc")
SELECT 
    'f1111111-1111-1111-1111-111111111102'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Priya Patel',
    'priya.patel@outlook.com',
    '+91-9123456789',
    'Thinking of you!',
    8,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Customers" WHERE "Id" = 'f1111111-1111-1111-1111-111111111102'::uuid);

INSERT INTO "Customers" ("Id", "CompanyId", "Name", "Email", "Phone", "DefaultCardMessage", "TotalOrders", "IsActive", "CreatedAtUtc")
SELECT 
    'f1111111-1111-1111-1111-111111111103'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Raj Enterprises Ltd',
    'procurement@rajenterprises.com',
    '+91-22-26543210',
    'Corporate Greetings from Raj Enterprises',
    45,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Customers" WHERE "Id" = 'f1111111-1111-1111-1111-111111111103'::uuid);

INSERT INTO "Customers" ("Id", "CompanyId", "Name", "Email", "Phone", "DefaultCardMessage", "TotalOrders", "IsActive", "CreatedAtUtc")
SELECT 
    'f1111111-1111-1111-1111-111111111104'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Meera Singh',
    'meera.singh@yahoo.com',
    '+91-9654321098',
    NULL,
    3,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Customers" WHERE "Id" = 'f1111111-1111-1111-1111-111111111104'::uuid);

INSERT INTO "Customers" ("Id", "CompanyId", "Name", "Email", "Phone", "DefaultCardMessage", "TotalOrders", "IsActive", "CreatedAtUtc")
SELECT 
    'f1111111-1111-1111-1111-111111111105'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Taj Hotel Mumbai',
    'events@tajhotels.com',
    '+91-22-66543210',
    'With Compliments from The Taj',
    150,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Customers" WHERE "Id" = 'f1111111-1111-1111-1111-111111111105'::uuid);

-- =====================================================
-- STAFF
-- =====================================================

INSERT INTO "Staff" ("Id", "CompanyId", "Name", "Email", "Phone", "Role", "HourlyRate", "CommissionType", "CommissionRate", "PrimaryLocationId", "IsActive", "CreatedAtUtc")
SELECT 
    'g1111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Vikram Designer',
    'vikram@demoflorist.com',
    '+91-9876500001',
    2, -- Designer
    500.00,
    1, -- PercentOfSale
    5.00,
    'a1111111-1111-1111-1111-111111111111'::uuid,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Staff" WHERE "Id" = 'g1111111-1111-1111-1111-111111111101'::uuid);

INSERT INTO "Staff" ("Id", "CompanyId", "Name", "Email", "Phone", "Role", "HourlyRate", "CommissionType", "CommissionRate", "PrimaryLocationId", "IsActive", "CreatedAtUtc")
SELECT 
    'g1111111-1111-1111-1111-111111111102'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Anita Sales',
    'anita@demoflorist.com',
    '+91-9876500002',
    1, -- Sales
    400.00,
    1,
    3.00,
    'a1111111-1111-1111-1111-111111111111'::uuid,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Staff" WHERE "Id" = 'g1111111-1111-1111-1111-111111111102'::uuid);

INSERT INTO "Staff" ("Id", "CompanyId", "Name", "Email", "Phone", "Role", "HourlyRate", "PrimaryLocationId", "IsActive", "CreatedAtUtc")
SELECT 
    'g1111111-1111-1111-1111-111111111103'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Ramesh Driver',
    'ramesh@demoflorist.com',
    '+91-9876500003',
    4, -- Delivery
    300.00,
    'a1111111-1111-1111-1111-111111111111'::uuid,
    TRUE,
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "Staff" WHERE "Id" = 'g1111111-1111-1111-1111-111111111103'::uuid);

-- =====================================================
-- DELIVERY ZONES
-- =====================================================

INSERT INTO "DeliveryZones" ("Id", "CompanyId", "Name", "Code", "DeliveryFee", "SameDayFee", "ExpressFee", "EstimatedMinutes", "FreeDeliveryThreshold", "IsActive", "SortOrder", "ZipCodes", "Cities", "CreatedAtUtc")
SELECT 
    'h1111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Bandra & Khar',
    'ZONE-A',
    99.00,
    149.00,
    249.00,
    30,
    2000.00,
    TRUE,
    1,
    '400050,400051,400052',
    'Bandra West,Bandra East,Khar',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "DeliveryZones" WHERE "Id" = 'h1111111-1111-1111-1111-111111111101'::uuid);

INSERT INTO "DeliveryZones" ("Id", "CompanyId", "Name", "Code", "DeliveryFee", "SameDayFee", "ExpressFee", "EstimatedMinutes", "FreeDeliveryThreshold", "IsActive", "SortOrder", "ZipCodes", "Cities", "CreatedAtUtc")
SELECT 
    'h1111111-1111-1111-1111-111111111102'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'Andheri & Juhu',
    'ZONE-B',
    149.00,
    199.00,
    299.00,
    45,
    3000.00,
    TRUE,
    2,
    '400049,400053,400058,400069',
    'Juhu,Andheri West,Andheri East,Versova',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "DeliveryZones" WHERE "Id" = 'h1111111-1111-1111-1111-111111111102'::uuid);

INSERT INTO "DeliveryZones" ("Id", "CompanyId", "Name", "Code", "DeliveryFee", "SameDayFee", "ExpressFee", "EstimatedMinutes", "FreeDeliveryThreshold", "IsActive", "SortOrder", "ZipCodes", "Cities", "CreatedAtUtc")
SELECT 
    'h1111111-1111-1111-1111-111111111103'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'South Mumbai',
    'ZONE-C',
    199.00,
    299.00,
    399.00,
    60,
    5000.00,
    TRUE,
    3,
    '400001,400002,400003,400004,400005,400020,400021',
    'Colaba,Fort,Churchgate,Marine Lines,Nariman Point',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "DeliveryZones" WHERE "Id" = 'h1111111-1111-1111-1111-111111111103'::uuid);

-- =====================================================
-- GIFT CARDS
-- =====================================================

INSERT INTO "GiftCards" ("Id", "CompanyId", "Code", "InitialBalance", "CurrentBalance", "Status", "IssuedAt", "ExpiresAt", "SenderName", "RecipientName", "RecipientEmail", "RecipientPhone", "PersonalMessage", "CreatedAtUtc")
SELECT 
    'i1111111-1111-1111-1111-111111111101'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GIFT-DEMO-001',
    2000.00,
    1500.00,
    1, -- Active
    NOW() - INTERVAL '30 days',
    NOW() + INTERVAL '335 days',
    'Amit Sharma',
    'Neha Sharma',
    'neha@gmail.com',
    '+91-9876543211',
    'Happy Birthday! Enjoy some flowers!',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "GiftCards" WHERE "Code" = 'GIFT-DEMO-001');

INSERT INTO "GiftCards" ("Id", "CompanyId", "Code", "InitialBalance", "CurrentBalance", "Status", "IssuedAt", "ExpiresAt", "SenderName", "RecipientName", "RecipientEmail", "PersonalMessage", "CreatedAtUtc")
SELECT 
    'i1111111-1111-1111-1111-111111111102'::uuid,
    '11111111-1111-1111-1111-111111111111'::uuid,
    'GIFT-DEMO-002',
    5000.00,
    5000.00,
    1,
    NOW() - INTERVAL '7 days',
    NOW() + INTERVAL '358 days',
    'Raj Enterprises',
    'Employee Reward',
    'hr@rajenterprises.com',
    'Corporate Gift - Thank you for your service!',
    NOW()
WHERE NOT EXISTS (SELECT 1 FROM "GiftCards" WHERE "Code" = 'GIFT-DEMO-002');

-- =====================================================
-- SUMMARY
-- =====================================================
SELECT 'Demo data seeded successfully!' AS status,
       (SELECT COUNT(*) FROM "Companies") AS companies,
       (SELECT COUNT(*) FROM "Locations") AS locations,
       (SELECT COUNT(*) FROM "Products") AS products,
       (SELECT COUNT(*) FROM "Customers") AS customers,
       (SELECT COUNT(*) FROM "Suppliers") AS suppliers,
       (SELECT COUNT(*) FROM "Staff") AS staff,
       (SELECT COUNT(*) FROM "DeliveryZones") AS delivery_zones,
       (SELECT COUNT(*) FROM "GiftCards") AS gift_cards,
       (SELECT COUNT(*) FROM "tax_rules") AS tax_rules,
       (SELECT COUNT(*) FROM "ProductCategories") AS categories;
