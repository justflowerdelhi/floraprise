START TRANSACTION;
ALTER TABLE "Payments" ADD "ClientPaymentId" text;

ALTER TABLE "Payments" ADD "Reference" character varying(256);

ALTER TABLE "Orders" ADD "PosRoundOffAmount" numeric(18,2) NOT NULL DEFAULT 0.0;

ALTER TABLE "Orders" ADD "RewardDiscountAmount" numeric(18,2) NOT NULL DEFAULT 0.0;

ALTER TABLE "OrderItems" ADD "ClientOrderLineId" text;

ALTER TABLE "OrderItems" ADD "DiscountAmount" numeric(18,2) NOT NULL DEFAULT 0.0;

ALTER TABLE "OrderItems" ADD "DiscountType" text;

ALTER TABLE "OrderItems" ADD "DiscountValue" numeric(18,2);

ALTER TABLE "OrderItems" ADD "LineSubtotal" numeric(18,2);

ALTER TABLE "OrderItems" ADD "LineTaxAmount" numeric(18,2);

ALTER TABLE "OrderItems" ADD "TaxRatePercent" numeric(8,4);

CREATE TABLE "PosSaleSyncReceipts" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "ClientSyncId" text NOT NULL,
    "LocalOrderId" integer NOT NULL,
    "DeviceId" text NOT NULL,
    "CloudOrderId" uuid NOT NULL,
    "CloudCustomerId" uuid,
    "PayloadHash" text NOT NULL,
    "CompletedAtUtc" timestamp with time zone NOT NULL,
    "CreatedAtUtc" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_PosSaleSyncReceipts" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PosSaleSyncReceipts_Customers_CloudCustomerId" FOREIGN KEY ("CloudCustomerId") REFERENCES "Customers" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_PosSaleSyncReceipts_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT
);

CREATE TABLE "PosSaleSyncInventoryTransactions" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "PosSaleSyncReceiptId" uuid NOT NULL,
    "ClientInventoryTransactionId" text NOT NULL,
    "CloudOrderId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Quantity" integer NOT NULL,
    "OccurredAtUtc" timestamp with time zone NOT NULL,
    "CreatedAtUtc" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_PosSaleSyncInventoryTransactions" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PosSaleSyncInventoryTransactions_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_PosSaleSyncInventoryTransactions_PosSaleSyncReceipts_PosSal~" FOREIGN KEY ("PosSaleSyncReceiptId") REFERENCES "PosSaleSyncReceipts" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PosSaleSyncInventoryTransactions_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);

CREATE UNIQUE INDEX "IX_Payments_OrderId_ClientPaymentId" ON "Payments" ("OrderId", "ClientPaymentId") WHERE "ClientPaymentId" IS NOT NULL;

CREATE UNIQUE INDEX "IX_OrderItems_OrderId_ClientOrderLineId" ON "OrderItems" ("OrderId", "ClientOrderLineId") WHERE "ClientOrderLineId" IS NOT NULL;

CREATE INDEX "IX_PosSaleSyncInventoryTransactions_CloudOrderId" ON "PosSaleSyncInventoryTransactions" ("CloudOrderId");

CREATE UNIQUE INDEX "IX_PosSaleSyncInventoryTransactions_CompanyId_ClientInventoryT~" ON "PosSaleSyncInventoryTransactions" ("CompanyId", "ClientInventoryTransactionId");

CREATE INDEX "IX_PosSaleSyncInventoryTransactions_PosSaleSyncReceiptId_Creat~" ON "PosSaleSyncInventoryTransactions" ("PosSaleSyncReceiptId", "CreatedAtUtc");

CREATE INDEX "IX_PosSaleSyncInventoryTransactions_ProductId" ON "PosSaleSyncInventoryTransactions" ("ProductId");

CREATE INDEX "IX_PosSaleSyncReceipts_CloudCustomerId" ON "PosSaleSyncReceipts" ("CloudCustomerId");

CREATE INDEX "IX_PosSaleSyncReceipts_CloudOrderId" ON "PosSaleSyncReceipts" ("CloudOrderId");

CREATE UNIQUE INDEX "IX_PosSaleSyncReceipts_CompanyId_ClientSyncId" ON "PosSaleSyncReceipts" ("CompanyId", "ClientSyncId");

CREATE UNIQUE INDEX "IX_PosSaleSyncReceipts_CompanyId_DeviceId_LocalOrderId" ON "PosSaleSyncReceipts" ("CompanyId", "DeviceId", "LocalOrderId");

COMMIT;

START TRANSACTION;
CREATE TABLE "PosSaleSyncOrderLines" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "PosSaleSyncReceiptId" uuid NOT NULL,
    "CloudOrderId" uuid NOT NULL,
    "ClientOrderLineId" text NOT NULL,
    "LocalOrderLineId" integer NOT NULL,
    "LocalProductId" integer,
    "CloudProductId" uuid,
    "Source" text,
    "DesignRef" text,
    "Description" text NOT NULL,
    "Quantity" integer NOT NULL,
    "UnitPrice" numeric(18,2) NOT NULL,
    "TaxRatePercent" numeric(8,4),
    "DiscountType" text,
    "DiscountValue" numeric(18,2),
    "DiscountAmount" numeric(18,2) NOT NULL,
    "LineSubtotal" numeric(18,2) NOT NULL,
    "LineTaxAmount" numeric(18,2) NOT NULL,
    "LineTotal" numeric(18,2) NOT NULL,
    "CreatedAtUtc" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_PosSaleSyncOrderLines" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PosSaleSyncOrderLines_Orders_CloudOrderId" FOREIGN KEY ("CloudOrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_PosSaleSyncOrderLines_PosSaleSyncReceipts_PosSaleSyncReceip~" FOREIGN KEY ("PosSaleSyncReceiptId") REFERENCES "PosSaleSyncReceipts" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_PosSaleSyncOrderLines_Products_CloudProductId" FOREIGN KEY ("CloudProductId") REFERENCES "Products" ("Id") ON DELETE RESTRICT
);

CREATE INDEX "IX_PosSaleSyncOrderLines_CloudOrderId" ON "PosSaleSyncOrderLines" ("CloudOrderId");

CREATE INDEX "IX_PosSaleSyncOrderLines_CloudProductId" ON "PosSaleSyncOrderLines" ("CloudProductId");

CREATE UNIQUE INDEX "IX_PosSaleSyncOrderLines_PosSaleSyncReceiptId_ClientOrderLineId" ON "PosSaleSyncOrderLines" ("PosSaleSyncReceiptId", "ClientOrderLineId");

COMMIT;