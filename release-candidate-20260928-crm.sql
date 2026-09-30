-- ============================================================================
-- FLORAPRISE
-- Production Release Candidate Migration
-- Date: 2026-09-28
--
-- PURPOSE:
-- CRM Phase 2 production persistence.
--
-- VERIFIED PRODUCTION STATE:
-- CrmEnquiries does not exist.
-- OrderItems.ProductId is already nullable.
-- Payments.PaymentType already exists with default 'SaleTender'.
-- DemoRequests.PhoneNumber already exists.
--
-- ONLY CHANGE:
-- Create CrmEnquiries and required indexes.
-- ============================================================================

BEGIN;

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

CREATE UNIQUE INDEX IF NOT EXISTS
    "IX_CrmEnquiries_CompanyId_ClientSyncId"
ON "CrmEnquiries" ("CompanyId", "ClientSyncId");

CREATE INDEX IF NOT EXISTS
    "IX_CrmEnquiries_CompanyId_CustomerId"
ON "CrmEnquiries" ("CompanyId", "CustomerId");

CREATE INDEX IF NOT EXISTS
    "IX_CrmEnquiries_CompanyId_Status"
ON "CrmEnquiries" ("CompanyId", "Status");

CREATE INDEX IF NOT EXISTS
    "IX_CrmEnquiries_CompanyId_NextFollowUpAtUtc"
ON "CrmEnquiries" ("CompanyId", "NextFollowUpAtUtc");

CREATE INDEX IF NOT EXISTS
    "IX_CrmEnquiries_CompanyId_CreatedAtUtc"
ON "CrmEnquiries" ("CompanyId", "CreatedAtUtc");

COMMIT;