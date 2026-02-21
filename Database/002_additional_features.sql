-- =====================================================
-- ADDITIONAL TABLES FOR NEW FEATURES
-- Run this after sumpooj_complete_schema.sql
-- =====================================================

-- ─── Delivery Zones ─────────────────────────────────
CREATE TABLE IF NOT EXISTS "DeliveryZones" (
    "Id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL REFERENCES "Companies"("Id"),
    "Name" varchar(100) NOT NULL,
    "Code" varchar(20) NOT NULL,
    "ZipCodes" text,
    "Cities" text,
    "FreeDeliveryThreshold" decimal(18,2),
    "DeliveryFee" decimal(18,2) NOT NULL DEFAULT 0,
    "SameDayFee" decimal(18,2) NOT NULL DEFAULT 0,
    "ExpressFee" decimal(18,2) NOT NULL DEFAULT 0,
    "EstimatedMinutes" integer NOT NULL DEFAULT 30,
    "DistanceKm" decimal(10,2),
    "SortOrder" integer NOT NULL DEFAULT 0,
    "IsActive" boolean NOT NULL DEFAULT true,
    "Notes" text,
    "CreatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "IX_DeliveryZones_CompanyId" ON "DeliveryZones" ("CompanyId");

-- ─── Wire Orders (FTD, BloomNation, Teleflora) ──────
CREATE TABLE IF NOT EXISTS "WireOrders" (
    "Id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL REFERENCES "Companies"("Id"),
    "WireService" integer NOT NULL, -- 0=FTD, 1=Teleflora, 2=BloomNation, etc.
    "WireOrderNumber" varchar(100) NOT NULL,
    "ReceivedDate" timestamp NOT NULL,
    "DeliveryDate" timestamp NOT NULL,
    "TimeSlot" varchar(50),
    "Status" integer NOT NULL DEFAULT 0, -- 0=Received, 1=Accepted, 2=InProgress, 3=Fulfilled, 4=Rejected, 5=Cancelled
    
    -- Sender Info
    "SenderName" varchar(200),
    "SenderPhone" varchar(50),
    "SenderEmail" varchar(200),
    
    -- Recipient Info
    "RecipientName" varchar(200) NOT NULL,
    "RecipientPhone" varchar(50) NOT NULL,
    "DeliveryAddress" text NOT NULL,
    "DeliveryCity" varchar(100),
    "DeliveryZipCode" varchar(20),
    
    "CardMessage" text,
    "DeliveryInstructions" text,
    
    -- Pricing
    "WireAmount" decimal(18,2) NOT NULL,
    "WireServiceFee" decimal(18,2) NOT NULL DEFAULT 0,
    "NetAmount" decimal(18,2) NOT NULL,
    "FulfillmentCost" decimal(18,2),
    
    -- Product Info
    "ProductDescription" text,
    "WireProductCode" varchar(100),
    "SubstitutionNotes" text,
    
    "LinkedOrderId" uuid REFERENCES "Orders"("Id"),
    "AssignedToUserId" uuid,
    "InternalNotes" text,
    "ConfirmationCode" varchar(100),
    "FulfilledAt" timestamp,
    "RejectionReason" text,
    
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "IX_WireOrders_CompanyId" ON "WireOrders" ("CompanyId");
CREATE INDEX "IX_WireOrders_WireOrderNumber" ON "WireOrders" ("WireOrderNumber");
CREATE INDEX "IX_WireOrders_DeliveryDate" ON "WireOrders" ("DeliveryDate");
CREATE INDEX "IX_WireOrders_Status" ON "WireOrders" ("Status");

-- ─── Proposals (Event Quotes) ───────────────────────
CREATE TABLE IF NOT EXISTS "Proposals" (
    "Id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL REFERENCES "Companies"("Id"),
    "EventId" uuid NOT NULL REFERENCES "Events"("Id"),
    "ProposalNumber" varchar(50) NOT NULL,
    "Title" varchar(200) NOT NULL,
    "Version" integer NOT NULL DEFAULT 1,
    "Status" integer NOT NULL DEFAULT 0, -- 0=Draft, 1=Sent, 2=Viewed, 3=RevisionRequested, 4=Accepted, 5=Declined, 6=Expired
    "ValidUntil" timestamp,
    "SentAt" timestamp,
    "RespondedAt" timestamp,
    
    -- Client Info
    "ClientName" varchar(200) NOT NULL,
    "ClientEmail" varchar(200) NOT NULL,
    "ClientPhone" varchar(50),
    
    -- Content
    "Introduction" text,
    "TermsAndConditions" text,
    "PaymentTerms" text,
    "ClientNotes" text,
    "InternalNotes" text,
    
    -- Pricing
    "SubTotal" decimal(18,2) NOT NULL DEFAULT 0,
    "DiscountAmount" decimal(18,2) NOT NULL DEFAULT 0,
    "DiscountPercent" decimal(5,2) NOT NULL DEFAULT 0,
    "TaxAmount" decimal(18,2) NOT NULL DEFAULT 0,
    "TotalAmount" decimal(18,2) NOT NULL DEFAULT 0,
    "DepositAmount" decimal(18,2) NOT NULL DEFAULT 0,
    "DepositPercent" decimal(5,2) NOT NULL DEFAULT 0,
    
    "ClientFeedback" text,
    "DeclineReason" text,
    "CreatedByUserId" uuid NOT NULL,
    
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "IX_Proposals_CompanyId" ON "Proposals" ("CompanyId");
CREATE INDEX "IX_Proposals_EventId" ON "Proposals" ("EventId");
CREATE INDEX "IX_Proposals_ProposalNumber" ON "Proposals" ("ProposalNumber");

-- ─── Proposal Items ─────────────────────────────────
CREATE TABLE IF NOT EXISTS "ProposalItems" (
    "Id" uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    "ProposalId" uuid NOT NULL REFERENCES "Proposals"("Id") ON DELETE CASCADE,
    "Category" varchar(100) NOT NULL,
    "Description" text NOT NULL,
    "ProductId" uuid REFERENCES "Products"("Id"),
    "Quantity" integer NOT NULL DEFAULT 1,
    "UnitPrice" decimal(18,2) NOT NULL,
    "TotalPrice" decimal(18,2) NOT NULL,
    "Notes" text,
    "SortOrder" integer NOT NULL DEFAULT 0,
    "CreatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX "IX_ProposalItems_ProposalId" ON "ProposalItems" ("ProposalId");

-- =====================================================
-- COMPLETION
-- =====================================================
