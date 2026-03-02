-- =====================================================
-- SUMPOOJ FLORIST ERP - Migration Script 010
-- Add missing columns to Deliveries table
-- (TimeSlot, PostalCode, DeliveryRouteId, StopOrder)
-- =====================================================

DO $$
BEGIN
    -- TimeSlot column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Deliveries' AND column_name = 'TimeSlot'
    ) THEN
        ALTER TABLE "Deliveries" ADD COLUMN "TimeSlot" VARCHAR(50) NULL;
        RAISE NOTICE 'TimeSlot column added to Deliveries table.';
    END IF;

    -- PostalCode column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Deliveries' AND column_name = 'PostalCode'
    ) THEN
        ALTER TABLE "Deliveries" ADD COLUMN "PostalCode" VARCHAR(20) NULL;
        RAISE NOTICE 'PostalCode column added to Deliveries table.';
    END IF;

    -- DeliveryRouteId column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Deliveries' AND column_name = 'DeliveryRouteId'
    ) THEN
        ALTER TABLE "Deliveries" ADD COLUMN "DeliveryRouteId" UUID NULL;
        RAISE NOTICE 'DeliveryRouteId column added to Deliveries table.';
    END IF;

    -- StopOrder column
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Deliveries' AND column_name = 'StopOrder'
    ) THEN
        ALTER TABLE "Deliveries" ADD COLUMN "StopOrder" INTEGER NULL;
        RAISE NOTICE 'StopOrder column added to Deliveries table.';
    END IF;

    RAISE NOTICE 'Migration 010 completed: Deliveries table columns synced with entity.';
END $$;
