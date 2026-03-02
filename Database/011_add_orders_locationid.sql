-- =====================================================
-- SUMPOOJ FLORIST ERP - Migration Script 011
-- Add LocationId column to Orders table
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Orders' AND column_name = 'LocationId'
    ) THEN
        ALTER TABLE "Orders" ADD COLUMN "LocationId" UUID NULL;

        ALTER TABLE "Orders"
            ADD CONSTRAINT "FK_Orders_Locations"
            FOREIGN KEY ("LocationId") REFERENCES "Locations" ("Id")
            ON DELETE SET NULL;

        CREATE INDEX "IX_Orders_LocationId" ON "Orders" ("LocationId");

        RAISE NOTICE 'LocationId column added to Orders table.';
    END IF;

    RAISE NOTICE 'Migration 011 completed.';
END $$;
