-- =====================================================
-- SUMPOOJ FLORIST ERP - PostgreSQL Database Script
-- Database First Approach - COMPLETE VERSION
-- =====================================================
-- Run this script against a PostgreSQL database
-- =====================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- DROP EXISTING TABLES (for fresh start)
-- =====================================================
DROP TABLE IF EXISTS "AuditLogs" CASCADE;
DROP TABLE IF EXISTS "DayCloses" CASCADE;
DROP TABLE IF EXISTS "RefundItems" CASCADE;
DROP TABLE IF EXISTS "Refunds" CASCADE;
DROP TABLE IF EXISTS "Tasks" CASCADE;
DROP TABLE IF EXISTS "GiftCards" CASCADE;
DROP TABLE IF EXISTS "Payments" CASCADE;
DROP TABLE IF EXISTS "Events" CASCADE;
DROP TABLE IF EXISTS "Staff" CASCADE;
DROP TABLE IF EXISTS "StockMovements" CASCADE;
DROP TABLE IF EXISTS "InventoryAdjustments" CASCADE;
DROP TABLE IF EXISTS "ProductBatches" CASCADE;
DROP TABLE IF EXISTS "Deliveries" CASCADE;
DROP TABLE IF EXISTS "OrderItems" CASCADE;
DROP TABLE IF EXISTS "Orders" CASCADE;
DROP TABLE IF EXISTS "PurchaseOrderItems" CASCADE;
DROP TABLE IF EXISTS "PurchaseOrders" CASCADE;
DROP TABLE IF EXISTS "Products" CASCADE;
DROP TABLE IF EXISTS "Suppliers" CASCADE;
DROP TABLE IF EXISTS "Customers" CASCADE;
DROP TABLE IF EXISTS "Locations" CASCADE;
DROP TABLE IF EXISTS "Companies" CASCADE;
DROP TABLE IF EXISTS "AspNetUserTokens" CASCADE;
DROP TABLE IF EXISTS "AspNetUserRoles" CASCADE;
DROP TABLE IF EXISTS "AspNetUserLogins" CASCADE;
DROP TABLE IF EXISTS "AspNetUserClaims" CASCADE;
DROP TABLE IF EXISTS "AspNetRoleClaims" CASCADE;
DROP TABLE IF EXISTS "AspNetRoles" CASCADE;
DROP TABLE IF EXISTS "AspNetUsers" CASCADE;

-- =====================================================
-- IDENTITY TABLES (ASP.NET Identity)
-- =====================================================

CREATE TABLE "AspNetRoles" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "Name" VARCHAR(256) NULL,
    "NormalizedName" VARCHAR(256) NULL,
    "ConcurrencyStamp" TEXT NULL,
    CONSTRAINT "PK_AspNetRoles" PRIMARY KEY ("Id")
);

CREATE TABLE "AspNetUsers" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NULL,
    "FirstName" VARCHAR(100) NULL,
    "LastName" VARCHAR(100) NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "UserName" VARCHAR(256) NULL,
    "NormalizedUserName" VARCHAR(256) NULL,
    "Email" VARCHAR(256) NULL,
    "NormalizedEmail" VARCHAR(256) NULL,
    "EmailConfirmed" BOOLEAN NOT NULL DEFAULT FALSE,
    "PasswordHash" TEXT NULL,
    "SecurityStamp" TEXT NULL,
    "ConcurrencyStamp" TEXT NULL,
    "PhoneNumber" TEXT NULL,
    "PhoneNumberConfirmed" BOOLEAN NOT NULL DEFAULT FALSE,
    "TwoFactorEnabled" BOOLEAN NOT NULL DEFAULT FALSE,
    "LockoutEnd" TIMESTAMPTZ NULL,
    "LockoutEnabled" BOOLEAN NOT NULL DEFAULT FALSE,
    "AccessFailedCount" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "PK_AspNetUsers" PRIMARY KEY ("Id")
);

