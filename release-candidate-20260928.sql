-- ============================================================================
-- FLORAPRISE
-- Production Release Candidate Migration
-- Date: 2026-09-28
--
-- Purpose:
-- CRM Phase 2 + POS quotation & payment schema support for PostgreSQL 18.
--
-- Changes Included:
-- 1. Create table "CrmEnquiries" and required multi-tenant indexes.
-- 2. Alter column "OrderItems"."ProductId" to DROP NOT NULL (supports custom quote items).
-- 3. Add column "Payments"."PaymentType" (varchar(32) NOT NULL DEFAULT 'SaleTender').
--
-- Explicitly Excluded:
-- - Floraprise Library tables and catalog seed data (deferred).
-- - DemoRequests.PhoneNumber (already exists in production).
-- - All INSERT / UPDATE / DELETE data operations.
--
-- Idempotency:
-- Fully idempotent (safe to run once, safe to re-run).
--
-- IMPORTANT:
-- Always review and backup the production database (pg_dump) prior to execution.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. CRM ENQUIRIES TABLE & INDEXES
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS "CrmEnquiries" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "CustomerId" uuid NOT NULL,
    "ClientSyncId" character varying(64) NOT NULL,
    "Category" character varying(50) NOT NULL,
    "Requirement" text NOT NULL,
    "EventDate" timestamp with time zone,
    "BudgetAmount" numeric(18,2),
    "Location" character varying(255),
    "Notes" text,
    "Status" character varying(32) NOT NULL,
    "NextAction" character varying(255) NOT NULL,
    "NextFollowUpAtUtc" timestamp with time zone,
    "LinkedTaskId" uuid,
    "QuoteOrderId" uuid,
    "ConvertedOrderId" uuid,
    "LostReason" character varying(255),
    "DeletedAtUtc" timestamp with time zone,
    "CreatedAtUtc" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_CrmEnquiries" PRIMARY KEY ("Id")
);

-- Unique index for idempotent client synchronization per company
CREATE UNIQUE INDEX IF NOT EXISTS "IX_CrmEnquiries_CompanyId_ClientSyncId"
    ON "CrmEnquiries" ("CompanyId", "ClientSyncId");

-- Tenant and customer lookup index
CREATE INDEX IF NOT EXISTS "IX_CrmEnquiries_CompanyId_CustomerId"
    ON "CrmEnquiries" ("CompanyId", "CustomerId");

-- Pipeline status filtering index
CREATE INDEX IF NOT EXISTS "IX_CrmEnquiries_CompanyId_Status"
    ON "CrmEnquiries" ("CompanyId", "Status");

-- Today and upcoming follow-up scheduling index
CREATE INDEX IF NOT EXISTS "IX_CrmEnquiries_CompanyId_NextFollowUpAtUtc"
    ON "CrmEnquiries" ("CompanyId", "NextFollowUpAtUtc");

-- Creation timestamp sorting index
CREATE INDEX IF NOT EXISTS "IX_CrmEnquiries_CompanyId_CreatedAtUtc"
    ON "CrmEnquiries" ("CompanyId", "CreatedAtUtc");


-- ----------------------------------------------------------------------------
-- 2. ORDER ITEMS: MAKE ProductId NULLABLE FOR CUSTOM / SERVICE QUOTE LINES
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public'
          AND table_name = 'OrderItems' 
          AND column_name = 'ProductId' 
          AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE "OrderItems" ALTER COLUMN "ProductId" DROP NOT NULL;
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- 3. PAYMENTS: ADD PaymentType COLUMN WITH DEFAULT 'SaleTender'
-- ----------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public'
          AND table_name = 'Payments' 
          AND column_name = 'PaymentType'
    ) THEN
        ALTER TABLE "Payments" 
            ADD COLUMN "PaymentType" character varying(32) NOT NULL DEFAULT 'SaleTender';
    END IF;
END $$;

COMMIT;


-- ============================================================================
-- VERIFICATION QUERIES (READ-ONLY INSPECTION — DO NOT EXECUTE AS PART OF MIGRATION)
-- ============================================================================

/*
-- A. Verify CrmEnquiries table existence:
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'CrmEnquiries';

-- B. Verify all CrmEnquiries columns and types:
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'CrmEnquiries'
ORDER BY ordinal_position;

-- C. Verify all 5 CrmEnquiries indexes:
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'public' AND tablename = 'CrmEnquiries'
ORDER BY indexname;

-- D. Verify OrderItems.ProductId is nullable:
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'OrderItems' AND column_name = 'ProductId';

-- E. Verify Payments.PaymentType definition:
SELECT table_name, column_name, data_type, character_maximum_length, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'Payments' AND column_name = 'PaymentType';

-- F. Verify DemoRequests.PhoneNumber is intact:
SELECT table_name, column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'DemoRequests' AND column_name = 'PhoneNumber';
*/
