-- =====================================================
-- 020_delivery_consumption_and_reservations.sql
-- Delivery-time inventory consumption hardening
-- =====================================================

-- 1) Add processing flags for idempotent stock consumption
ALTER TABLE "Orders"
ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;

ALTER TABLE "SalesOrders"
ADD COLUMN IF NOT EXISTS "IsInventoryProcessed" boolean NOT NULL DEFAULT false;

-- 2) Reservation table used by FIFO reservation/consumption flows
CREATE TABLE IF NOT EXISTS "InventoryReservations" (
    "Id" uuid NOT NULL,
    "SalesOrderId" uuid NOT NULL,
    "ProductBatchId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "ReservedUnits" integer NOT NULL,
    "Status" integer NOT NULL,
    "CreatedAtUtc" timestamptz NOT NULL,
    "UpdatedAtUtc" timestamptz NULL,
    CONSTRAINT "PK_InventoryReservations" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_InventoryReservations_ProductBatches_ProductBatchId" FOREIGN KEY ("ProductBatchId") REFERENCES "ProductBatches" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_InventoryReservations_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_InventoryReservations_SalesOrderId" ON "InventoryReservations" ("SalesOrderId");
CREATE INDEX IF NOT EXISTS "IX_InventoryReservations_ProductBatchId" ON "InventoryReservations" ("ProductBatchId");
CREATE INDEX IF NOT EXISTS "IX_InventoryReservations_ProductId" ON "InventoryReservations" ("ProductId");
CREATE INDEX IF NOT EXISTS "IX_InventoryReservations_OrderBatchStatus" ON "InventoryReservations" ("SalesOrderId", "ProductBatchId", "Status");

-- 3) Optional safety: for already delivered orders from old flow,
-- mark processed only when matching SALE ledger exists to prevent duplicate deduction.
UPDATE "Orders" o
SET "IsInventoryProcessed" = true
WHERE o."Status" = 4 -- Delivered
  AND EXISTS (
      SELECT 1
      FROM "InventoryLedgers" l
      WHERE l."CompanyId" = o."CompanyId"
        AND l."Reference" = o."OrderNumber"
        AND l."ReferenceType" = 'SALE'
  );