CREATE TABLE "AspNetRoleClaims" (
    "Id" SERIAL NOT NULL,
    "RoleId" UUID NOT NULL,
    "ClaimType" TEXT NULL,
    "ClaimValue" TEXT NULL,
    CONSTRAINT "PK_AspNetRoleClaims" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_AspNetRoleClaims_AspNetRoles" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserClaims" (
    "Id" SERIAL NOT NULL,
    "UserId" UUID NOT NULL,
    "ClaimType" TEXT NULL,
    "ClaimValue" TEXT NULL,
    CONSTRAINT "PK_AspNetUserClaims" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_AspNetUserClaims_AspNetUsers" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserLogins" (
    "LoginProvider" VARCHAR(128) NOT NULL,
    "ProviderKey" VARCHAR(128) NOT NULL,
    "ProviderDisplayName" TEXT NULL,
    "UserId" UUID NOT NULL,
    CONSTRAINT "PK_AspNetUserLogins" PRIMARY KEY ("LoginProvider", "ProviderKey"),
    CONSTRAINT "FK_AspNetUserLogins_AspNetUsers" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserRoles" (
    "UserId" UUID NOT NULL,
    "RoleId" UUID NOT NULL,
    CONSTRAINT "PK_AspNetUserRoles" PRIMARY KEY ("UserId", "RoleId"),
    CONSTRAINT "FK_AspNetUserRoles_AspNetRoles" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_AspNetUserRoles_AspNetUsers" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

CREATE TABLE "AspNetUserTokens" (
    "UserId" UUID NOT NULL,
    "LoginProvider" VARCHAR(128) NOT NULL,
    "Name" VARCHAR(128) NOT NULL,
    "Value" TEXT NULL,
    CONSTRAINT "PK_AspNetUserTokens" PRIMARY KEY ("UserId", "LoginProvider", "Name"),
    CONSTRAINT "FK_AspNetUserTokens_AspNetUsers" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- COMPANY TABLE (Tenant)
-- =====================================================

CREATE TABLE "Companies" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "Name" VARCHAR(200) NOT NULL,
    "Region" VARCHAR(10) NOT NULL DEFAULT 'US',
    "Email" VARCHAR(200) NULL,
    "Phone" VARCHAR(50) NULL,
    "Address" TEXT NULL,
    "ShortDescription" TEXT NULL,
    "LogoPath" TEXT NULL,
    "TimeZone" VARCHAR(100) NULL DEFAULT 'UTC',
    "CurrencyCode" VARCHAR(10) NULL DEFAULT 'USD',
    "TaxIdentifier" VARCHAR(100) NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Companies" PRIMARY KEY ("Id")
);

-- =====================================================
-- LOCATION TABLE
-- =====================================================

CREATE TABLE "Locations" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "Code" VARCHAR(50) NOT NULL,
    "LocationType" INTEGER NOT NULL DEFAULT 0,
    "Address" TEXT NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDefault" BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Locations" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Locations_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- SUPPLIER TABLE
-- =====================================================

CREATE TABLE "Suppliers" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "ContactPerson" VARCHAR(200) NULL,
    "Email" VARCHAR(200) NULL,
    "Phone" VARCHAR(50) NULL,
    "Address" TEXT NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "Rating" INTEGER NOT NULL DEFAULT 0,
    "Notes" TEXT NULL,
    "PaymentTermsDays" INTEGER NOT NULL DEFAULT 30,
    "TaxIdentifier" VARCHAR(100) NULL,
    "LastOrderDate" TIMESTAMPTZ NULL,
    "TotalOrdersCount" INTEGER NOT NULL DEFAULT 0,
    "TotalSpentAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Suppliers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Suppliers_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- CUSTOMER TABLE
-- =====================================================

CREATE TABLE "Customers" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "Email" VARCHAR(200) NULL,
    "Phone" VARCHAR(50) NULL,
    "Address" TEXT NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "DefaultCardMessage" TEXT NULL,
    "TotalOrders" INTEGER NOT NULL DEFAULT 0,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Customers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Customers_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- STAFF TABLE
-- =====================================================

CREATE TABLE "Staff" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "Role" INTEGER NOT NULL DEFAULT 5,
    "Email" VARCHAR(200) NULL,
    "Phone" VARCHAR(50) NULL,
    "UserId" UUID NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CommissionType" INTEGER NULL,
    "CommissionRate" DECIMAL(5,2) NULL,
    "HourlyRate" DECIMAL(10,2) NULL,
    "PrimaryLocationId" UUID NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Staff" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Staff_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Staff_Locations" FOREIGN KEY ("PrimaryLocationId") REFERENCES "Locations" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Staff_Users" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE SET NULL
);

-- =====================================================
-- PRODUCT TABLE
-- =====================================================

CREATE TABLE "Products" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "Sku" VARCHAR(100) NOT NULL,
    "Barcode" VARCHAR(100) NULL,
    "Brand" VARCHAR(100) NULL,
    "ProductType" INTEGER NOT NULL DEFAULT 0,
    "Category" INTEGER NOT NULL DEFAULT 17,
    "Description" TEXT NULL,
    "UnitOfMeasure" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "RetailPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CostPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "WholesalePrice" DECIMAL(18,2) NULL,
    "WeddingEventPrice" DECIMAL(18,2) NULL,
    "TaxCategory" INTEGER NOT NULL DEFAULT 1,
    "TrackInventory" BOOLEAN NOT NULL DEFAULT TRUE,
    "TrackBatch" BOOLEAN NOT NULL DEFAULT FALSE,
    "StockQuantity" INTEGER NOT NULL DEFAULT 0,
    "MinimumStockLevel" INTEGER NOT NULL DEFAULT 0,
    "ReorderLevel" INTEGER NOT NULL DEFAULT 0,
    "IsPerishable" BOOLEAN NOT NULL DEFAULT FALSE,
    "ShelfLifeDays" INTEGER NULL,
    "ExpiryAlertDays" INTEGER NULL,
    "TemperatureNotes" VARCHAR(500) NULL,
    "Color" VARCHAR(100) NULL,
    "Variety" VARCHAR(100) NULL,
    "FlowerGrade" INTEGER NULL,
    "CountryOfOrigin" VARCHAR(10) NULL,
    "SeasonalAvailability" INTEGER NOT NULL DEFAULT 0,
    "EstimatedMinutesToAssemble" INTEGER NULL,
    "DefaultSupplierId" UUID NULL,
    "LeadTimeDays" INTEGER NULL,
    "IncomeAccount" VARCHAR(20) NULL,
    "ExpenseAccount" VARCHAR(20) NULL,
    "AllowAsRawMaterial" BOOLEAN NOT NULL DEFAULT FALSE,
    "AvailableOnline" BOOLEAN NOT NULL DEFAULT FALSE,
    "CommissionEligible" BOOLEAN NOT NULL DEFAULT FALSE,
    "Tags" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Products" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Products_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Products_Suppliers" FOREIGN KEY ("DefaultSupplierId") REFERENCES "Suppliers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "UQ_Products_CompanySku" UNIQUE ("CompanyId", "Sku")
);

-- =====================================================
-- PRODUCT BATCH TABLE
-- =====================================================

CREATE TABLE "ProductBatches" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "BatchNumber" VARCHAR(100) NOT NULL,
    "QuantityReceived" INTEGER NOT NULL DEFAULT 0,
    "QuantityRemaining" INTEGER NOT NULL DEFAULT 0,
    "CostPerUnit" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "SellingPricePerUnit" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ReceivedDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ExpiryDate" TIMESTAMPTZ NULL,
    "SupplierId" UUID NULL,
    "LocationId" UUID NULL,
    "StorageLocation" VARCHAR(200) NULL,
    "PurchaseOrderId" UUID NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_ProductBatches" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_ProductBatches_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_ProductBatches_Products" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_ProductBatches_Suppliers" FOREIGN KEY ("SupplierId") REFERENCES "Suppliers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_ProductBatches_Locations" FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id") ON DELETE SET NULL
);

