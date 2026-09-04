START TRANSACTION;
ALTER TABLE "Deliveries" RENAME COLUMN "DeliveryAddressLongitude" TO "DeliveryLongitude";

ALTER TABLE "Deliveries" RENAME COLUMN "DeliveryAddressLatitude" TO "DeliveryLatitude";

ALTER TABLE "SubscriptionPlans" ALTER COLUMN "IncludedModulesJson" TYPE text;

ALTER TABLE "StaffAttendanceRecords" ALTER COLUMN "CheckInUtc" DROP NOT NULL;

ALTER TABLE "StaffAttendanceRecords" ADD "AttendanceDate" timestamp with time zone NOT NULL DEFAULT TIMESTAMPTZ '-infinity';

ALTER TABLE "StaffAttendanceRecords" ADD "Notes" text;

ALTER TABLE "StaffAttendanceRecords" ADD "OvertimeHours" integer NOT NULL DEFAULT 0;

ALTER TABLE "Orders" ADD "RewardPointsEarned" integer NOT NULL DEFAULT 0;

ALTER TABLE "Orders" ADD "RewardPointsRedeemed" integer NOT NULL DEFAULT 0;

ALTER TABLE "MobileDevices" ADD "DeviceFingerprintHash" text NOT NULL DEFAULT '';

ALTER TABLE "MobileDevices" ADD "DeviceName" text NOT NULL DEFAULT '';

ALTER TABLE "MobileDevices" ADD "UserId" uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';

ALTER TABLE "Expenses" ADD "ExpenseCategoryId" uuid;

ALTER TABLE "Expenses" ADD "PaymentMode" integer NOT NULL DEFAULT 0;

ALTER TABLE "Deliveries" ADD "CompletedAtUtc" timestamp with time zone;

ALTER TABLE "Deliveries" ADD "LastLocationUtc" timestamp with time zone;

ALTER TABLE "Deliveries" ADD "StartedAtUtc" timestamp with time zone;

ALTER TABLE "Customers" ADD "AnniversaryMonthDay" text;

ALTER TABLE "Customers" ADD "BirthdayMonthDay" text;

ALTER TABLE "Customers" ADD "CompanyName" text;

ALTER TABLE "Customers" ADD "Department" text;

ALTER TABLE "Customers" ADD "LastOrderAtUtc" timestamp with time zone;

ALTER TABLE "Customers" ADD "LastRewardActivityAtUtc" timestamp with time zone;

ALTER TABLE "Customers" ADD "LifetimeRewardPoints" integer NOT NULL DEFAULT 0;

ALTER TABLE "Customers" ADD "PendingPaymentAmount" numeric NOT NULL DEFAULT 0.0;

ALTER TABLE "Customers" ADD "RedeemedRewardPoints" integer NOT NULL DEFAULT 0;

ALTER TABLE "Customers" ADD "RewardPoints" integer NOT NULL DEFAULT 0;

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

CREATE TABLE "OpeningCashEntries" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "Date" timestamp with time zone NOT NULL,
    "Amount" numeric NOT NULL,
    "CreatedAtUtc" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_OpeningCashEntries" PRIMARY KEY ("Id")
);

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

CREATE UNIQUE INDEX "IX_StaffAttendanceRecords_CompanyId_StaffId_AttendanceDate" ON "StaffAttendanceRecords" ("CompanyId", "StaffId", "AttendanceDate");

CREATE INDEX "IX_Orders_DeliveryPersonId" ON "Orders" ("DeliveryPersonId");

CREATE INDEX "IX_DriverLocations_CreatedAtUtc" ON "DriverLocations" ("CreatedAtUtc");

CREATE INDEX "IX_Deliveries_CompanyId" ON "Deliveries" ("CompanyId");

CREATE UNIQUE INDEX "IX_Deliveries_TrackingToken" ON "Deliveries" ("TrackingToken");

CREATE UNIQUE INDEX "IX_Associates_CompanyId_AssociateCode" ON "Associates" ("CompanyId", "AssociateCode");

CREATE UNIQUE INDEX "IX_Associates_CompanyId_BusinessName_Phone" ON "Associates" ("CompanyId", "BusinessName", "Phone");

CREATE UNIQUE INDEX "IX_Barcodes_CompanyId_Value" ON "Barcodes" ("CompanyId", "Value");

CREATE UNIQUE INDEX "IX_Barcodes_ProductId_Type" ON "Barcodes" ("ProductId", "Type");

CREATE INDEX "IX_CashBookEntries_CompanyId_Date_CreatedAtUtc" ON "CashBookEntries" ("CompanyId", "Date", "CreatedAtUtc");

CREATE UNIQUE INDEX "IX_CloudDesigns_CompanyId_BouquetId" ON "CloudDesigns" ("CompanyId", "BouquetId");

CREATE UNIQUE INDEX "IX_ExpenseCategories_CompanyId_Name" ON "ExpenseCategories" ("CompanyId", "Name");

CREATE UNIQUE INDEX "IX_MorningPurchaseListItems_CompanyId_ListDate_ProductId" ON "MorningPurchaseListItems" ("CompanyId", "ListDate", "ProductId");

CREATE UNIQUE INDEX "IX_OccasionContacts_CompanyId_CustomerId_RecipientName_Occasion" ON "OccasionContacts" ("CompanyId", "CustomerId", "RecipientName", "Occasion");

CREATE UNIQUE INDEX "IX_OccasionFollowUpActions_CompanyId_SourceType_SourceId_Occur~" ON "OccasionFollowUpActions" ("CompanyId", "SourceType", "SourceId", "OccurrenceDate");

CREATE UNIQUE INDEX "IX_OpeningCashEntries_CompanyId_Date" ON "OpeningCashEntries" ("CompanyId", "Date");

CREATE INDEX "IX_ReadyBouquetRecords_CompanyId_FinishedProductId_ProducedAt" ON "ReadyBouquetRecords" ("CompanyId", "FinishedProductId", "ProducedAt");

CREATE INDEX "IX_ReadyBouquetRefreshEvents_CompanyId_BatchId_CreatedAtUtc" ON "ReadyBouquetRefreshEvents" ("CompanyId", "BatchId", "CreatedAtUtc");

CREATE UNIQUE INDEX "IX_SchedulerRecords_CompanyId_Producer_SourceRef" ON "SchedulerRecords" ("CompanyId", "Producer", "SourceRef");

CREATE UNIQUE INDEX "IX_WhatsAppAccounts_MemberId" ON "WhatsAppAccounts" ("MemberId");

CREATE UNIQUE INDEX "IX_WhatsAppAccounts_PhoneNumberId" ON "WhatsAppAccounts" ("PhoneNumberId");

ALTER TABLE "Orders" ADD CONSTRAINT "FK_Orders_DeliveryPerson" FOREIGN KEY ("DeliveryPersonId") REFERENCES "Staff" ("Id") ON DELETE SET NULL;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260902174636_AddMobileOperationalParity', '10.0.10');

COMMIT;

