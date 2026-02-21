-- =====================================================
-- SUMPOOJ FLORIST ERP - Tax Rules & Product TaxRuleId
-- Migration Script - AddTaxRule & AddProductTaxRuleFK
-- =====================================================

-- =====================================================
-- Tax Rules Table
-- =====================================================
CREATE TABLE IF NOT EXISTS "tax_rules" (
    "Id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "Rate" DECIMAL(8,4) NOT NULL,
    "CountryCode" VARCHAR(10) NOT NULL,
    "IsInclusive" BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ
);

-- Indexes for tax_rules
CREATE INDEX IF NOT EXISTS "IX_tax_rules_CompanyId_CountryCode" ON "tax_rules"("CompanyId", "CountryCode");
CREATE INDEX IF NOT EXISTS "IX_tax_rules_IsActive" ON "tax_rules"("IsActive");

COMMENT ON TABLE "tax_rules" IS 'Tax rules configuration per company and country';

-- =====================================================
-- Add TaxRuleId column to Products table (if not exists)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'Products' AND column_name = 'TaxRuleId'
    ) THEN
        ALTER TABLE "Products" ADD COLUMN "TaxRuleId" UUID NULL;
    END IF;
END $$;

-- Add index for TaxRuleId
CREATE INDEX IF NOT EXISTS "IX_Products_TaxRuleId" ON "Products"("TaxRuleId");

-- Add foreign key constraint (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'FK_Products_tax_rules_TaxRuleId'
    ) THEN
        ALTER TABLE "Products" 
        ADD CONSTRAINT "FK_Products_tax_rules_TaxRuleId" 
        FOREIGN KEY ("TaxRuleId") REFERENCES "tax_rules"("Id") ON DELETE SET NULL;
    END IF;
END $$;

-- =====================================================
-- Product Categories Table (if not exists)
-- =====================================================
CREATE TABLE IF NOT EXISTS "ProductCategories" (
    "Id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "IsPerishable" BOOLEAN NOT NULL DEFAULT FALSE,
    "TrackBatchByDefault" BOOLEAN NOT NULL DEFAULT FALSE,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ,
    CONSTRAINT "UQ_ProductCategories_CompanyName" UNIQUE ("CompanyId", "Name")
);

-- Add CategoryId column to Products table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'Products' AND column_name = 'CategoryId'
    ) THEN
        ALTER TABLE "Products" ADD COLUMN "CategoryId" UUID NULL;
    END IF;
END $$;

-- Add index and FK for CategoryId
CREATE INDEX IF NOT EXISTS "IX_Products_CategoryId" ON "Products"("CategoryId");

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'FK_Products_ProductCategories_CategoryId'
    ) THEN
        ALTER TABLE "Products" 
        ADD CONSTRAINT "FK_Products_ProductCategories_CategoryId" 
        FOREIGN KEY ("CategoryId") REFERENCES "ProductCategories"("Id") ON DELETE SET NULL;
    END IF;
END $$;

-- =====================================================
-- Shifts Table (if not exists)
-- =====================================================
CREATE TABLE IF NOT EXISTS "Shifts" (
    "Id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId" UUID NOT NULL,
    "LocationId" UUID NOT NULL,
    "OpenedByUserId" UUID NOT NULL,
    "OpenedByName" VARCHAR(200) NOT NULL,
    "OpenedAt" TIMESTAMPTZ NOT NULL,
    "OpeningCash" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "ClosedByUserId" UUID NULL,
    "ClosedByName" VARCHAR(200) NULL,
    "ClosedAt" TIMESTAMPTZ NULL,
    "ClosingCashCount" DECIMAL(18,2) NULL,
    "CashDifference" DECIMAL(18,2) NULL,
    "CashSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "CardSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "UpiSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "GiftCardSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "OtherSales" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TotalRefunds" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "PaidOuts" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "TransactionCount" INTEGER NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "Notes" TEXT NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS "IX_Shifts_CompanyId" ON "Shifts"("CompanyId");
CREATE INDEX IF NOT EXISTS "IX_Shifts_LocationId" ON "Shifts"("LocationId");
CREATE INDEX IF NOT EXISTS "IX_Shifts_Status" ON "Shifts"("Status");

COMMENT ON TABLE "Shifts" IS 'POS shift management for cash drawer reconciliation';
COMMENT ON COLUMN "Shifts"."Status" IS '0=Open, 1=Closed, 2=Suspended';
