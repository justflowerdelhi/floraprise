-- Phase 1 foundation for Floraprise mobile subscription and licensing in unified ERP DB

CREATE TABLE IF NOT EXISTS "MobileCustomers" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "BusinessName" character varying(160) NOT NULL,
    "OwnerName" character varying(120) NOT NULL,
    "Mobile" character varying(32) NOT NULL,
    "Email" character varying(160),
    "City" character varying(100),
    "State" character varying(100),
    "Country" character varying(100),
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobileCustomers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobileCustomers_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobileCustomers_CompanyId_Mobile" ON "MobileCustomers" ("CompanyId", "Mobile");
CREATE INDEX IF NOT EXISTS "IX_MobileCustomers_CompanyId_IsDeleted" ON "MobileCustomers" ("CompanyId", "IsDeleted");

CREATE TABLE IF NOT EXISTS "MobileUsers" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "MobileCustomerId" uuid NOT NULL,
    "FullName" character varying(120) NOT NULL,
    "Mobile" character varying(32) NOT NULL,
    "Email" character varying(160),
    "Status" character varying(24) NOT NULL,
    "PreferredLanguage" character varying(16) NOT NULL,
    "PreferredTheme" character varying(32) NOT NULL,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobileUsers" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobileUsers_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileUsers_MobileCustomers_MobileCustomerId" FOREIGN KEY ("MobileCustomerId") REFERENCES "MobileCustomers" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobileUsers_CompanyId_Mobile" ON "MobileUsers" ("CompanyId", "Mobile");
CREATE INDEX IF NOT EXISTS "IX_MobileUsers_CompanyId_Status" ON "MobileUsers" ("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS "IX_MobileUsers_MobileCustomerId" ON "MobileUsers" ("MobileCustomerId");

CREATE TABLE IF NOT EXISTS "MobileDevices" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobileDevices" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobileDevices_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileDevices_MobileUsers_MobileUserId" FOREIGN KEY ("MobileUserId") REFERENCES "MobileUsers" ("Id") ON DELETE CASCADE
);

