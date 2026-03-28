-- =====================================================
-- SUMPOOJ FLORIST ERP - Migration Script
-- Add DeliveryPincode column to Orders for route mapping
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'Orders'
          AND column_name = 'DeliveryPincode'
    ) THEN
        ALTER TABLE "Orders" ADD COLUMN "DeliveryPincode" text NULL;
        RAISE NOTICE 'Column Orders.DeliveryPincode added successfully.';
    ELSE
        RAISE NOTICE 'Column Orders.DeliveryPincode already exists. Skipping.';
    END IF;
END $$;