-- =====================================================
-- INVENTORY ADJUSTMENT TABLE
-- =====================================================

CREATE TABLE "InventoryAdjustments" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "BatchId" UUID NULL,
    "AdjustmentType" INTEGER NOT NULL DEFAULT 0,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    "CostPerUnit" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalValue" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Reason" TEXT NOT NULL,
    "AdjustedByUserId" UUID NOT NULL,
    "AdjustmentDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Notes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_InventoryAdjustments" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_InventoryAdjustments_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_InventoryAdjustments_Products" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_InventoryAdjustments_Batches" FOREIGN KEY ("BatchId") REFERENCES "ProductBatches" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_InventoryAdjustments_Users" FOREIGN KEY ("AdjustedByUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE RESTRICT
);

-- =====================================================
-- PURCHASE ORDER TABLE
-- =====================================================

CREATE TABLE "PurchaseOrders" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "SupplierId" UUID NOT NULL,
    "OrderNumber" VARCHAR(50) NOT NULL,
    "OrderDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ExpectedDeliveryDate" TIMESTAMPTZ NOT NULL,
    "ActualDeliveryDate" TIMESTAMPTZ NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "TotalAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Notes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_PurchaseOrders" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PurchaseOrders_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PurchaseOrders_Suppliers" FOREIGN KEY ("SupplierId") REFERENCES "Suppliers" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "UQ_PurchaseOrders_CompanyOrderNumber" UNIQUE ("CompanyId", "OrderNumber")
);