-- Compatibility patch for legacy schemas where MobileDevices/MobileUsers already existed
-- with older column names (UserId, DeviceFingerprintHash, DeviceName, LastSeenAtUtc, etc.).
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'MobileUsers'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileUsers' AND column_name = 'CustomerId'
        ) AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileUsers' AND column_name = 'MobileCustomerId'
        ) THEN
            ALTER TABLE "MobileUsers" ADD COLUMN "MobileCustomerId" uuid NULL;
            UPDATE "MobileUsers" SET "MobileCustomerId" = "CustomerId" WHERE "MobileCustomerId" IS NULL;
        END IF;

        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "IsDeleted" boolean NOT NULL DEFAULT false;
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "DeletedAtUtc" timestamptz;
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "CreatedBy" uuid;
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "UpdatedBy" uuid;
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "UpdatedAtUtc" timestamptz;
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "RowVersion" bytea NOT NULL DEFAULT E'\\x';
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "Status" character varying(24) NOT NULL DEFAULT 'Active';
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "PreferredLanguage" character varying(16) NOT NULL DEFAULT 'en-IN';
        ALTER TABLE "MobileUsers" ADD COLUMN IF NOT EXISTS "PreferredTheme" character varying(32) NOT NULL DEFAULT 'system';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'MobileDevices'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'UserId'
        ) AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'MobileUserId'
        ) THEN
            ALTER TABLE "MobileDevices" ADD COLUMN "MobileUserId" uuid NULL;
            UPDATE "MobileDevices" SET "MobileUserId" = "UserId" WHERE "MobileUserId" IS NULL;
        END IF;

        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "DeviceId" character varying(120);
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'DeviceFingerprintHash'
        ) THEN
            UPDATE "MobileDevices"
            SET "DeviceId" = COALESCE("DeviceId", "DeviceFingerprintHash", "Id"::text)
            WHERE "DeviceId" IS NULL;
        ELSE
            UPDATE "MobileDevices"
            SET "DeviceId" = COALESCE("DeviceId", "Id"::text)
            WHERE "DeviceId" IS NULL;
        END IF;

        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "Model" character varying(120);
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'DeviceName'
        ) THEN
            UPDATE "MobileDevices" SET "Model" = COALESCE("Model", "DeviceName") WHERE "Model" IS NULL;
        END IF;

        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "LastHeartbeatAtUtc" timestamptz;
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'LastSeenAtUtc'
        ) THEN
            UPDATE "MobileDevices"
            SET "LastHeartbeatAtUtc" = COALESCE("LastHeartbeatAtUtc", "LastSeenAtUtc")
            WHERE "LastHeartbeatAtUtc" IS NULL;
        END IF;

        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "Status" character varying(24);
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileDevices' AND column_name = 'IsActive'
        ) THEN
            UPDATE "MobileDevices"
            SET "Status" = COALESCE("Status", CASE WHEN "IsActive" THEN 'Active' ELSE 'Disabled' END)
            WHERE "Status" IS NULL;
        ELSE
            UPDATE "MobileDevices" SET "Status" = COALESCE("Status", 'Active') WHERE "Status" IS NULL;
        END IF;

        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "Manufacturer" character varying(80);
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "OsVersion" character varying(80);
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "AppVersion" character varying(40) NOT NULL DEFAULT 'legacy';
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "LastIpAddress" character varying(64);
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "LastLoginAtUtc" timestamptz;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "LastSyncAtUtc" timestamptz;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "IsDeleted" boolean NOT NULL DEFAULT false;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "DeletedAtUtc" timestamptz;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "CreatedBy" uuid;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "UpdatedBy" uuid;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "UpdatedAtUtc" timestamptz;
        ALTER TABLE "MobileDevices" ADD COLUMN IF NOT EXISTS "RowVersion" bytea NOT NULL DEFAULT E'\\x';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'MobileSubscriptions'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileSubscriptions' AND column_name = 'UserId'
        ) AND NOT EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = 'MobileSubscriptions' AND column_name = 'MobileUserId'
        ) THEN
            ALTER TABLE "MobileSubscriptions" ADD COLUMN "MobileUserId" uuid NULL;
            UPDATE "MobileSubscriptions" SET "MobileUserId" = "UserId" WHERE "MobileUserId" IS NULL;
        END IF;

        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "IsDeleted" boolean NOT NULL DEFAULT false;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "DeletedAtUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "CreatedBy" uuid;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "UpdatedBy" uuid;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "UpdatedAtUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "RowVersion" bytea NOT NULL DEFAULT E'\\x';
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "Status" character varying(24) NOT NULL DEFAULT 'Trial';
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "TrialStartUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "TrialEndUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP + INTERVAL '7 days';
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "StartUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "EndUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "GraceEndUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "LastValidatedUtc" timestamptz;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "AutoRenew" boolean NOT NULL DEFAULT false;
        ALTER TABLE "MobileSubscriptions" ADD COLUMN IF NOT EXISTS "SubscriptionPlanId" uuid;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobileDevices_CompanyId_MobileUserId_DeviceId" ON "MobileDevices" ("CompanyId", "MobileUserId", "DeviceId");
