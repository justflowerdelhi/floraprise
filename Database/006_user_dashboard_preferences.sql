-- ============================================================
-- 006_user_dashboard_preferences.sql
-- Per-user dashboard module visibility & ordering
-- ============================================================

-- 1. Create table
CREATE TABLE IF NOT EXISTS "UserDashboardPreferences" (
    "Id"               UUID          NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"        UUID          NOT NULL,
    "UserId"           UUID          NOT NULL,
    "VisibleModules"   TEXT          NOT NULL DEFAULT '[]',
    "ModuleOrder"      TEXT          NOT NULL DEFAULT '[]',
    "CreatedAtUtc"     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    "UpdatedAtUtc"     TIMESTAMPTZ   NULL,

    CONSTRAINT "PK_UserDashboardPreferences" PRIMARY KEY ("Id"),

    CONSTRAINT "FK_UserDashboardPreferences_Companies_CompanyId"
        FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id")
        ON DELETE CASCADE,

    CONSTRAINT "FK_UserDashboardPreferences_AspNetUsers_UserId"
        FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id")
        ON DELETE CASCADE
);

-- 2. Unique index: one preference row per user per company
CREATE UNIQUE INDEX IF NOT EXISTS "IX_UserDashboardPreferences_CompanyId_UserId"
    ON "UserDashboardPreferences" ("CompanyId", "UserId");

-- 3. Index for fast lookup by user
CREATE INDEX IF NOT EXISTS "IX_UserDashboardPreferences_UserId"
    ON "UserDashboardPreferences" ("UserId");