-- =====================================================
-- PURCHASE ORDER ITEM TABLE
-- =====================================================

CREATE TABLE "PurchaseOrderItems" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "PurchaseOrderId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "ProductName" VARCHAR(200) NOT NULL,
    "Sku" VARCHAR(100) NULL,
    "Unit" VARCHAR(50) NULL,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    "UnitPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ReceivedQuantity" INTEGER NOT NULL DEFAULT 0,
    "IsPerishable" BOOLEAN NOT NULL DEFAULT FALSE,
    "ShelfLifeDays" INTEGER NOT NULL DEFAULT 0,
    "BatchNumber" VARCHAR(100) NULL,
    "ExpiryDate" TIMESTAMPTZ NULL,
    "StorageLocation" VARCHAR(200) NULL,
    CONSTRAINT "PK_PurchaseOrderItems" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PurchaseOrderItems_PurchaseOrders" FOREIGN KEY ("PurchaseOrderId") REFERENCES "PurchaseOrders" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PurchaseOrderItems_Products" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);

-- =====================================================
-- ORDER TABLE (Sales Orders)
-- =====================================================

CREATE TABLE "Orders" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "CustomerId" UUID NOT NULL,
    "OrderNumber" VARCHAR(50) NOT NULL,
    "OrderDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "DeliveryDate" TIMESTAMPTZ NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "PaymentStatus" INTEGER NOT NULL DEFAULT 0,
    "FulfillmentStatus" INTEGER NOT NULL DEFAULT 0,
    "OrderSource" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "TimeSlot" VARCHAR(50) NULL,
    "DeliveryAddress" TEXT NULL,
    "RecipientName" VARCHAR(200) NULL,
    "RecipientPhone" VARCHAR(50) NULL,
    "CardMessage" TEXT NULL,
    "DeliveryPriority" INTEGER NOT NULL DEFAULT 0,
    "SubTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "DeliveryFee" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TaxAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "DiscountAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "AssignedToUserId" UUID NULL,
    "DeliveryPersonId" UUID NULL,
    "InternalNotes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Orders" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Orders_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Orders_Customers" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_Orders_AssignedUser" FOREIGN KEY ("AssignedToUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Orders_DeliveryPerson" FOREIGN KEY ("DeliveryPersonId") REFERENCES "AspNetUsers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "UQ_Orders_CompanyOrderNumber" UNIQUE ("CompanyId", "OrderNumber")
);

-- =====================================================
-- ORDER ITEM TABLE
-- =====================================================

CREATE TABLE "OrderItems" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "OrderId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "ProductName" VARCHAR(200) NOT NULL,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    "UnitPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "DiscountAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "SpecialInstructions" TEXT NULL,
    CONSTRAINT "PK_OrderItems" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_OrderItems_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- DELIVERY TABLE
-- =====================================================

CREATE TABLE "Deliveries" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "OrderId" UUID NOT NULL,
    "DeliveryPersonId" UUID NULL,
    "ScheduledDateTime" TIMESTAMPTZ NOT NULL,
    "ActualDeliveryDateTime" TIMESTAMPTZ NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "DeliveryAddress" TEXT NOT NULL,
    "RecipientName" VARCHAR(200) NULL,
    "RecipientPhone" VARCHAR(50) NULL,
    "DeliveryProofPhotoPath" TEXT NULL,
    "RecipientSignature" TEXT NULL,
    "DeliveryNotes" TEXT NULL,
    "DeliveryLatitude" DOUBLE PRECISION NULL,
    "DeliveryLongitude" DOUBLE PRECISION NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Deliveries" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Deliveries_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Deliveries_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Deliveries_Users" FOREIGN KEY ("DeliveryPersonId") REFERENCES "AspNetUsers" ("Id") ON DELETE SET NULL
);