CREATE INDEX IF NOT EXISTS "IX_MobileDevices_CompanyId_Status" ON "MobileDevices" ("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS "IX_MobileDevices_MobileUserId" ON "MobileDevices" ("MobileUserId");

CREATE TABLE IF NOT EXISTS "SubscriptionPlans" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
    "IncludedModulesJson" text NOT NULL,
    "IsActive" boolean NOT NULL,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_SubscriptionPlans" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_SubscriptionPlans_Code" ON "SubscriptionPlans" ("Code");
CREATE INDEX IF NOT EXISTS "IX_SubscriptionPlans_IsActive_IsDeleted" ON "SubscriptionPlans" ("IsActive", "IsDeleted");

CREATE TABLE IF NOT EXISTS "MobileSubscriptions" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobileSubscriptions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobileSubscriptions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileSubscriptions_MobileUsers_MobileUserId" FOREIGN KEY ("MobileUserId") REFERENCES "MobileUsers" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileSubscriptions_SubscriptionPlans_SubscriptionPlanId" FOREIGN KEY ("SubscriptionPlanId") REFERENCES "SubscriptionPlans" ("Id") ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobileSubscriptions_MobileUserId" ON "MobileSubscriptions" ("MobileUserId");
CREATE INDEX IF NOT EXISTS "IX_MobileSubscriptions_CompanyId_Status" ON "MobileSubscriptions" ("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS "IX_MobileSubscriptions_SubscriptionPlanId" ON "MobileSubscriptions" ("SubscriptionPlanId");

CREATE TABLE IF NOT EXISTS "MobileLicenses" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "MobileDeviceId" uuid NOT NULL,
    "MobileSubscriptionId" uuid NOT NULL,
    "Status" character varying(24) NOT NULL,
    "IssuedAtUtc" timestamptz NOT NULL,
    "ExpiryUtc" timestamptz,
    "RevokedAtUtc" timestamptz,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobileLicenses" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobileLicenses_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileLicenses_MobileDevices_MobileDeviceId" FOREIGN KEY ("MobileDeviceId") REFERENCES "MobileDevices" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobileLicenses_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobileLicenses_MobileDeviceId" ON "MobileLicenses" ("MobileDeviceId");
CREATE INDEX IF NOT EXISTS "IX_MobileLicenses_CompanyId_Status" ON "MobileLicenses" ("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS "IX_MobileLicenses_MobileSubscriptionId" ON "MobileLicenses" ("MobileSubscriptionId");

CREATE TABLE IF NOT EXISTS "DeviceSessions" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "MobileDeviceId" uuid NOT NULL,
    "RefreshToken" character varying(512) NOT NULL,
    "ExpiresAtUtc" timestamptz NOT NULL,
    "LastSeenAtUtc" timestamptz NOT NULL,
    "Status" character varying(24) NOT NULL,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_DeviceSessions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_DeviceSessions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_DeviceSessions_MobileDevices_MobileDeviceId" FOREIGN KEY ("MobileDeviceId") REFERENCES "MobileDevices" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_DeviceSessions_RefreshToken" ON "DeviceSessions" ("RefreshToken");
CREATE INDEX IF NOT EXISTS "IX_DeviceSessions_CompanyId_MobileDeviceId_Status" ON "DeviceSessions" ("CompanyId", "MobileDeviceId", "Status");

CREATE TABLE IF NOT EXISTS "MobilePaymentTransactions" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
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
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_MobilePaymentTransactions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_MobilePaymentTransactions_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_MobilePaymentTransactions_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_MobilePaymentTransactions_TransactionRef" ON "MobilePaymentTransactions" ("TransactionRef");
CREATE INDEX IF NOT EXISTS "IX_MobilePaymentTransactions_CompanyId_PaymentStatus" ON "MobilePaymentTransactions" ("CompanyId", "PaymentStatus");

CREATE TABLE IF NOT EXISTS "FeatureEntitlements" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "MobileSubscriptionId" uuid NOT NULL,
    "FeatureKey" character varying(120) NOT NULL,
    "IsEnabled" boolean NOT NULL,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_FeatureEntitlements" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_FeatureEntitlements_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_FeatureEntitlements_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_FeatureEntitlements_CompanyId_MobileSubscriptionId_FeatureKey" ON "FeatureEntitlements" ("CompanyId", "MobileSubscriptionId", "FeatureKey");

CREATE TABLE IF NOT EXISTS "TrialHistory" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "MobileSubscriptionId" uuid NOT NULL,
    "ActionType" character varying(24) NOT NULL,
    "ActionAtUtc" timestamptz NOT NULL,
    "Notes" character varying(500),
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAtUtc" timestamptz,
    "CreatedBy" uuid,
    "UpdatedBy" uuid,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    "RowVersion" bytea NOT NULL DEFAULT E'\\x',
    CONSTRAINT "PK_TrialHistory" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_TrialHistory_Companies_CompanyId" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_TrialHistory_MobileSubscriptions_MobileSubscriptionId" FOREIGN KEY ("MobileSubscriptionId") REFERENCES "MobileSubscriptions" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_TrialHistory_CompanyId_MobileSubscriptionId_ActionAtUtc" ON "TrialHistory" ("CompanyId", "MobileSubscriptionId", "ActionAtUtc");

INSERT INTO "SubscriptionPlans"
(
    "Id", "Code", "Name", "PlanType", "MonthlyPrice", "AnnualPrice", "LifetimePrice", "TrialDays",
    "OfflineDays", "GraceDays", "MaximumDevices", "MaximumStaff", "IncludedModulesJson", "IsActive",
    "IsDeleted", "CreatedAtUtc", "RowVersion"
)
SELECT
    uuid_generate_v4(),
    'MOBILE_TRIAL',
    'Mobile Trial',
    'Basic',
    0,
    0,
    0,
    7,
    3,
    30,
    2,
    2,
    '[]',
    true,
    false,
    CURRENT_TIMESTAMP,
    E'\\x'
WHERE NOT EXISTS (SELECT 1 FROM "SubscriptionPlans" WHERE "Code" = 'MOBILE_TRIAL');
