START TRANSACTION;
ALTER TABLE "ProductCategories" ADD "DefaultUnit" character varying(50);

ALTER TABLE "FinishedGoodsBatches" ADD "OperatorName" text;

ALTER TABLE "FinishedGoodsBatches" ADD "ReversalNote" text;

ALTER TABLE "FinishedGoodsBatches" ADD "ReversedAt" timestamp with time zone;

ALTER TABLE "DayCloses" ADD "CashExpenses" numeric NOT NULL DEFAULT 0.0;

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

CREATE UNIQUE INDEX "IX_RewardsSettings_CompanyId" ON "RewardsSettings" ("CompanyId");

CREATE UNIQUE INDEX "IX_ShareBrandingSettings_CompanyId" ON "ShareBrandingSettings" ("CompanyId");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260915195240_AddShareBrandingAndRewardsSettings', '10.0.10');

COMMIT;