-- =====================================================
-- PAYMENT TABLE
-- =====================================================

CREATE TABLE "Payments" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "OrderId" UUID NOT NULL,
    "LocationId" UUID NULL,
    "Method" INTEGER NOT NULL DEFAULT 0,
    "Amount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "TransactionId" VARCHAR(200) NULL,
    "AuthorizationCode" VARCHAR(100) NULL,
    "CardBrand" VARCHAR(50) NULL,
    "Last4" VARCHAR(4) NULL,
    "TerminalId" VARCHAR(100) NULL,
    "TerminalResponseCode" VARCHAR(50) NULL,
    "TerminalMessage" TEXT NULL,
    "ReceiptData" TEXT NULL,
    "ProcessedByUserId" UUID NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Payments" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Payments_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Payments_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Payments_Locations" FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Payments_Users" FOREIGN KEY ("ProcessedByUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE SET NULL
);

-- =====================================================
-- EVENT TABLE (Weddings, Corporate, etc.)
-- =====================================================

CREATE TABLE "Events" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "EventName" VARCHAR(300) NOT NULL,
    "EventType" INTEGER NOT NULL DEFAULT 0,
    "EventDate" TIMESTAMPTZ NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "ClientName" VARCHAR(200) NOT NULL,
    "ClientPhone" VARCHAR(50) NOT NULL,
    "ClientEmail" VARCHAR(200) NULL,
    "VenueName" VARCHAR(300) NOT NULL,
    "VenueAddress" TEXT NULL,
    "EstimatedGuestCount" INTEGER NULL,
    "Budget" DECIMAL(18,2) NULL,
    "ColorTheme" VARCHAR(200) NULL,
    "MoodNotes" TEXT NULL,
    "MoodBoardLink" TEXT NULL,
    "AssignedDesignerId" UUID NULL,
    "InternalNotes" TEXT NULL,
    "TotalProposedAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalPaidAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "EstimatedCost" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Events" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Events_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Events_Designer" FOREIGN KEY ("AssignedDesignerId") REFERENCES "Staff" ("Id") ON DELETE SET NULL
);

-- =====================================================
-- STAFF TASK TABLE
-- =====================================================

CREATE TABLE "Tasks" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "LocationId" UUID NOT NULL,
    "Title" VARCHAR(300) NOT NULL,
    "Description" TEXT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "Priority" INTEGER NOT NULL DEFAULT 1,
    "AssignedToStaffId" UUID NOT NULL,
    "DueDate" TIMESTAMPTZ NULL,
    "RelatedEntityType" INTEGER NULL,
    "RelatedEntityId" UUID NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Tasks" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Tasks_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Tasks_Locations" FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Tasks_Staff" FOREIGN KEY ("AssignedToStaffId") REFERENCES "Staff" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- GIFT CARD TABLE
-- =====================================================

CREATE TABLE "GiftCards" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "Code" VARCHAR(50) NOT NULL,
    "InitialBalance" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CurrentBalance" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "IssuedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ExpiresAt" TIMESTAMPTZ NULL,
    "LastUsedAt" TIMESTAMPTZ NULL,
    "RecipientName" VARCHAR(200) NULL,
    "RecipientEmail" VARCHAR(200) NULL,
    "RecipientPhone" VARCHAR(50) NULL,
    "SenderName" VARCHAR(200) NULL,
    "PersonalMessage" TEXT NULL,
    "DesignTheme" VARCHAR(100) NULL,
    "PurchasedByCustomerId" UUID NULL,
    "SourceOrderId" UUID NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_GiftCards" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_GiftCards_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "UQ_GiftCards_CompanyCode" UNIQUE ("CompanyId", "Code")
);

-- =====================================================
-- REFUND TABLE
-- =====================================================

