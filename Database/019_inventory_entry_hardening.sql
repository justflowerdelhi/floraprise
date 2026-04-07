-- 019_inventory_entry_hardening.sql
-- Adds idempotency flag for purchase receive and batch uniqueness constraint.

BEGIN;

-- 1) PurchaseOrder idempotency flag
ALTER TABLE "PurchaseOrders"
ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;

-- 2) Unique batch number per product
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'uq_productbatches_productid_batchnumber'
    ) THEN
        ALTER TABLE "ProductBatches"
        ADD CONSTRAINT uq_productbatches_productid_batchnumber
        UNIQUE ("ProductId", "BatchNumber");
    END IF;
END $$;

COMMIT;
