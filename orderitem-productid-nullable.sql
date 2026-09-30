CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" character varying(150) NOT NULL,
    "ProductVersion" character varying(32) NOT NULL,
    CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY ("MigrationId")
);

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Accounts" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Code" text NOT NULL,
        "Name" text NOT NULL,
        "Type" text NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Accounts" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AIUsageRecords" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Feature" text NOT NULL,
        "Model" text NOT NULL,
        "PromptSummary" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_AIUsageRecords" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetRoles" (
        "Id" uuid NOT NULL,
        "Name" character varying(256),
        "NormalizedName" character varying(256),
        "ConcurrencyStamp" text,
        CONSTRAINT "PK_AspNetRoles" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetUsers" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid,
        "IsActive" boolean NOT NULL,
        "UserName" character varying(256),
        "NormalizedUserName" character varying(256),
        "Email" character varying(256),
        "NormalizedEmail" character varying(256),
        "EmailConfirmed" boolean NOT NULL,
        "PasswordHash" text,
        "SecurityStamp" text,
        "ConcurrencyStamp" text,
        "PhoneNumber" text,
        "PhoneNumberConfirmed" boolean NOT NULL,
        "TwoFactorEnabled" boolean NOT NULL,
        "LockoutEnd" timestamp with time zone,
        "LockoutEnabled" boolean NOT NULL,
        "AccessFailedCount" integer NOT NULL,
        CONSTRAINT "PK_AspNetUsers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AuditLogs" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "UserId" uuid,
        "UserName" text,
        "UserRole" text,
        "Action" text NOT NULL,
        "EntityType" text NOT NULL,
        "EntityId" uuid,
        "EntityName" text,
        "OldValues" text,
        "NewValues" text,
        "Description" text,
        "IpAddress" text,
        "UserAgent" text,
        "RequestPath" text,
        "HttpMethod" text,
        "Timestamp" timestamp with time zone NOT NULL,
        "DurationMs" bigint,
        "IsSuccess" boolean NOT NULL,
        "ErrorMessage" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_AuditLogs" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Companies" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Region" character varying(50) NOT NULL,
        "Email" character varying(200),
        "Phone" character varying(50),
        "Address" text,
        "ShortDescription" text,
        "LogoPath" character varying(500),
        "TimeZone" character varying(100) NOT NULL,
        "CurrencyCode" character varying(10) NOT NULL,
        "TaxIdentifier" character varying(100),
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_Companies" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Customers" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Email" character varying(200),
        "Phone" character varying(50),
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "DefaultCardMessage" text,
        "TotalOrders" integer NOT NULL DEFAULT 0,
        "CompanyId" uuid NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_Customers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "DayCloses" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "LocationId" uuid NOT NULL,
        "BusinessDate" timestamp with time zone NOT NULL,
        "Status" integer NOT NULL,
        "ClosedAt" timestamp with time zone NOT NULL,
        "ClosedByUserId" uuid NOT NULL,
        "TotalOrders" integer NOT NULL,
        "TotalSales" numeric NOT NULL,
        "TotalRefunds" numeric NOT NULL,
        "NetSales" numeric NOT NULL,
        "CashTotal" numeric NOT NULL,
        "CardTotal" numeric NOT NULL,
        "UpiTotal" numeric NOT NULL,
        "GiftCardTotal" numeric NOT NULL,
        "OtherPaymentsTotal" numeric NOT NULL,
        "ExpectedCash" numeric NOT NULL,
        "ActualCash" numeric NOT NULL,
        "CashVariance" numeric NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DayCloses" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Deliveries" (
        "Id" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "ScheduledDateTime" timestamp with time zone NOT NULL,
        "TimeSlot" text NOT NULL,
        "DeliveryAddress" text NOT NULL,
        "PostalCode" text,
        "DeliveryPersonId" uuid,
        "Status" integer NOT NULL,
        "DeliveryRouteId" uuid,
        "StopOrder" integer,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Deliveries" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "DeliveryRoutes" (
        "Id" uuid NOT NULL,
        "DeliveryPersonId" uuid NOT NULL,
        "RouteDate" timestamp with time zone NOT NULL,
        "Name" text NOT NULL,
        "Status" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DeliveryRoutes" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "DeliveryZones" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Code" text NOT NULL,
        "ZipCodes" text,
        "Cities" text,
        "FreeDeliveryThreshold" numeric,
        "DeliveryFee" numeric NOT NULL,
        "SameDayFee" numeric NOT NULL,
        "ExpressFee" numeric NOT NULL,
        "EstimatedMinutes" integer NOT NULL,
        "DistanceKm" numeric,
        "SortOrder" integer NOT NULL,
        "IsActive" boolean NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DeliveryZones" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "DemoRequests" (
        "Id" uuid NOT NULL,
        "FullName" text NOT NULL,
        "BusinessEmail" text NOT NULL,
        "BusinessType" text,
        "CurrentSoftware" text,
        "Notes" text,
        "Status" integer NOT NULL,
        "Comments" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DemoRequests" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Events" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "EventName" text NOT NULL,
        "EventType" integer NOT NULL,
        "EventDate" timestamp with time zone NOT NULL,
        "Status" integer NOT NULL,
        "IsActive" boolean NOT NULL,
        "ClientName" text NOT NULL,
        "ClientPhone" text NOT NULL,
        "ClientEmail" text,
        "VenueName" text NOT NULL,
        "VenueAddress" text,
        "EstimatedGuestCount" integer,
        "Budget" numeric,
        "ColorTheme" text,
        "MoodNotes" text,
        "MoodBoardLink" text,
        "AssignedDesignerId" uuid,
        "InternalNotes" text,
        "TotalProposedAmount" numeric NOT NULL,
        "TotalPaidAmount" numeric NOT NULL,
        "EstimatedCost" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Events" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Expenses" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "LocationId" uuid,
        "AccountId" uuid,
        "Category" text NOT NULL,
        "Amount" numeric NOT NULL,
        "Description" text,
        "ExpenseDate" timestamp with time zone NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Expenses" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "FinishedGoodsBatches" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "RecipeId" uuid NOT NULL,
        "RecipeName" text NOT NULL,
        "BatchCode" text NOT NULL,
        "Barcode" text NOT NULL,
        "QuantityProduced" integer NOT NULL,
        "QuantityAvailable" integer NOT NULL,
        "ExpectedExpiry" timestamp with time zone NOT NULL,
        "LocationId" uuid NOT NULL,
        "LocationName" text NOT NULL,
        "TotalCost" numeric NOT NULL,
        "Status" integer NOT NULL,
        "ProducedAt" timestamp with time zone NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_FinishedGoodsBatches" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "FloralRecipes" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Category" text,
        "SellingPrice" numeric NOT NULL,
        "LaborCost" numeric NOT NULL,
        "SampleImages" text,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_FloralRecipes" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "GiftCards" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Code" text NOT NULL,
        "InitialBalance" numeric NOT NULL,
        "CurrentBalance" numeric NOT NULL,
        "Status" integer NOT NULL,
        "IssuedAt" timestamp with time zone NOT NULL,
        "ExpiresAt" timestamp with time zone,
        "LastUsedAt" timestamp with time zone,
        "RecipientName" text,
        "RecipientEmail" text,
        "RecipientPhone" text,
        "SenderName" text,
        "PersonalMessage" text,
        "DesignTheme" text,
        "PurchasedByCustomerId" uuid,
        "SourceOrderId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_GiftCards" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "InventoryAdjustments" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "BatchId" uuid,
        "AdjustmentType" integer NOT NULL,
        "Quantity" integer NOT NULL,
        "CostPerUnit" numeric NOT NULL,
        "TotalValue" numeric NOT NULL,
        "Reason" text NOT NULL,
        "AdjustedByUserId" uuid NOT NULL,
        "AdjustmentDate" timestamp with time zone NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_InventoryAdjustments" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "JournalEntries" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "LocationId" uuid,
        "EntryDate" timestamp with time zone NOT NULL,
        "Reference" text NOT NULL,
        "ReferenceType" text NOT NULL,
        "Description" text NOT NULL,
        "Debit" numeric NOT NULL,
        "Credit" numeric NOT NULL,
        "AccountId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_JournalEntries" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Locations" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Code" text NOT NULL,
        "LocationType" integer NOT NULL,
        "Address" text,
        "IsActive" boolean NOT NULL,
        "IsDefault" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Locations" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Payments" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "LocationId" uuid,
        "Method" integer NOT NULL,
        "Amount" numeric NOT NULL,
        "Status" integer NOT NULL,
        "TransactionId" text,
        "AuthorizationCode" text,
        "CardBrand" text,
        "Last4" text,
        "TerminalId" text,
        "TerminalResponseCode" text,
        "TerminalMessage" text,
        "ReceiptData" text,
        "ProcessedByUserId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Payments" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductBatches" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "BatchNumber" text NOT NULL,
        "QuantityReceived" integer NOT NULL,
        "QuantityRemaining" integer NOT NULL,
        "CostPerUnit" numeric NOT NULL,
        "SellingPricePerUnit" numeric NOT NULL,
        "ReceivedDate" timestamp with time zone NOT NULL,
        "ExpiryDate" timestamp with time zone,
        "SupplierId" uuid,
        "LocationId" uuid,
        "StorageLocation" text,
        "PurchaseOrderId" uuid,
        "IsActive" boolean NOT NULL,
        "StemsInStock" integer NOT NULL,
        "UsedUnits" integer NOT NULL,
        "DamagedUnits" integer NOT NULL,
        "ReservedUnits" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductBatches" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductCategories" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "IsPerishable" boolean NOT NULL,
        "TrackBatchByDefault" boolean NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductCategories" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductionJobs" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "Description" text NOT NULL,
        "Status" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductionJobs" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductionMaintenanceLogs" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "FinishedBatchId" uuid NOT NULL,
        "BatchCode" text NOT NULL,
        "Notes" text,
        "PerformedAt" timestamp with time zone NOT NULL,
        "PerformedBy" text,
        "ReplacementsJson" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductionMaintenanceLogs" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductionWastageLogs" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Quantity" integer NOT NULL,
        "Reason" integer NOT NULL,
        "RelatedFinishedBatchId" uuid,
        "RelatedBatchCode" text,
        "CreatedBy" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductionWastageLogs" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Proposals" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "EventId" uuid NOT NULL,
        "ProposalNumber" text NOT NULL,
        "Title" text NOT NULL,
        "Version" integer NOT NULL,
        "Status" integer NOT NULL,
        "ValidUntil" timestamp with time zone,
        "SentAt" timestamp with time zone,
        "RespondedAt" timestamp with time zone,
        "ClientName" text NOT NULL,
        "ClientEmail" text NOT NULL,
        "ClientPhone" text,
        "Introduction" text,
        "TermsAndConditions" text,
        "PaymentTerms" text,
        "ClientNotes" text,
        "InternalNotes" text,
        "SubTotal" numeric NOT NULL,
        "DiscountAmount" numeric NOT NULL,
        "DiscountPercent" numeric NOT NULL,
        "TaxAmount" numeric NOT NULL,
        "TotalAmount" numeric NOT NULL,
        "DepositAmount" numeric NOT NULL,
        "DepositPercent" numeric NOT NULL,
        "ClientFeedback" text,
        "DeclineReason" text,
        "CreatedByUserId" uuid NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Proposals" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "PurchaseOrders" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "SupplierId" uuid NOT NULL,
        "OrderNumber" text NOT NULL,
        "OrderDate" timestamp with time zone NOT NULL,
        "ExpectedDeliveryDate" timestamp with time zone NOT NULL,
        "ActualDeliveryDate" timestamp with time zone,
        "Status" integer NOT NULL,
        "IsActive" boolean NOT NULL,
        "TotalAmount" numeric NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_PurchaseOrders" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "RefreshTokens" (
        "Id" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "Token" character varying(256) NOT NULL,
        "ExpiresAtUtc" timestamp with time zone NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "RevokedAtUtc" timestamp with time zone,
        "IsRevoked" boolean NOT NULL,
        "ReplacedByToken" text,
        CONSTRAINT "PK_RefreshTokens" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Refunds" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "RefundNumber" text NOT NULL,
        "Method" integer NOT NULL,
        "Status" integer NOT NULL,
        "Reason" text NOT NULL,
        "RefundedAmount" numeric NOT NULL,
        "ProcessedByUserId" uuid NOT NULL,
        "TransactionId" text,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Refunds" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "SalesOrders" (
        "Id" uuid NOT NULL,
        "DeliveryAddressLine1" text NOT NULL,
        "DeliveryAddressLine2" text,
        "City" text NOT NULL,
        "PostalCode" text NOT NULL,
        "State" text,
        "CompanyId" uuid NOT NULL,
        "CustomerId" uuid NOT NULL,
        "OrderNumber" text NOT NULL,
        "OrderType" integer NOT NULL,
        "Status" integer NOT NULL,
        "InvoiceNumber" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_SalesOrders" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Shifts" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "LocationId" uuid NOT NULL,
        "OpenedByUserId" uuid NOT NULL,
        "OpenedByName" text NOT NULL,
        "OpenedAt" timestamp with time zone NOT NULL,
        "OpeningCash" numeric NOT NULL,
        "ClosedByUserId" uuid,
        "ClosedByName" text,
        "ClosedAt" timestamp with time zone,
        "ClosingCashCount" numeric,
        "CashDifference" numeric,
        "CashSales" numeric NOT NULL,
        "CardSales" numeric NOT NULL,
        "UpiSales" numeric NOT NULL,
        "GiftCardSales" numeric NOT NULL,
        "OtherSales" numeric NOT NULL,
        "TotalRefunds" numeric NOT NULL,
        "PaidOuts" numeric NOT NULL,
        "TransactionCount" integer NOT NULL,
        "Status" integer NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Shifts" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "StaffAttendanceRecords" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "StaffId" uuid NOT NULL,
        "CheckInUtc" timestamp with time zone NOT NULL,
        "CheckOutUtc" timestamp with time zone,
        "Status" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_StaffAttendanceRecords" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "StockMovements" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "MovementType" integer NOT NULL,
        "Quantity" integer NOT NULL,
        "MovementDate" timestamp with time zone NOT NULL,
        "Reason" text,
        "OrderId" uuid,
        "PurchaseOrderId" uuid,
        "UserId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_StockMovements" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Suppliers" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "ContactPerson" text,
        "Email" text,
        "Phone" text,
        "Address" text,
        "IsActive" boolean NOT NULL,
        "Rating" integer NOT NULL,
        "Notes" text,
        "PaymentTermsDays" integer NOT NULL,
        "TaxIdentifier" text,
        "LastOrderDate" timestamp with time zone,
        "TotalOrdersCount" integer NOT NULL,
        "TotalSpentAmount" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Suppliers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Tasks" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "LocationId" uuid NOT NULL,
        "Title" text NOT NULL,
        "Description" text,
        "Status" integer NOT NULL,
        "Priority" integer NOT NULL,
        "AssignedToStaffId" uuid NOT NULL,
        "DueDate" timestamp with time zone,
        "RelatedEntityType" integer,
        "RelatedEntityId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Tasks" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE tax_rules (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "CountryCode" character varying(10) NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Rate" numeric(8,4) NOT NULL,
        "IsInclusive" boolean NOT NULL DEFAULT FALSE,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_tax_rules" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "UserDashboardPreferences" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "UserId" uuid NOT NULL,
        "VisibleModules" text NOT NULL,
        "ModuleOrder" text NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_UserDashboardPreferences" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "WireOrders" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "WireService" integer NOT NULL,
        "WireOrderNumber" text NOT NULL,
        "ReceivedDate" timestamp with time zone NOT NULL,
        "DeliveryDate" timestamp with time zone NOT NULL,
        "TimeSlot" text,
        "Status" integer NOT NULL,
        "SenderName" text,
        "SenderPhone" text,
        "SenderEmail" text,
        "RecipientName" text NOT NULL,
        "RecipientPhone" text NOT NULL,
        "DeliveryAddress" text NOT NULL,
        "DeliveryCity" text,
        "DeliveryZipCode" text,
        "CardMessage" text,
        "DeliveryInstructions" text,
        "WireAmount" numeric NOT NULL,
        "WireServiceFee" numeric NOT NULL,
        "NetAmount" numeric NOT NULL,
        "FulfillmentCost" numeric,
        "ProductDescription" text,
        "WireProductCode" text,
        "SubstitutionNotes" text,
        "LinkedOrderId" uuid,
        "AssignedToUserId" uuid,
        "InternalNotes" text,
        "ConfirmationCode" text,
        "FulfilledAt" timestamp with time zone,
        "RejectionReason" text,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_WireOrders" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetRoleClaims" (
        "Id" integer GENERATED BY DEFAULT AS IDENTITY,
        "RoleId" uuid NOT NULL,
        "ClaimType" text,
        "ClaimValue" text,
        CONSTRAINT "PK_AspNetRoleClaims" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AspNetRoleClaims_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetUserClaims" (
        "Id" integer GENERATED BY DEFAULT AS IDENTITY,
        "UserId" uuid NOT NULL,
        "ClaimType" text,
        "ClaimValue" text,
        CONSTRAINT "PK_AspNetUserClaims" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_AspNetUserClaims_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetUserLogins" (
        "LoginProvider" text NOT NULL,
        "ProviderKey" text NOT NULL,
        "ProviderDisplayName" text,
        "UserId" uuid NOT NULL,
        CONSTRAINT "PK_AspNetUserLogins" PRIMARY KEY ("LoginProvider", "ProviderKey"),
        CONSTRAINT "FK_AspNetUserLogins_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetUserRoles" (
        "UserId" uuid NOT NULL,
        "RoleId" uuid NOT NULL,
        CONSTRAINT "PK_AspNetUserRoles" PRIMARY KEY ("UserId", "RoleId"),
        CONSTRAINT "FK_AspNetUserRoles_AspNetRoles_RoleId" FOREIGN KEY ("RoleId") REFERENCES "AspNetRoles" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_AspNetUserRoles_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "AspNetUserTokens" (
        "UserId" uuid NOT NULL,
        "LoginProvider" text NOT NULL,
        "Name" text NOT NULL,
        "Value" text,
        CONSTRAINT "PK_AspNetUserTokens" PRIMARY KEY ("UserId", "LoginProvider", "Name"),
        CONSTRAINT "FK_AspNetUserTokens_AspNetUsers_UserId" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Staff" (
        "Id" uuid NOT NULL,
        "DriverStatus" integer NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Role" integer NOT NULL,
        "Email" text,
        "Phone" text,
        "UserId" uuid,
        "IdentityUserId" uuid,
        "IsActive" boolean NOT NULL,
        "CommissionType" integer,
        "CommissionRate" numeric,
        "HourlyRate" numeric,
        "PrimaryLocationId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Staff" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Staff_AspNetUsers_IdentityUserId" FOREIGN KEY ("IdentityUserId") REFERENCES "AspNetUsers" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "PaymentGatewayConfigs" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "GatewayType" integer NOT NULL,
        "Name" character varying(100) NOT NULL,
        "PublicKey" character varying(500) NOT NULL,
        "SecretKeyEncrypted" character varying(1000) NOT NULL,
        "WebhookSecretEncrypted" character varying(500),
        "MerchantId" character varying(200),
        "Environment" integer NOT NULL,
        "Currency" character varying(3) NOT NULL,
        "SupportedCurrencies" character varying(100),
        "IsActive" boolean NOT NULL,
        "IsDefault" boolean NOT NULL,
        "AdditionalConfig" jsonb,
        "WebhookUrl" character varying(500),
        "LastTestedAt" timestamptz,
        "LastTestSuccessful" boolean,
        "CreatedAt" timestamptz NOT NULL,
        "UpdatedAt" timestamptz,
        CONSTRAINT "PK_PaymentGatewayConfigs" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PaymentGatewayConfigs_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "RecipeComponents" (
        "Id" uuid NOT NULL,
        "RecipeId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "QuantityRequired" integer NOT NULL,
        "UnitCost" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_RecipeComponents" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_RecipeComponents_FloralRecipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES "FloralRecipes" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Orders" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "CustomerId" uuid NOT NULL,
        "LocationId" uuid,
        "OrderNumber" text NOT NULL,
        "OrderDate" timestamp with time zone NOT NULL,
        "DeliveryDate" timestamp with time zone NOT NULL,
        "Status" integer NOT NULL,
        "PaymentStatus" integer NOT NULL,
        "FulfillmentStatus" integer NOT NULL,
        "OrderSource" integer NOT NULL,
        "OrderType" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL,
        "TimeSlot" text,
        "DeliveryAddress" text,
        "RecipientName" text,
        "RecipientPhone" text,
        "CardMessage" text,
        "DeliveryPriority" integer NOT NULL,
        "SubTotal" numeric NOT NULL,
        "DeliveryFee" numeric NOT NULL,
        "TaxAmount" numeric NOT NULL,
        "DiscountAmount" numeric NOT NULL,
        "TotalAmount" numeric NOT NULL,
        "AssignedToUserId" uuid,
        "DeliveryPersonId" uuid,
        "InternalNotes" text,
        "InvoiceNumber" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Orders" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Orders_Customers_CustomerId" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_Orders_Locations_LocationId" FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProductionMaterialUsages" (
        "Id" uuid NOT NULL,
        "JobId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "UnitsUsed" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProductionMaterialUsages" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ProductionMaterialUsages_ProductionJobs_JobId" FOREIGN KEY ("JobId") REFERENCES "ProductionJobs" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "ProposalItems" (
        "Id" uuid NOT NULL,
        "ProposalId" uuid NOT NULL,
        "Category" text NOT NULL,
        "Description" text NOT NULL,
        "ProductId" uuid,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric NOT NULL,
        "TotalPrice" numeric NOT NULL,
        "Notes" text,
        "SortOrder" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ProposalItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ProposalItems_Proposals_ProposalId" FOREIGN KEY ("ProposalId") REFERENCES "Proposals" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "PurchaseOrderItems" (
        "Id" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric NOT NULL,
        "TotalPrice" numeric NOT NULL,
        "ReceivedQuantity" integer NOT NULL,
        "Sku" text,
        "Unit" text,
        "IsPerishable" boolean NOT NULL,
        "ShelfLifeDays" integer NOT NULL,
        "BatchNumber" text,
        "ExpiryDate" timestamp with time zone,
        "StorageLocation" text,
        "PurchaseOrderId" uuid,
        CONSTRAINT "PK_PurchaseOrderItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PurchaseOrderItems_PurchaseOrders_PurchaseOrderId" FOREIGN KEY ("PurchaseOrderId") REFERENCES "PurchaseOrders" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "RefundItems" (
        "Id" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric NOT NULL,
        "RefundAmount" numeric NOT NULL,
        "Restock" boolean NOT NULL,
        "RefundId" uuid,
        CONSTRAINT "PK_RefundItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_RefundItems_Refunds_RefundId" FOREIGN KEY ("RefundId") REFERENCES "Refunds" ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "SalesOrderItems" (
        "Id" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric NOT NULL,
        "TotalPrice" numeric NOT NULL,
        "SalesOrderId" uuid,
        CONSTRAINT "PK_SalesOrderItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_SalesOrderItems_SalesOrders_SalesOrderId" FOREIGN KEY ("SalesOrderId") REFERENCES "SalesOrders" ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "Products" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Sku" text NOT NULL,
        "Barcode" text,
        "Brand" text,
        "ProductType" integer NOT NULL,
        "Category" integer NOT NULL,
        "Description" text,
        "IsActive" boolean NOT NULL,
        "UnitOfMeasure" integer NOT NULL,
        "CategoryId" uuid,
        "TaxRuleId" uuid,
        "RetailPrice" numeric NOT NULL,
        "CostPrice" numeric NOT NULL,
        "WholesalePrice" numeric,
        "WeddingEventPrice" numeric,
        "TaxCategory" integer NOT NULL,
        "TrackInventory" boolean NOT NULL,
        "TrackBatch" boolean NOT NULL,
        "StockQuantity" integer NOT NULL,
        "MinimumStockLevel" integer NOT NULL,
        "ReorderLevel" integer NOT NULL,
        "IsPerishable" boolean NOT NULL,
        "ShelfLifeDays" integer,
        "ExpiryAlertDays" integer,
        "TemperatureNotes" text,
        "IsMultiUnit" boolean NOT NULL,
        "AvgUnitsPerStem" integer NOT NULL,
        "Color" text,
        "Variety" text,
        "FlowerGrade" integer,
        "CountryOfOrigin" text,
        "SeasonalAvailability" integer NOT NULL,
        "EstimatedMinutesToAssemble" integer,
        "DefaultSupplierId" uuid,
        "LeadTimeDays" integer,
        "IncomeAccount" text,
        "ExpenseAccount" text,
        "AllowAsRawMaterial" boolean NOT NULL,
        "AvailableOnline" boolean NOT NULL,
        "CommissionEligible" boolean NOT NULL,
        "Tags" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Products" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Products_ProductCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "ProductCategories" ("Id") ON DELETE SET NULL,
        CONSTRAINT "FK_Products_tax_rules_TaxRuleId" FOREIGN KEY ("TaxRuleId") REFERENCES tax_rules ("Id") ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "OrderItems" (
        "Id" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric NOT NULL,
        "TotalPrice" numeric NOT NULL,
        "SpecialInstructions" text,
        "OrderId" uuid,
        CONSTRAINT "PK_OrderItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_OrderItems_Orders_OrderId" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE TABLE "PaymentTransactions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "PaymentGatewayConfigId" uuid NOT NULL,
        "OrderId" uuid,
        "TransactionRef" character varying(50) NOT NULL,
        "GatewayPaymentId" character varying(200),
        "GatewayOrderId" character varying(200),
        "Amount" numeric(18,2) NOT NULL,
        "Currency" character varying(3) NOT NULL,
        "Status" integer NOT NULL,
        "PaymentMethod" integer,
        "CardLast4" character varying(4),
        "CardBrand" character varying(20),
        "BankName" character varying(100),
        "UpiId" character varying(100),
        "WalletName" character varying(50),
        "CustomerEmail" character varying(200),
        "CustomerPhone" character varying(20),
        "FailureReason" character varying(500),
        "ErrorCode" character varying(50),
        "RefundedAmount" numeric(18,2) NOT NULL DEFAULT 0.0,
        "GatewayResponse" jsonb,
        "GatewayFee" numeric(18,4),
        "NetAmount" numeric(18,2),
        "AuthorizedAt" timestamptz,
        "CapturedAt" timestamptz,
        "CompletedAt" timestamptz,
        "FailedAt" timestamptz,
        "Metadata" jsonb,
        "CreatedAt" timestamptz NOT NULL,
        "UpdatedAt" timestamptz,
        CONSTRAINT "PK_PaymentTransactions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PaymentTransactions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_PaymentTransactions_Orders_OrderId" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE SET NULL,
        CONSTRAINT "FK_PaymentTransactions_PaymentGatewayConfigs_PaymentGatewayCon~" FOREIGN KEY ("PaymentGatewayConfigId") REFERENCES "PaymentGatewayConfigs" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_AspNetRoleClaims_RoleId" ON "AspNetRoleClaims" ("RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "RoleNameIndex" ON "AspNetRoles" ("NormalizedName");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_AspNetUserClaims_UserId" ON "AspNetUserClaims" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_AspNetUserLogins_UserId" ON "AspNetUserLogins" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_AspNetUserRoles_RoleId" ON "AspNetUserRoles" ("RoleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "EmailIndex" ON "AspNetUsers" ("NormalizedEmail");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "UserNameIndex" ON "AspNetUsers" ("NormalizedUserName");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Companies_IsActive" ON "Companies" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Companies_Region" ON "Companies" ("Region");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Customers_IsActive" ON "Customers" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_FinishedGoodsBatches_CompanyId_BatchCode" ON "FinishedGoodsBatches" ("CompanyId", "BatchCode");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_OrderItems_OrderId" ON "OrderItems" ("OrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_Orders_CompanyId_OrderNumber" ON "Orders" ("CompanyId", "OrderNumber");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Orders_CustomerId" ON "Orders" ("CustomerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Orders_LocationId" ON "Orders" ("LocationId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentGatewayConfigs_CompanyId" ON "PaymentGatewayConfigs" ("CompanyId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_PaymentGatewayConfigs_CompanyId_GatewayType" ON "PaymentGatewayConfigs" ("CompanyId", "GatewayType");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentGatewayConfigs_CompanyId_IsDefault" ON "PaymentGatewayConfigs" ("CompanyId", "IsDefault") WHERE "IsDefault" = TRUE;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_CompanyId" ON "PaymentTransactions" ("CompanyId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_CompanyId_CreatedAt" ON "PaymentTransactions" ("CompanyId", "CreatedAt");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_CompanyId_GatewayPaymentId" ON "PaymentTransactions" ("CompanyId", "GatewayPaymentId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_CompanyId_Status" ON "PaymentTransactions" ("CompanyId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_OrderId" ON "PaymentTransactions" ("OrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PaymentTransactions_PaymentGatewayConfigId" ON "PaymentTransactions" ("PaymentGatewayConfigId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_PaymentTransactions_TransactionRef" ON "PaymentTransactions" ("TransactionRef");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_ProductBatches_CompanyId_BatchNumber" ON "ProductBatches" ("CompanyId", "BatchNumber");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_ProductCategories_CompanyId_Name" ON "ProductCategories" ("CompanyId", "Name");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_ProductionMaterialUsages_JobId" ON "ProductionMaterialUsages" ("JobId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Products_CategoryId" ON "Products" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_Products_CompanyId_Sku" ON "Products" ("CompanyId", "Sku");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Products_TaxRuleId" ON "Products" ("TaxRuleId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_ProposalItems_ProposalId" ON "ProposalItems" ("ProposalId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_PurchaseOrderItems_PurchaseOrderId" ON "PurchaseOrderItems" ("PurchaseOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_PurchaseOrders_CompanyId_OrderNumber" ON "PurchaseOrders" ("CompanyId", "OrderNumber");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_RecipeComponents_RecipeId" ON "RecipeComponents" ("RecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_RefreshTokens_Token" ON "RefreshTokens" ("Token");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_RefreshTokens_UserId" ON "RefreshTokens" ("UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_RefundItems_RefundId" ON "RefundItems" ("RefundId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_SalesOrderItems_SalesOrderId" ON "SalesOrderItems" ("SalesOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_Staff_IdentityUserId" ON "Staff" ("IdentityUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_tax_rules_CompanyId_CountryCode" ON tax_rules ("CompanyId", "CountryCode");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE INDEX "IX_tax_rules_IsActive" ON tax_rules ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    CREATE UNIQUE INDEX "IX_UserDashboardPreferences_CompanyId_UserId" ON "UserDashboardPreferences" ("CompanyId", "UserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260317130126_UnifyPhoneOrdersIntoOrders') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260317130126_UnifyPhoneOrdersIntoOrders', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260326211015_AddInventoryLedger') THEN
    CREATE TABLE "InventoryLedgers" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "Reference" text NOT NULL,
        "ReferenceType" text NOT NULL,
        "QuantityChange" integer NOT NULL,
        "BalanceAfter" integer NOT NULL,
        "Notes" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_InventoryLedgers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260326211015_AddInventoryLedger') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260326211015_AddInventoryLedger', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "SalesOrders" ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "PurchaseOrders" ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "Orders" ADD COLUMN IF NOT EXISTS "CustomerType" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "Orders" ADD COLUMN IF NOT EXISTS "DeliveryPincode" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "Orders" ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "Deliveries" ADD COLUMN IF NOT EXISTS "CompanyId" uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "CorporateClients" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "CustomerId" uuid NOT NULL,
        "Name" text NOT NULL,
        "BillingEmail" text NOT NULL,
        "Phone" text NULL,
        "CreditLimit" numeric NULL,
        "PaymentTerms" text NULL,
        "BillingCycle" text NOT NULL,
        "DefaultProductId" uuid NULL,
        "DefaultMessage" text NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_CorporateClients" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "InventoryReservations" (
        "Id" uuid NOT NULL,
        "SalesOrderId" uuid NOT NULL,
        "ProductBatchId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "ReservedUnits" integer NOT NULL,
        "Status" integer NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_InventoryReservations" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "CorporateEmployees" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ClientId" uuid NOT NULL,
        "Name" text NOT NULL,
        "DateOfBirth" timestamp with time zone NOT NULL,
        "Address" text NULL,
        "IsActive" boolean NOT NULL,
        "CorporateClientId" uuid NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_CorporateEmployees" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "CorporateInvoices" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ClientId" uuid NOT NULL,
        "StartDateUtc" timestamp with time zone NOT NULL,
        "EndDateUtc" timestamp with time zone NOT NULL,
        "TotalAmount" numeric NOT NULL,
        "Status" integer NOT NULL,
        "PaidAtUtc" timestamp with time zone NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_CorporateInvoices" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "CorporateOrderMetas" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "ClientId" uuid NOT NULL,
        "EmployeeId" uuid NULL,
        "BillingStatus" integer NOT NULL,
        "IsAutoCreated" boolean NOT NULL,
        "NeedsApproval" boolean NOT NULL,
        "AutomationDateUtc" timestamp with time zone NULL,
        "IsAccountingPosted" boolean NOT NULL,
        "IsInventoryPosted" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_CorporateOrderMetas" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN

    CREATE TABLE IF NOT EXISTS "CorporateInvoiceLines" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "InvoiceId" uuid NOT NULL,
        "OrderId" uuid NOT NULL,
        "OrderNumber" text NOT NULL,
        "OrderDateUtc" timestamp with time zone NOT NULL,
        "Amount" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone NULL,
        CONSTRAINT "PK_CorporateInvoiceLines" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE UNIQUE INDEX IF NOT EXISTS "IX_ProductBatches_ProductId_BatchNumber" ON "ProductBatches" ("ProductId", "BatchNumber");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateClients_CompanyId_Name" ON "CorporateClients" ("CompanyId", "Name");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateClients_CustomerId" ON "CorporateClients" ("CustomerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateEmployees_ClientId" ON "CorporateEmployees" ("ClientId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    ALTER TABLE "CorporateEmployees" ADD COLUMN IF NOT EXISTS "CorporateClientId" uuid NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateEmployees_CorporateClientId" ON "CorporateEmployees" ("CorporateClientId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateInvoiceLines_InvoiceId" ON "CorporateInvoiceLines" ("InvoiceId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateInvoices_ClientId" ON "CorporateInvoices" ("ClientId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_ClientId" ON "CorporateOrderMetas" ("ClientId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE UNIQUE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_CompanyId_OrderId" ON "CorporateOrderMetas" ("CompanyId", "OrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_EmployeeId" ON "CorporateOrderMetas" ("EmployeeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_OrderId" ON "CorporateOrderMetas" ("OrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    CREATE INDEX IF NOT EXISTS "IX_InventoryReservations_SalesOrderId_ProductBatchId_Status" ON "InventoryReservations" ("SalesOrderId", "ProductBatchId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260407165445_AddIsInventoryProcessed') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260407165445_AddIsInventoryProcessed', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobileCustomers" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "BusinessName" character varying(160) NOT NULL,
        "OwnerName" character varying(120) NOT NULL,
        "Mobile" character varying(32) NOT NULL,
        "Email" character varying(160),
        "City" character varying(100),
        "State" character varying(100),
        "Country" character varying(100),
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobileCustomers" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "SubscriptionPlans" (
        "Id" uuid NOT NULL,
        "Code" character varying(40) NOT NULL,
        "Name" character varying(100) NOT NULL,
        "PlanType" character varying(24) NOT NULL,
        "MonthlyPrice" numeric(18,2) NOT NULL,
        "AnnualPrice" numeric(18,2) NOT NULL,
        "LifetimePrice" numeric(18,2) NOT NULL,
        "TrialDays" integer NOT NULL,
        "OfflineDays" integer NOT NULL,
        "GraceDays" integer NOT NULL,
        "MaximumDevices" integer NOT NULL,
        "MaximumStaff" integer NOT NULL,
        "IncludedModulesJson" jsonb NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_SubscriptionPlans" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobileUsers" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileCustomerId" uuid NOT NULL,
        "FullName" character varying(120) NOT NULL,
        "Mobile" character varying(32) NOT NULL,
        "Email" character varying(160),
        "Status" character varying(24) NOT NULL,
        "PreferredLanguage" character varying(16) NOT NULL,
        "PreferredTheme" character varying(32) NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobileUsers" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MobileUsers_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileUsers_MobileCustomers_MobileCustomerId" FOREIGN KEY ("MobileCustomerId") REFERENCES "MobileCustomers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobileDevices" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileUserId" uuid NOT NULL,
        "DeviceId" character varying(120) NOT NULL,
        "Manufacturer" character varying(80),
        "Model" character varying(120),
        "Platform" character varying(24) NOT NULL,
        "OsVersion" character varying(80),
        "AppVersion" character varying(40) NOT NULL,
        "PushToken" character varying(512),
        "LastIpAddress" character varying(64),
        "LastLoginAtUtc" timestamptz,
        "LastHeartbeatAtUtc" timestamptz,
        "LastSyncAtUtc" timestamptz,
        "Status" character varying(24) NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobileDevices" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MobileDevices_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileDevices_MobileUsers_MobileUserId" FOREIGN KEY ("MobileUserId") REFERENCES "MobileUsers" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobileSubscriptions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileUserId" uuid NOT NULL,
        "SubscriptionPlanId" uuid NOT NULL,
        "Status" character varying(24) NOT NULL,
        "TrialStartUtc" timestamptz NOT NULL,
        "TrialEndUtc" timestamptz NOT NULL,
        "StartUtc" timestamptz,
        "EndUtc" timestamptz,
        "GraceEndUtc" timestamptz,
        "LastValidatedUtc" timestamptz,
        "AutoRenew" boolean NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobileSubscriptions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MobileSubscriptions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileSubscriptions_MobileUsers_MobileUserId" FOREIGN KEY ("MobileUserId") REFERENCES "MobileUsers" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileSubscriptions_SubscriptionPlans_SubscriptionPlanId" FOREIGN KEY ("SubscriptionPlanId") REFERENCES "SubscriptionPlans" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "DeviceSessions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileDeviceId" uuid NOT NULL,
        "RefreshToken" character varying(512) NOT NULL,
        "ExpiresAtUtc" timestamptz NOT NULL,
        "LastSeenAtUtc" timestamptz NOT NULL,
        "Status" character varying(24) NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_DeviceSessions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_DeviceSessions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_DeviceSessions_MobileDevices_MobileDeviceId" FOREIGN KEY ("MobileDeviceId") REFERENCES "MobileDevices" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "FeatureEntitlements" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileSubscriptionId" uuid NOT NULL,
        "FeatureKey" character varying(120) NOT NULL,
        "IsEnabled" boolean NOT NULL,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_FeatureEntitlements" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_FeatureEntitlements_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_FeatureEntitlements_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobileLicenses" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileDeviceId" uuid NOT NULL,
        "MobileSubscriptionId" uuid NOT NULL,
        "Status" character varying(24) NOT NULL,
        "IssuedAtUtc" timestamptz NOT NULL,
        "ExpiryUtc" timestamptz,
        "RevokedAtUtc" timestamptz,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobileLicenses" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MobileLicenses_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileLicenses_MobileDevices_MobileDeviceId" FOREIGN KEY ("MobileDeviceId") REFERENCES "MobileDevices" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobileLicenses_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "MobilePaymentTransactions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileSubscriptionId" uuid NOT NULL,
        "PaymentType" character varying(24) NOT NULL,
        "PaymentStatus" character varying(24) NOT NULL,
        "TransactionRef" character varying(100) NOT NULL,
        "GatewayOrderId" character varying(200),
        "GatewayPaymentId" character varying(200),
        "Amount" numeric(18,2) NOT NULL,
        "Currency" character varying(8) NOT NULL,
        "PaidAtUtc" timestamptz,
        "FailedAtUtc" timestamptz,
        "RefundedAtUtc" timestamptz,
        "FailureReason" character varying(400),
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_MobilePaymentTransactions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_MobilePaymentTransactions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_MobilePaymentTransactions_MobileSubscriptions_MobileSubscri~" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE TABLE "TrialHistory" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "MobileSubscriptionId" uuid NOT NULL,
        "ActionType" character varying(24) NOT NULL,
        "ActionAtUtc" timestamptz NOT NULL,
        "Notes" character varying(500),
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        "IsDeleted" boolean NOT NULL,
        "DeletedAtUtc" timestamptz,
        "CreatedBy" uuid,
        "UpdatedBy" uuid,
        "RowVersion" bytea NOT NULL,
        CONSTRAINT "PK_TrialHistory" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_TrialHistory_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_TrialHistory_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_DeviceSessions_CompanyId_MobileDeviceId_Status" ON "DeviceSessions" ("CompanyId", "MobileDeviceId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_DeviceSessions_MobileDeviceId" ON "DeviceSessions" ("MobileDeviceId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_DeviceSessions_RefreshToken" ON "DeviceSessions" ("RefreshToken");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_FeatureEntitlements_CompanyId_MobileSubscriptionId_FeatureK~" ON "FeatureEntitlements" ("CompanyId", "MobileSubscriptionId", "FeatureKey");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_FeatureEntitlements_MobileSubscriptionId" ON "FeatureEntitlements" ("MobileSubscriptionId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileCustomers_CompanyId_IsDeleted" ON "MobileCustomers" ("CompanyId", "IsDeleted");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobileCustomers_CompanyId_Mobile" ON "MobileCustomers" ("CompanyId", "Mobile");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobileDevices_CompanyId_MobileUserId_DeviceId" ON "MobileDevices" ("CompanyId", "MobileUserId", "DeviceId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileDevices_CompanyId_Status" ON "MobileDevices" ("CompanyId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileDevices_MobileUserId" ON "MobileDevices" ("MobileUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileLicenses_CompanyId_Status" ON "MobileLicenses" ("CompanyId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobileLicenses_MobileDeviceId" ON "MobileLicenses" ("MobileDeviceId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileLicenses_MobileSubscriptionId" ON "MobileLicenses" ("MobileSubscriptionId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobilePaymentTransactions_CompanyId_PaymentStatus" ON "MobilePaymentTransactions" ("CompanyId", "PaymentStatus");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobilePaymentTransactions_MobileSubscriptionId" ON "MobilePaymentTransactions" ("MobileSubscriptionId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobilePaymentTransactions_TransactionRef" ON "MobilePaymentTransactions" ("TransactionRef");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileSubscriptions_CompanyId_Status" ON "MobileSubscriptions" ("CompanyId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobileSubscriptions_MobileUserId" ON "MobileSubscriptions" ("MobileUserId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileSubscriptions_SubscriptionPlanId" ON "MobileSubscriptions" ("SubscriptionPlanId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_MobileUsers_CompanyId_Mobile" ON "MobileUsers" ("CompanyId", "Mobile");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileUsers_CompanyId_Status" ON "MobileUsers" ("CompanyId", "Status");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_MobileUsers_MobileCustomerId" ON "MobileUsers" ("MobileCustomerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE UNIQUE INDEX "IX_SubscriptionPlans_Code" ON "SubscriptionPlans" ("Code");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_SubscriptionPlans_IsActive_IsDeleted" ON "SubscriptionPlans" ("IsActive", "IsDeleted");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_TrialHistory_CompanyId_MobileSubscriptionId_ActionAtUtc" ON "TrialHistory" ("CompanyId", "MobileSubscriptionId", "ActionAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    CREATE INDEX "IX_TrialHistory_MobileSubscriptionId" ON "TrialHistory" ("MobileSubscriptionId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260727192413_MobileSubscriptionFoundation') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260727192413_MobileSubscriptionFoundation', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731173303_AddDeliveryTrackingTables') THEN
    CREATE TABLE "DeliveryLocations" (
        "Id" uuid NOT NULL,
        "DeliveryId" uuid NOT NULL,
        "Latitude" double precision NOT NULL,
        "Longitude" double precision NOT NULL,
        "SpeedKph" double precision NOT NULL,
        "RecordedAt" timestamp with time zone NOT NULL,
        "DeliveryRouteId" uuid,
        "DriverId" uuid,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DeliveryLocations" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731173303_AddDeliveryTrackingTables') THEN
    CREATE TABLE "DeliveryProofs" (
        "Id" uuid NOT NULL,
        "DeliveryId" uuid NOT NULL,
        "PhotoUrl" text NOT NULL,
        "RecipientName" text,
        "Note" text,
        "RecordedAt" timestamp with time zone NOT NULL,
        "OTPCode" text,
        "OTPVerified" boolean NOT NULL,
        "OTPVerifiedAt" timestamp with time zone,
        "CompletionLatitude" double precision,
        "CompletionLongitude" double precision,
        "UploadedByUserId" uuid,
        "UploadedByUserName" text,
        "SignatureData" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DeliveryProofs" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731173303_AddDeliveryTrackingTables') THEN
    CREATE TABLE "DeliveryTimelines" (
        "Id" uuid NOT NULL,
        "DeliveryId" uuid NOT NULL,
        "Status" text NOT NULL,
        "Note" text,
        "RecordedAt" timestamp with time zone NOT NULL,
        "ChangedByUserId" uuid,
        "ChangedByUserName" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_DeliveryTimelines" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731173303_AddDeliveryTrackingTables') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260731173303_AddDeliveryTrackingTables', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731182502_FixDeliveryPersonFk') THEN
    ALTER TABLE "Deliveries" DROP CONSTRAINT IF EXISTS "FK_Deliveries_Users";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731182502_FixDeliveryPersonFk') THEN
    CREATE INDEX "IX_Deliveries_DeliveryPersonId" ON "Deliveries" ("DeliveryPersonId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731182502_FixDeliveryPersonFk') THEN
    ALTER TABLE "Deliveries" ADD CONSTRAINT "FK_Deliveries_Staff_DeliveryPersonId" FOREIGN KEY ("DeliveryPersonId") REFERENCES "Staff" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731182502_FixDeliveryPersonFk') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260731182502_FixDeliveryPersonFk', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    ALTER TABLE "Deliveries" ADD "CustomerEmail" character varying(256);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    ALTER TABLE "Deliveries" ADD "CustomerPhone" character varying(50);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    ALTER TABLE "Deliveries" ADD "DeliveryAddressLatitude" double precision;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    ALTER TABLE "Deliveries" ADD "DeliveryAddressLongitude" double precision;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    ALTER TABLE "Deliveries" ADD "TrackingToken" character varying(256);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260731205928_AddDeliveryTrackingFields') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260731205928_AddDeliveryTrackingFields', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Deliveries" RENAME COLUMN "DeliveryAddressLongitude" TO "DeliveryLongitude";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Deliveries" RENAME COLUMN "DeliveryAddressLatitude" TO "DeliveryLatitude";
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "SubscriptionPlans" ALTER COLUMN "IncludedModulesJson" TYPE text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "StaffAttendanceRecords" ALTER COLUMN "CheckInUtc" DROP NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "StaffAttendanceRecords" ADD "AttendanceDate" timestamp with time zone NOT NULL DEFAULT TIMESTAMPTZ '-infinity';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "StaffAttendanceRecords" ADD "Notes" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "StaffAttendanceRecords" ADD "OvertimeHours" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Orders" ADD "RewardPointsEarned" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Orders" ADD "RewardPointsRedeemed" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "MobileDevices" ADD "DeviceFingerprintHash" text NOT NULL DEFAULT '';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "MobileDevices" ADD "DeviceName" text NOT NULL DEFAULT '';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "MobileDevices" ADD "UserId" uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Expenses" ADD "ExpenseCategoryId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Expenses" ADD "PaymentMode" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Deliveries" ADD "CompletedAtUtc" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Deliveries" ADD "LastLocationUtc" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Deliveries" ADD "StartedAtUtc" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "AnniversaryMonthDay" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "BirthdayMonthDay" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "CompanyName" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "Department" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "LastOrderAtUtc" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "LastRewardActivityAtUtc" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "LifetimeRewardPoints" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "PendingPaymentAmount" numeric NOT NULL DEFAULT 0.0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "RedeemedRewardPoints" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Customers" ADD "RewardPoints" integer NOT NULL DEFAULT 0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "Associates" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "AssociateCode" text NOT NULL,
        "BusinessName" text NOT NULL,
        "ContactPerson" text,
        "Phone" text NOT NULL,
        "Whatsapp" text,
        "Email" text,
        "City" text NOT NULL,
        "State" text,
        "Pincode" text NOT NULL,
        "Address" text,
        "GstNumber" text,
        "Website" text,
        "Notes" text,
        "Types" text NOT NULL,
        "IsActive" boolean NOT NULL,
        "DeletedAtUtc" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Associates" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "Barcodes" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "Type" integer NOT NULL,
        "Value" text NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_Barcodes" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_Barcodes_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "CashBookEntries" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Date" timestamp with time zone NOT NULL,
        "TransactionType" integer NOT NULL,
        "Description" text NOT NULL,
        "Amount" numeric NOT NULL,
        "CashIn" numeric NOT NULL,
        "CashOut" numeric NOT NULL,
        "RunningBalance" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_CashBookEntries" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "CloudDesigns" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "BouquetId" text NOT NULL,
        "ImageReference" text,
        "Description" text NOT NULL,
        "SellingPricePaise" integer,
        "Flowers" text NOT NULL,
        "Occasion" text NOT NULL,
        "Color" text NOT NULL,
        "Collection" text NOT NULL,
        "Notes" text NOT NULL,
        "Status" text NOT NULL,
        "IsFavorite" boolean NOT NULL,
        "DeletedAtUtc" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_CloudDesigns" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "ExpenseCategories" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Name" text NOT NULL,
        "Emoji" text NOT NULL,
        "GroupName" text NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ExpenseCategories" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "MorningPurchaseListItems" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ListDate" timestamp with time zone NOT NULL,
        "ProductId" uuid NOT NULL,
        "ProductName" text NOT NULL,
        "Category" text NOT NULL,
        "Quantity" integer NOT NULL,
        "Unit" text NOT NULL,
        "Supplier" text NOT NULL,
        "Priority" text NOT NULL,
        "Remarks" text NOT NULL,
        "Purchased" boolean NOT NULL,
        "InventoryUpdated" boolean NOT NULL,
        "DeletedAtUtc" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_MorningPurchaseListItems" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "OccasionContacts" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "CustomerId" uuid NOT NULL,
        "RecipientName" text NOT NULL,
        "Relationship" text NOT NULL,
        "Occasion" text NOT NULL,
        "OccasionDate" timestamp with time zone NOT NULL,
        "RecipientPhone" text NOT NULL,
        "Company" text NOT NULL,
        "Notes" text NOT NULL,
        "ReminderEnabled" boolean NOT NULL,
        "Source" text NOT NULL,
        "DeletedAtUtc" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_OccasionContacts" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "OccasionFollowUpActions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "SourceType" text NOT NULL,
        "SourceId" uuid NOT NULL,
        "OccurrenceDate" timestamp with time zone NOT NULL,
        "Status" text NOT NULL,
        "SnoozedTo" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_OccasionFollowUpActions" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "OpeningCashEntries" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Date" timestamp with time zone NOT NULL,
        "Amount" numeric NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_OpeningCashEntries" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "ReadyBouquetRecords" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "FinishedProductId" uuid NOT NULL,
        "RecipeId" uuid,
        "ProductionId" uuid,
        "InitialQuantity" integer NOT NULL,
        "RemainingQuantity" integer NOT NULL,
        "ShelfLifeDays" integer NOT NULL,
        "RefreshAfterDays" integer NOT NULL,
        "ProducedAt" timestamp with time zone NOT NULL,
        "LastRefreshAt" timestamp with time zone,
        "ExpiryAt" timestamp with time zone NOT NULL,
        "Location" text NOT NULL,
        "Status" text NOT NULL,
        "Note" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ReadyBouquetRecords" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "ReadyBouquetRefreshEvents" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "BatchId" uuid NOT NULL,
        "ActionType" text NOT NULL,
        "ProductId" uuid NOT NULL,
        "Quantity" integer NOT NULL,
        "WastageQuantity" integer NOT NULL,
        "Reason" text,
        "Note" text,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_ReadyBouquetRefreshEvents" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "SchedulerRecords" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Title" text NOT NULL,
        "Type" text NOT NULL,
        "Category" text NOT NULL,
        "Priority" text NOT NULL,
        "Status" text NOT NULL,
        "ScheduledAt" timestamp with time zone NOT NULL,
        "NextReminderAt" timestamp with time zone,
        "DeadlineAt" timestamp with time zone,
        "Notes" text NOT NULL,
        "LinkedCustomerId" uuid,
        "LinkedOrderId" uuid,
        "AssignedStaffId" uuid,
        "Producer" text NOT NULL,
        "SourceRef" text NOT NULL,
        "RequiresConfirmation" boolean NOT NULL,
        "RequiresAlarm" boolean NOT NULL,
        "StartedAt" timestamp with time zone,
        "CompletedAt" timestamp with time zone,
        "DeletedAtUtc" timestamp with time zone,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_SchedulerRecords" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE TABLE "WhatsAppAccounts" (
        "Id" uuid NOT NULL,
        "MemberId" integer NOT NULL,
        "BusinessName" text NOT NULL,
        "PhoneNumber" text NOT NULL,
        "PhoneNumberId" text NOT NULL,
        "WabaId" text NOT NULL,
        "AccessToken" text NOT NULL,
        "VerifyToken" text NOT NULL,
        "IsActive" boolean NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_WhatsAppAccounts" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_StaffAttendanceRecords_CompanyId_StaffId_AttendanceDate" ON "StaffAttendanceRecords" ("CompanyId", "StaffId", "AttendanceDate");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_Orders_DeliveryPersonId" ON "Orders" ("DeliveryPersonId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_DriverLocations_CreatedAtUtc" ON "DriverLocations" ("CreatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_Deliveries_CompanyId" ON "Deliveries" ("CompanyId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_Deliveries_TrackingToken" ON "Deliveries" ("TrackingToken");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_Associates_CompanyId_AssociateCode" ON "Associates" ("CompanyId", "AssociateCode");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_Associates_CompanyId_BusinessName_Phone" ON "Associates" ("CompanyId", "BusinessName", "Phone");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_Barcodes_CompanyId_Value" ON "Barcodes" ("CompanyId", "Value");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_Barcodes_ProductId_Type" ON "Barcodes" ("ProductId", "Type");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_CashBookEntries_CompanyId_Date_CreatedAtUtc" ON "CashBookEntries" ("CompanyId", "Date", "CreatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_CloudDesigns_CompanyId_BouquetId" ON "CloudDesigns" ("CompanyId", "BouquetId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_ExpenseCategories_CompanyId_Name" ON "ExpenseCategories" ("CompanyId", "Name");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_MorningPurchaseListItems_CompanyId_ListDate_ProductId" ON "MorningPurchaseListItems" ("CompanyId", "ListDate", "ProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_OccasionContacts_CompanyId_CustomerId_RecipientName_Occasion" ON "OccasionContacts" ("CompanyId", "CustomerId", "RecipientName", "Occasion");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_OccasionFollowUpActions_CompanyId_SourceType_SourceId_Occur~" ON "OccasionFollowUpActions" ("CompanyId", "SourceType", "SourceId", "OccurrenceDate");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_OpeningCashEntries_CompanyId_Date" ON "OpeningCashEntries" ("CompanyId", "Date");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_ReadyBouquetRecords_CompanyId_FinishedProductId_ProducedAt" ON "ReadyBouquetRecords" ("CompanyId", "FinishedProductId", "ProducedAt");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE INDEX "IX_ReadyBouquetRefreshEvents_CompanyId_BatchId_CreatedAtUtc" ON "ReadyBouquetRefreshEvents" ("CompanyId", "BatchId", "CreatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_SchedulerRecords_CompanyId_Producer_SourceRef" ON "SchedulerRecords" ("CompanyId", "Producer", "SourceRef");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_WhatsAppAccounts_MemberId" ON "WhatsAppAccounts" ("MemberId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    CREATE UNIQUE INDEX "IX_WhatsAppAccounts_PhoneNumberId" ON "WhatsAppAccounts" ("PhoneNumberId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    ALTER TABLE "Orders" ADD CONSTRAINT "FK_Orders_DeliveryPerson" FOREIGN KEY ("DeliveryPersonId") REFERENCES "Staff" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260902174636_AddMobileOperationalParity') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260902174636_AddMobileOperationalParity', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "Payments" ADD "ClientPaymentId" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "Payments" ADD "Reference" character varying(256);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "Orders" ADD "PosRoundOffAmount" numeric(18,2) NOT NULL DEFAULT 0.0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "Orders" ADD "RewardDiscountAmount" numeric(18,2) NOT NULL DEFAULT 0.0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "ClientOrderLineId" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "DiscountAmount" numeric(18,2) NOT NULL DEFAULT 0.0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "DiscountType" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "DiscountValue" numeric(18,2);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "LineSubtotal" numeric(18,2);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "LineTaxAmount" numeric(18,2);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    ALTER TABLE "OrderItems" ADD "TaxRatePercent" numeric(8,4);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE TABLE "PosSaleSyncReceipts" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ClientSyncId" text NOT NULL,
        "LocalOrderId" integer NOT NULL,
        "DeviceId" text NOT NULL,
        "CloudOrderId" uuid NOT NULL,
        "CloudCustomerId" uuid,
        "PayloadHash" text NOT NULL,
        "CompletedAtUtc" timestamp with time zone NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_PosSaleSyncReceipts" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PosSaleSyncReceipts_Customers_CloudCustomerId" FOREIGN KEY ("CloudCustomerId") REFERENCES "Customers" ("Id") ON DELETE SET NULL,
        CONSTRAINT "FK_PosSaleSyncReceipts_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE TABLE "PosSaleSyncInventoryTransactions" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "PosSaleSyncReceiptId" uuid NOT NULL,
        "ClientInventoryTransactionId" text NOT NULL,
        "CloudOrderId" uuid NOT NULL,
        "ProductId" uuid NOT NULL,
        "Quantity" integer NOT NULL,
        "OccurredAtUtc" timestamp with time zone NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_PosSaleSyncInventoryTransactions" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PosSaleSyncInventoryTransactions_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_PosSaleSyncInventoryTransactions_PosSaleSyncReceipts_PosSal~" FOREIGN KEY ("PosSaleSyncReceiptId") REFERENCES "PosSaleSyncReceipts" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_PosSaleSyncInventoryTransactions_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE UNIQUE INDEX "IX_Payments_OrderId_ClientPaymentId" ON "Payments" ("OrderId", "ClientPaymentId") WHERE "ClientPaymentId" IS NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE UNIQUE INDEX "IX_OrderItems_OrderId_ClientOrderLineId" ON "OrderItems" ("OrderId", "ClientOrderLineId") WHERE "ClientOrderLineId" IS NOT NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE INDEX "IX_PosSaleSyncInventoryTransactions_CloudOrderId" ON "PosSaleSyncInventoryTransactions" ("CloudOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE UNIQUE INDEX "IX_PosSaleSyncInventoryTransactions_CompanyId_ClientInventoryT~" ON "PosSaleSyncInventoryTransactions" ("CompanyId", "ClientInventoryTransactionId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE INDEX "IX_PosSaleSyncInventoryTransactions_PosSaleSyncReceiptId_Creat~" ON "PosSaleSyncInventoryTransactions" ("PosSaleSyncReceiptId", "CreatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE INDEX "IX_PosSaleSyncInventoryTransactions_ProductId" ON "PosSaleSyncInventoryTransactions" ("ProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE INDEX "IX_PosSaleSyncReceipts_CloudCustomerId" ON "PosSaleSyncReceipts" ("CloudCustomerId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE INDEX "IX_PosSaleSyncReceipts_CloudOrderId" ON "PosSaleSyncReceipts" ("CloudOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE UNIQUE INDEX "IX_PosSaleSyncReceipts_CompanyId_ClientSyncId" ON "PosSaleSyncReceipts" ("CompanyId", "ClientSyncId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    CREATE UNIQUE INDEX "IX_PosSaleSyncReceipts_CompanyId_DeviceId_LocalOrderId" ON "PosSaleSyncReceipts" ("CompanyId", "DeviceId", "LocalOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260903162843_AddPosSalesSyncPersistence') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260903162843_AddPosSalesSyncPersistence', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260904112201_AddPosSaleSyncOrderLines') THEN
    CREATE TABLE "PosSaleSyncOrderLines" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "PosSaleSyncReceiptId" uuid NOT NULL,
        "CloudOrderId" uuid NOT NULL,
        "ClientOrderLineId" text NOT NULL,
        "LocalOrderLineId" integer NOT NULL,
        "LocalProductId" integer,
        "CloudProductId" uuid,
        "Source" text,
        "DesignRef" text,
        "Description" text NOT NULL,
        "Quantity" integer NOT NULL,
        "UnitPrice" numeric(18,2) NOT NULL,
        "TaxRatePercent" numeric(8,4),
        "DiscountType" text,
        "DiscountValue" numeric(18,2),
        "DiscountAmount" numeric(18,2) NOT NULL,
        "LineSubtotal" numeric(18,2) NOT NULL,
        "LineTaxAmount" numeric(18,2) NOT NULL,
        "LineTotal" numeric(18,2) NOT NULL,
        "CreatedAtUtc" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_PosSaleSyncOrderLines" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_PosSaleSyncOrderLines_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_PosSaleSyncOrderLines_PosSaleSyncReceipts_PosSaleSyncReceip~" FOREIGN KEY ("PosSaleSyncReceiptId") REFERENCES "PosSaleSyncReceipts" ("Id") ON DELETE CASCADE,
        CONSTRAINT "FK_PosSaleSyncOrderLines_Products_CloudProductId" FOREIGN KEY ("CloudProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260904112201_AddPosSaleSyncOrderLines') THEN
    CREATE INDEX "IX_PosSaleSyncOrderLines_CloudOrderId" ON "PosSaleSyncOrderLines" ("CloudOrderId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260904112201_AddPosSaleSyncOrderLines') THEN
    CREATE INDEX "IX_PosSaleSyncOrderLines_CloudProductId" ON "PosSaleSyncOrderLines" ("CloudProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260904112201_AddPosSaleSyncOrderLines') THEN
    CREATE UNIQUE INDEX "IX_PosSaleSyncOrderLines_PosSaleSyncReceiptId_ClientOrderLineId" ON "PosSaleSyncOrderLines" ("PosSaleSyncReceiptId", "ClientOrderLineId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260904112201_AddPosSaleSyncOrderLines') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260904112201_AddPosSaleSyncOrderLines', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260907170306_AddOrderDesignerStaffAssignment') THEN
    ALTER TABLE "Orders" ADD "AssignedDesignerStaffId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260907170306_AddOrderDesignerStaffAssignment') THEN
    CREATE INDEX "IX_Orders_AssignedDesignerStaffId" ON "Orders" ("AssignedDesignerStaffId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260907170306_AddOrderDesignerStaffAssignment') THEN
    ALTER TABLE "Orders" ADD CONSTRAINT "FK_Orders_AssignedDesignerStaff" FOREIGN KEY ("AssignedDesignerStaffId") REFERENCES "Staff" ("Id") ON DELETE SET NULL;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260907170306_AddOrderDesignerStaffAssignment') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260907170306_AddOrderDesignerStaffAssignment', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260911173823_AddIdempotencyRecords') THEN
    CREATE TABLE "IdempotencyRecords" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "IdempotencyKey" character varying(128) NOT NULL,
        "RequestPath" character varying(256) NOT NULL,
        "RequestHash" character varying(64) NOT NULL,
        "ResponseStatusCode" integer NOT NULL,
        "ResponsePayload" text NOT NULL,
        "OrderId" uuid,
        "ExpiresAt" timestamp with time zone,
        "CreatedAt" timestamp with time zone NOT NULL,
        "UpdatedAtUtc" timestamp with time zone,
        CONSTRAINT "PK_IdempotencyRecords" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260911173823_AddIdempotencyRecords') THEN
    CREATE UNIQUE INDEX "IX_IdempotencyRecords_CompanyId_IdempotencyKey" ON "IdempotencyRecords" ("CompanyId", "IdempotencyKey");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260911173823_AddIdempotencyRecords') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260911173823_AddIdempotencyRecords', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    ALTER TABLE "ProductCategories" ADD "DefaultUnit" character varying(50);
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    ALTER TABLE "FinishedGoodsBatches" ADD "OperatorName" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    ALTER TABLE "FinishedGoodsBatches" ADD "ReversalNote" text;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    ALTER TABLE "FinishedGoodsBatches" ADD "ReversedAt" timestamp with time zone;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    ALTER TABLE "DayCloses" ADD "CashExpenses" numeric NOT NULL DEFAULT 0.0;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    CREATE TABLE "RewardsSettings" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "Enabled" boolean NOT NULL DEFAULT TRUE,
        "EarnSpendPaisePerPoint" integer NOT NULL DEFAULT 10000,
        "MinimumBillPaise" integer NOT NULL DEFAULT 30000,
        "PointValuePaise" integer NOT NULL DEFAULT 100,
        "MaximumRedemptionPercent" integer NOT NULL DEFAULT 20,
        "ExpiryDays" integer NOT NULL DEFAULT 365,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_RewardsSettings" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_RewardsSettings_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    CREATE TABLE "ShareBrandingSettings" (
        "Id" uuid NOT NULL,
        "CompanyId" uuid NOT NULL,
        "ShowPrice" boolean NOT NULL DEFAULT TRUE,
        "ShowShopName" boolean NOT NULL DEFAULT TRUE,
        "ShowPhoneNumber" boolean NOT NULL DEFAULT TRUE,
        "ShowWebsite" boolean NOT NULL DEFAULT TRUE,
        "ShowLogo" boolean NOT NULL DEFAULT FALSE,
        "ShowWatermark" boolean NOT NULL DEFAULT TRUE,
        "ShowWatermarkBusinessName" boolean NOT NULL DEFAULT TRUE,
        "ShowWatermarkCity" boolean NOT NULL DEFAULT TRUE,
        "WatermarkOpacity" double precision NOT NULL DEFAULT 0.71999999999999997,
        "WatermarkSize" character varying(20) NOT NULL DEFAULT 'medium',
        "WatermarkPosition" character varying(30) NOT NULL DEFAULT 'bottomCenter',
        "FooterColorArgb" bigint NOT NULL DEFAULT 3424345632,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_ShareBrandingSettings" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_ShareBrandingSettings_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    CREATE UNIQUE INDEX "IX_RewardsSettings_CompanyId" ON "RewardsSettings" ("CompanyId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    CREATE UNIQUE INDEX "IX_ShareBrandingSettings_CompanyId" ON "ShareBrandingSettings" ("CompanyId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260915195240_AddShareBrandingAndRewardsSettings') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260915195240_AddShareBrandingAndRewardsSettings', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    ALTER TABLE "Products" ADD "SourceLibraryProductId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE TABLE "LibraryCategories" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "ImageUrl" character varying(1000),
        "IconKey" character varying(100),
        "ParentCategoryId" uuid,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryCategories" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryCategories_LibraryCategories_ParentCategoryId" FOREIGN KEY ("ParentCategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE TABLE "LibraryProducts" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "CategoryId" uuid,
        "ProductType" character varying(50) NOT NULL,
        "StandardUnit" character varying(50) NOT NULL,
        "StandardSku" character varying(100),
        "Description" text,
        "ReferenceImageUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "SearchKeywords" text,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryProducts" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryProducts_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_Products_SourceLibraryProductId" ON "Products" ("SourceLibraryProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_IsActive" ON "LibraryCategories" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_ParentCategoryId" ON "LibraryCategories" ("ParentCategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE UNIQUE INDEX "IX_LibraryCategories_Slug" ON "LibraryCategories" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_SortOrder" ON "LibraryCategories" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_CategoryId" ON "LibraryProducts" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_IsActive" ON "LibraryProducts" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE UNIQUE INDEX "IX_LibraryProducts_Slug" ON "LibraryProducts" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_SortOrder" ON "LibraryProducts" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_UpdatedAtUtc" ON "LibraryProducts" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919055551_AddFlorapriseLibraryCategoriesAndProducts', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    ALTER TABLE "FloralRecipes" ADD "SourceLibraryRecipeId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE TABLE "LibraryRecipes" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "YieldQuantity" numeric(18,4) NOT NULL DEFAULT 1.0,
        "YieldUnit" character varying(50),
        "Instructions" text,
        "PreparationNotes" text,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryRecipes" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryRecipes_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE TABLE "LibraryRecipeItems" (
        "Id" uuid NOT NULL,
        "RecipeId" uuid NOT NULL,
        "LibraryProductId" uuid,
        "ProductNameSnapshot" character varying(200) NOT NULL,
        "Quantity" numeric(18,4) NOT NULL,
        "Unit" character varying(50) NOT NULL,
        "Notes" character varying(500),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryRecipeItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryRecipeItems_LibraryProducts_LibraryProductId" FOREIGN KEY ("LibraryProductId") REFERENCES "LibraryProducts" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_LibraryRecipeItems_LibraryRecipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES "LibraryRecipes" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_FloralRecipes_SourceLibraryRecipeId" ON "FloralRecipes" ("SourceLibraryRecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipeItems_LibraryProductId" ON "LibraryRecipeItems" ("LibraryProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipeItems_RecipeId" ON "LibraryRecipeItems" ("RecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_CategoryId" ON "LibraryRecipes" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_IsActive" ON "LibraryRecipes" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE UNIQUE INDEX "IX_LibraryRecipes_Slug" ON "LibraryRecipes" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_SortOrder" ON "LibraryRecipes" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_UpdatedAtUtc" ON "LibraryRecipes" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919095011_AddFlorapriseLibraryRecipes', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    ALTER TABLE "CloudDesigns" ADD "SourceLibraryDesignId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryCardTemplates" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Content" text NOT NULL,
        "Occasion" character varying(100),
        "Tone" character varying(100),
        "Language" character varying(20) NOT NULL DEFAULT 'en',
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "SearchKeywords" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryCardTemplates" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryCardTemplates_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryDesigns" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "HighResImageUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "Occasion" character varying(100),
        "Style" character varying(100),
        "ColorPalette" character varying(200),
        "FlowerTypes" character varying(500),
        "RecipeId" uuid,
        "SearchKeywords" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryDesigns" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryDesigns_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_LibraryDesigns_LibraryRecipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES "LibraryRecipes" ("Id") ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryTutorials" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Summary" text,
        "ContentMarkdown" text NOT NULL,
        "CategoryId" uuid,
        "VideoUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "DifficultyLevel" character varying(50) NOT NULL DEFAULT 'Beginner',
        "EstimatedReadingMinutes" integer DEFAULT 5,
        "Tags" character varying(500),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryTutorials" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryTutorials_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_CloudDesigns_SourceLibraryDesignId" ON "CloudDesigns" ("SourceLibraryDesignId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_CategoryId" ON "LibraryCardTemplates" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_IsActive" ON "LibraryCardTemplates" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Language" ON "LibraryCardTemplates" ("Language");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Occasion" ON "LibraryCardTemplates" ("Occasion");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryCardTemplates_Slug" ON "LibraryCardTemplates" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_SortOrder" ON "LibraryCardTemplates" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Tone" ON "LibraryCardTemplates" ("Tone");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_UpdatedAtUtc" ON "LibraryCardTemplates" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_CategoryId" ON "LibraryDesigns" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_IsActive" ON "LibraryDesigns" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_Occasion" ON "LibraryDesigns" ("Occasion");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_RecipeId" ON "LibraryDesigns" ("RecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryDesigns_Slug" ON "LibraryDesigns" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_SortOrder" ON "LibraryDesigns" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_Style" ON "LibraryDesigns" ("Style");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_UpdatedAtUtc" ON "LibraryDesigns" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_CategoryId" ON "LibraryTutorials" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_DifficultyLevel" ON "LibraryTutorials" ("DifficultyLevel");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_IsActive" ON "LibraryTutorials" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryTutorials_Slug" ON "LibraryTutorials" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_SortOrder" ON "LibraryTutorials" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_UpdatedAtUtc" ON "LibraryTutorials" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919101107_AddFlorapriseLibraryAllModules', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920103000_AddPaymentTypeToPayments') THEN
    ALTER TABLE "Payments" ADD "PaymentType" character varying(32) NOT NULL DEFAULT 'SaleTender';
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920103000_AddPaymentTypeToPayments') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260920103000_AddPaymentTypeToPayments', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE TABLE "LibraryFestivals" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "FestivalDate" timestamptz NOT NULL,
        "Month" integer NOT NULL,
        "Day" integer NOT NULL,
        "Description" text,
        "IsRecurring" boolean NOT NULL DEFAULT TRUE,
        "FlowerDemands" character varying(500),
        "SearchKeywords" character varying(1000),
        "ImageUrl" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryFestivals" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE TABLE "LibraryWeddingDates" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "WeddingDate" timestamptz NOT NULL,
        "Tithi" character varying(200),
        "Nakshatra" character varying(200),
        "Notes" text,
        "Season" character varying(100),
        "DemandLevel" character varying(50) NOT NULL DEFAULT 'High',
        "SearchKeywords" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryWeddingDates" PRIMARY KEY ("Id")
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE UNIQUE INDEX "IX_LibraryFestivals_Slug" ON "LibraryFestivals" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryFestivals_FestivalDate" ON "LibraryFestivals" ("FestivalDate");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryFestivals_Month" ON "LibraryFestivals" ("Month");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryFestivals_IsActive" ON "LibraryFestivals" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryFestivals_SortOrder" ON "LibraryFestivals" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryFestivals_UpdatedAtUtc" ON "LibraryFestivals" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE UNIQUE INDEX "IX_LibraryWeddingDates_Slug" ON "LibraryWeddingDates" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_WeddingDate" ON "LibraryWeddingDates" ("WeddingDate");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_DemandLevel" ON "LibraryWeddingDates" ("DemandLevel");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_Season" ON "LibraryWeddingDates" ("Season");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_IsActive" ON "LibraryWeddingDates" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_SortOrder" ON "LibraryWeddingDates" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    CREATE INDEX "IX_LibraryWeddingDates_UpdatedAtUtc" ON "LibraryWeddingDates" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260920162000_AddLibraryFestivalAndWeddingDates') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260920162000_AddLibraryFestivalAndWeddingDates', '10.0.10');
    END IF;
END $EF$;
COMMIT;