CREATE TABLE "Refunds" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "OrderId" UUID NOT NULL,
    "RefundNumber" VARCHAR(50) NOT NULL,
    "Method" INTEGER NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "Reason" TEXT NOT NULL,
    "RefundedAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ProcessedByUserId" UUID NOT NULL,
    "TransactionId" VARCHAR(200) NULL,
    "Notes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_Refunds" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Refunds_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Refunds_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_Refunds_Users" FOREIGN KEY ("ProcessedByUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE RESTRICT
);

-- =====================================================
-- REFUND ITEM TABLE
-- =====================================================

CREATE TABLE "RefundItems" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "RefundId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "ProductName" VARCHAR(200) NOT NULL,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    "UnitPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "RefundAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Restock" BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT "PK_RefundItems" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_RefundItems_Refunds" FOREIGN KEY ("RefundId") REFERENCES "Refunds" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- DAY CLOSE TABLE
-- =====================================================

CREATE TABLE "DayCloses" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "LocationId" UUID NOT NULL,
    "BusinessDate" DATE NOT NULL,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "ClosedAt" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ClosedByUserId" UUID NOT NULL,
    "TotalOrders" INTEGER NOT NULL DEFAULT 0,
    "TotalSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalRefunds" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "NetSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CashTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CardTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "UpiTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "GiftCardTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "OtherPaymentsTotal" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ExpectedCash" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ActualCash" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CashVariance" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "Notes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_DayCloses" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_DayCloses_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_DayCloses_Locations" FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_DayCloses_Users" FOREIGN KEY ("ClosedByUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "UQ_DayCloses_CompanyLocationDate" UNIQUE ("CompanyId", "LocationId", "BusinessDate")
);

-- =====================================================
-- STOCK MOVEMENT TABLE (Audit Trail)
-- =====================================================

CREATE TABLE "StockMovements" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "ProductId" UUID NOT NULL,
    "MovementType" INTEGER NOT NULL DEFAULT 0,
    "Quantity" INTEGER NOT NULL DEFAULT 0,
    "MovementDate" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "Reason" TEXT NULL,
    "OrderId" UUID NULL,
    "PurchaseOrderId" UUID NULL,
    "UserId" UUID NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_StockMovements" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_StockMovements_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_StockMovements_Products" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- AUDIT LOG TABLE (User Activity Tracking)
-- =====================================================

