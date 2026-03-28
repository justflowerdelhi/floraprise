-- Migration 018: Create DeliveryRoutes table
-- Idempotent: safe to run multiple times

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'DeliveryRoutes'
    ) THEN
        CREATE TABLE "DeliveryRoutes" (
            "Id"               UUID        NOT NULL DEFAULT uuid_generate_v4(),
            "DeliveryPersonId" UUID        NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
            "RouteDate"        TIMESTAMPTZ NOT NULL,
            "Name"             TEXT        NOT NULL DEFAULT '',
            "Status"           INTEGER     NOT NULL DEFAULT 0,
            "CreatedAtUtc"     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "UpdatedAtUtc"     TIMESTAMPTZ NULL,
            CONSTRAINT "PK_DeliveryRoutes" PRIMARY KEY ("Id")
        );
        CREATE INDEX "IX_DeliveryRoutes_RouteDate" ON "DeliveryRoutes" ("RouteDate");
    END IF;
END $$;
