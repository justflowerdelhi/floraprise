BEGIN;

CREATE TABLE IF NOT EXISTS "RewardsSettings" (
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
    CONSTRAINT "FK_RewardsSettings_Companies_CompanyId"
        FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "ShareBrandingSettings" (
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
    "WatermarkOpacity" double precision NOT NULL DEFAULT 0.72,
    "WatermarkSize" character varying(20) NOT NULL DEFAULT 'medium',
    "WatermarkPosition" character varying(30) NOT NULL DEFAULT 'bottomCenter',
    "FooterColorArgb" bigint NOT NULL DEFAULT 3424345632,
    "CreatedAtUtc" timestamptz NOT NULL,
    "UpdatedAtUtc" timestamptz,
    CONSTRAINT "PK_ShareBrandingSettings" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_ShareBrandingSettings_Companies_CompanyId"
        FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_RewardsSettings_CompanyId"
    ON "RewardsSettings" ("CompanyId");

CREATE UNIQUE INDEX IF NOT EXISTS "IX_ShareBrandingSettings_CompanyId"
    ON "ShareBrandingSettings" ("CompanyId");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260915195240_AddShareBrandingAndRewardsSettings', '10.0.10');

COMMIT;