CREATE TABLE "AuditLogs" (
    "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" UUID NOT NULL,
    "UserId" UUID NULL,
    "UserName" VARCHAR(256) NULL,
    "UserRole" VARCHAR(100) NULL,
    "Action" VARCHAR(100) NOT NULL,
    "EntityType" VARCHAR(100) NOT NULL,
    "EntityId" UUID NULL,
    "EntityName" VARCHAR(300) NULL,
    "OldValues" TEXT NULL,
    "NewValues" TEXT NULL,
    "Description" TEXT NULL,
    "IpAddress" VARCHAR(50) NULL,
    "UserAgent" TEXT NULL,
    "RequestPath" VARCHAR(500) NULL,
    "HttpMethod" VARCHAR(10) NULL,
    "Timestamp" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "DurationMs" BIGINT NULL,
    "IsSuccess" BOOLEAN NOT NULL DEFAULT TRUE,
    "ErrorMessage" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_AuditLogs" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_AuditLogs_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

-- =====================================================
-- INDEXES
-- =====================================================

-- Identity
CREATE UNIQUE INDEX "IX_AspNetRoles_NormalizedName" ON "AspNetRoles" ("NormalizedName");
CREATE INDEX "IX_AspNetUsers_CompanyId" ON "AspNetUsers" ("CompanyId");
CREATE INDEX "IX_AspNetUsers_NormalizedEmail" ON "AspNetUsers" ("NormalizedEmail");
CREATE UNIQUE INDEX "IX_AspNetUsers_NormalizedUserName" ON "AspNetUsers" ("NormalizedUserName");

-- Core entities
CREATE INDEX "IX_Locations_CompanyId" ON "Locations" ("CompanyId");
CREATE INDEX "IX_Suppliers_CompanyId" ON "Suppliers" ("CompanyId");
CREATE INDEX "IX_Customers_CompanyId" ON "Customers" ("CompanyId");
CREATE INDEX "IX_Staff_CompanyId" ON "Staff" ("CompanyId");
CREATE INDEX "IX_Products_CompanyId" ON "Products" ("CompanyId");
CREATE INDEX "IX_Products_Sku" ON "Products" ("Sku");
CREATE INDEX "IX_ProductBatches_CompanyId" ON "ProductBatches" ("CompanyId");
CREATE INDEX "IX_ProductBatches_ProductId" ON "ProductBatches" ("ProductId");
CREATE INDEX "IX_ProductBatches_ExpiryDate" ON "ProductBatches" ("ExpiryDate");
CREATE INDEX "IX_InventoryAdjustments_CompanyId" ON "InventoryAdjustments" ("CompanyId");
CREATE INDEX "IX_PurchaseOrders_CompanyId" ON "PurchaseOrders" ("CompanyId");
CREATE INDEX "IX_PurchaseOrders_SupplierId" ON "PurchaseOrders" ("SupplierId");
CREATE INDEX "IX_Orders_CompanyId" ON "Orders" ("CompanyId");
CREATE INDEX "IX_Orders_CustomerId" ON "Orders" ("CustomerId");
CREATE INDEX "IX_Orders_OrderDate" ON "Orders" ("OrderDate" DESC);
CREATE INDEX "IX_Orders_DeliveryDate" ON "Orders" ("DeliveryDate");
CREATE INDEX "IX_Payments_OrderId" ON "Payments" ("OrderId");
CREATE INDEX "IX_Events_CompanyId" ON "Events" ("CompanyId");
CREATE INDEX "IX_Events_EventDate" ON "Events" ("EventDate");
CREATE INDEX "IX_Tasks_CompanyId" ON "Tasks" ("CompanyId");
CREATE INDEX "IX_Tasks_AssignedToStaffId" ON "Tasks" ("AssignedToStaffId");
CREATE INDEX "IX_GiftCards_CompanyId" ON "GiftCards" ("CompanyId");
CREATE INDEX "IX_GiftCards_Code" ON "GiftCards" ("Code");
CREATE INDEX "IX_Refunds_OrderId" ON "Refunds" ("OrderId");
CREATE INDEX "IX_DayCloses_CompanyId_LocationId" ON "DayCloses" ("CompanyId", "LocationId");

-- Audit Logs
CREATE INDEX "IX_AuditLogs_CompanyId" ON "AuditLogs" ("CompanyId");
CREATE INDEX "IX_AuditLogs_UserId" ON "AuditLogs" ("UserId");
CREATE INDEX "IX_AuditLogs_Timestamp" ON "AuditLogs" ("Timestamp" DESC);
CREATE INDEX "IX_AuditLogs_EntityType_EntityId" ON "AuditLogs" ("EntityType", "EntityId");
CREATE INDEX "IX_AuditLogs_Action" ON "AuditLogs" ("Action");

-- =====================================================
-- SEED DATA - ROLES
-- =====================================================

INSERT INTO "AspNetRoles" ("Id", "Name", "NormalizedName", "ConcurrencyStamp") VALUES
    ('11111111-1111-1111-1111-111111111111', 'PlatformSuperAdmin', 'PLATFORMSUPERADMIN', uuid_generate_v4()::text),
    ('22222222-2222-2222-2222-222222222222', 'PlatformSupport', 'PLATFORMSUPPORT', uuid_generate_v4()::text),
    ('33333333-3333-3333-3333-333333333333', 'CompanyAdmin', 'COMPANYADMIN', uuid_generate_v4()::text),
    ('44444444-4444-4444-4444-444444444444', 'Manager', 'MANAGER', uuid_generate_v4()::text),
    ('55555555-5555-5555-5555-555555555555', 'Staff', 'STAFF', uuid_generate_v4()::text),
    ('66666666-6666-6666-6666-666666666666', 'Delivery', 'DELIVERY', uuid_generate_v4()::text);

-- =====================================================
-- COMPLETION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'SUMPOOJ Database Schema Created Successfully!';
    RAISE NOTICE 'Tables: 25 | Indexes: 30+ | Roles: 6';
    RAISE NOTICE '=====================================================';
    RAISE NOTICE 'Includes: Audit Logging for User Activity Tracking';
    RAISE NOTICE 'DB-First compatible with EF Core scaffolding';
    RAISE NOTICE '=====================================================';
END $$;
