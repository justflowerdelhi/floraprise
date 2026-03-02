-- =====================================================
-- Migration 014: Customer Notes + AI Usage Tracking
-- =====================================================
-- Adds:
--   1. "Notes" column to "Customers" table
--   2. "AIUsageRecords" table for AI generation rate-limiting
-- =====================================================

-- 1. Add Notes column to Customers
ALTER TABLE "Customers" ADD COLUMN IF NOT EXISTS "Notes" TEXT NULL;

-- 2. Create AI Usage Records table
CREATE TABLE IF NOT EXISTS "AIUsageRecords" (
    "Id"              UUID            NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"       UUID            NOT NULL,
    "UserId"          UUID            NOT NULL,
    "Feature"         VARCHAR(100)    NOT NULL,
    "Model"           VARCHAR(100)    NOT NULL,
    "PromptSummary"   VARCHAR(500)    NULL,
    "CreatedAtUtc"    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"    TIMESTAMPTZ     NULL,
    CONSTRAINT "PK_AIUsageRecords" PRIMARY KEY ("Id")
);

-- Index for daily per-user lookups
CREATE INDEX IF NOT EXISTS "IX_AIUsageRecords_UserId_Feature_CreatedAt"
    ON "AIUsageRecords" ("UserId", "Feature", "CreatedAtUtc" DESC);

-- Index for monthly per-company lookups
CREATE INDEX IF NOT EXISTS "IX_AIUsageRecords_CompanyId_Feature_CreatedAt"
    ON "AIUsageRecords" ("CompanyId", "Feature", "CreatedAtUtc" DESC);
