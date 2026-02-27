-- =====================================================
-- SUMPOOJ FLORIST ERP - Migration Script
-- Add SalesOrders, SalesOrderItems tables
-- Add DriverStatus column to Staff
-- =====================================================

-- =====================================================
-- SALES ORDER TABLE (Phone/Walk-in Orders)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'SalesOrders'
    ) THEN
        CREATE TABLE "SalesOrders" (
            "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
            "CompanyId" UUID NOT NULL,
            "CustomerId" UUID NOT NULL,
            "OrderNumber" VARCHAR(50) NOT NULL,
            "OrderType" INTEGER NOT NULL DEFAULT 0,
            "Status" INTEGER NOT NULL DEFAULT 0,
            "InvoiceNumber" VARCHAR(50) NULL,
            "DeliveryAddressLine1" VARCHAR(500) NOT NULL DEFAULT '',
            "DeliveryAddressLine2" VARCHAR(500) NULL,
            "City" VARCHAR(200) NOT NULL DEFAULT '',
            "PostalCode" VARCHAR(20) NOT NULL DEFAULT '',
            "State" VARCHAR(200) NULL,
            "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "UpdatedAtUtc" TIMESTAMPTZ NULL,
            CONSTRAINT "PK_SalesOrders" PRIMARY KEY ("Id"),
            CONSTRAINT "FK_SalesOrders_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
            CONSTRAINT "FK_SalesOrders_Customers" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE RESTRICT
        );

        CREATE INDEX "IX_SalesOrders_CompanyId" ON "SalesOrders" ("CompanyId");
        CREATE INDEX "IX_SalesOrders_CustomerId" ON "SalesOrders" ("CustomerId");

        RAISE NOTICE 'SalesOrders table created successfully.';
    END IF;
END $$;

-- =====================================================
-- SALES ORDER ITEM TABLE
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'SalesOrderItems'
    ) THEN
        CREATE TABLE "SalesOrderItems" (
            "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
            "SalesOrderId" UUID NOT NULL,
            "ProductId" UUID NOT NULL,
            "ProductName" VARCHAR(200) NOT NULL,
            "Quantity" INTEGER NOT NULL DEFAULT 0,
            "UnitPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
            "TotalPrice" DECIMAL(18,2) NOT NULL DEFAULT 0,
            CONSTRAINT "PK_SalesOrderItems" PRIMARY KEY ("Id"),
            CONSTRAINT "FK_SalesOrderItems_SalesOrders" FOREIGN KEY ("SalesOrderId") REFERENCES "SalesOrders" ("Id") ON DELETE CASCADE
        );

        CREATE INDEX "IX_SalesOrderItems_SalesOrderId" ON "SalesOrderItems" ("SalesOrderId");

        RAISE NOTICE 'SalesOrderItems table created successfully.';
    END IF;
END $$;

-- =====================================================
-- ADD DriverStatus COLUMN TO Staff TABLE
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Staff' AND column_name = 'DriverStatus'
    ) THEN
        ALTER TABLE "Staff" ADD COLUMN "DriverStatus" INTEGER NOT NULL DEFAULT 0;
        RAISE NOTICE 'DriverStatus column added to Staff table.';
    END IF;
END $$;

-- =====================================================
-- COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Migration 009 completed: SalesOrders, SalesOrderItems tables and Staff.DriverStatus column added.';
END $$;
