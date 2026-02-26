-- =====================================================
-- SUMPOOJ FLORIST ERP - Production Module Tables
-- Migration Script - Add production / recipe / barcode tables
-- =====================================================

-- FloralRecipes
CREATE TABLE IF NOT EXISTS "FloralRecipes" (
    "Id"            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId"     UUID            NOT NULL,
    "Name"          VARCHAR(200)    NOT NULL,
    "Category"      VARCHAR(100),
    "SellingPrice"  DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "LaborCost"     DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "SampleImages"  TEXT,
    "IsActive"      BOOLEAN         NOT NULL DEFAULT TRUE,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ
);

-- RecipeComponents
CREATE TABLE IF NOT EXISTS "RecipeComponents" (
    "Id"                UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "RecipeId"          UUID            NOT NULL REFERENCES "FloralRecipes"("Id") ON DELETE CASCADE,
    "ProductId"         UUID            NOT NULL,
    "ProductName"       VARCHAR(200)    NOT NULL,
    "QuantityRequired"  INTEGER         NOT NULL DEFAULT 1,
    "UnitCost"          DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "CreatedAtUtc"      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"      TIMESTAMPTZ
);

-- FinishedGoodsBatches
CREATE TABLE IF NOT EXISTS "FinishedGoodsBatches" (
    "Id"                UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId"         UUID            NOT NULL,
    "RecipeId"          UUID            NOT NULL,
    "RecipeName"        VARCHAR(200)    NOT NULL,
    "BatchCode"         VARCHAR(50)     NOT NULL,
    "Barcode"           VARCHAR(50)     NOT NULL,
    "QuantityProduced"  INTEGER         NOT NULL DEFAULT 0,
    "QuantityAvailable" INTEGER         NOT NULL DEFAULT 0,
    "ExpectedExpiry"    TIMESTAMPTZ     NOT NULL,
    "LocationId"        UUID            NOT NULL,
    "LocationName"      VARCHAR(200)    NOT NULL,
    "TotalCost"         DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "Status"            INTEGER         NOT NULL DEFAULT 0,
    "ProducedAt"        TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "CreatedAtUtc"      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"      TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_FinishedGoodsBatches_CompanyId_BatchCode"
    ON "FinishedGoodsBatches" ("CompanyId", "BatchCode");

-- ProductionJobs
CREATE TABLE IF NOT EXISTS "ProductionJobs" (
    "Id"            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId"     UUID            NOT NULL,
    "OrderId"       UUID            NOT NULL,
    "Description"   TEXT            NOT NULL,
    "Status"        INTEGER         NOT NULL DEFAULT 0,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ
);

-- ProductionMaterialUsages
CREATE TABLE IF NOT EXISTS "ProductionMaterialUsages" (
    "Id"            UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "JobId"         UUID            NOT NULL REFERENCES "ProductionJobs"("Id") ON DELETE CASCADE,
    "ProductId"     UUID            NOT NULL,
    "ProductName"   VARCHAR(200)    NOT NULL,
    "UnitsUsed"     INTEGER         NOT NULL DEFAULT 0,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ
);

-- ProductionMaintenanceLogs
CREATE TABLE IF NOT EXISTS "ProductionMaintenanceLogs" (
    "Id"                UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId"         UUID            NOT NULL,
    "FinishedBatchId"   UUID            NOT NULL,
    "BatchCode"         VARCHAR(50)     NOT NULL,
    "Notes"             TEXT,
    "PerformedAt"       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "PerformedBy"       VARCHAR(200),
    "ReplacementsJson"  TEXT,
    "CreatedAtUtc"      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"      TIMESTAMPTZ
);

-- ProductionWastageLogs
CREATE TABLE IF NOT EXISTS "ProductionWastageLogs" (
    "Id"                        UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId"                 UUID            NOT NULL,
    "ProductId"                 UUID            NOT NULL,
    "ProductName"               VARCHAR(200)    NOT NULL,
    "Quantity"                  INTEGER         NOT NULL DEFAULT 0,
    "Reason"                    INTEGER         NOT NULL DEFAULT 0,
    "RelatedFinishedBatchId"    UUID,
    "RelatedBatchCode"          VARCHAR(50),
    "CreatedBy"                 VARCHAR(200),
    "CreatedAtUtc"              TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"              TIMESTAMPTZ
);

-- =====================================================
-- COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Production module tables created successfully!';
END $$;
