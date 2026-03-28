-- =====================================================
-- Migration 017: Corporate Client Module (B2B ERP Flow)
-- =====================================================

-- 1) Extend Orders for corporate workflows
ALTER TABLE "Orders"
    ADD COLUMN IF NOT EXISTS "CustomerType" INTEGER NOT NULL DEFAULT 0;

-- 2) Extend PaymentStatus enum storage compatibility by convention
--    No schema change required because PaymentStatus is stored as integer.

-- 3) Corporate Clients
CREATE TABLE IF NOT EXISTS "CorporateClients" (
    "Id" UUID NOT NULL,
    "CompanyId" UUID NOT NULL,
    "CustomerId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "BillingEmail" VARCHAR(200) NOT NULL,
    "Phone" VARCHAR(30) NULL,
    "CreditLimit" NUMERIC(18,2) NULL,
    "PaymentTerms" VARCHAR(100) NULL,
    "BillingCycle" VARCHAR(30) NOT NULL DEFAULT 'MONTHLY',
    "DefaultProductId" UUID NULL,
    "DefaultMessage" TEXT NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_CorporateClients" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_CorporateClients_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateClients_Customers" FOREIGN KEY ("CustomerId") REFERENCES "Customers" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_CorporateClients_Products_Default" FOREIGN KEY ("DefaultProductId") REFERENCES "Products" ("Id") ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "IX_CorporateClients_CompanyId_Name"
    ON "CorporateClients" ("CompanyId", "Name");

-- 4) Corporate Employees
CREATE TABLE IF NOT EXISTS "CorporateEmployees" (
    "Id" UUID NOT NULL,
    "CompanyId" UUID NOT NULL,
    "ClientId" UUID NOT NULL,
    "Name" VARCHAR(200) NOT NULL,
    "DateOfBirth" TIMESTAMPTZ NOT NULL,
    "Address" TEXT NULL,
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_CorporateEmployees" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_CorporateEmployees_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateEmployees_CorporateClients" FOREIGN KEY ("ClientId") REFERENCES "CorporateClients" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_CorporateEmployees_ClientId"
    ON "CorporateEmployees" ("ClientId");

CREATE INDEX IF NOT EXISTS "IX_CorporateEmployees_CompanyId_Birthday"
    ON "CorporateEmployees" ("CompanyId", "DateOfBirth");

-- 5) Corporate Order Metadata
CREATE TABLE IF NOT EXISTS "CorporateOrderMetas" (
    "Id" UUID NOT NULL,
    "CompanyId" UUID NOT NULL,
    "OrderId" UUID NOT NULL,
    "ClientId" UUID NOT NULL,
    "EmployeeId" UUID NULL,
    "BillingStatus" INTEGER NOT NULL DEFAULT 0,
    "IsAutoCreated" BOOLEAN NOT NULL DEFAULT FALSE,
    "NeedsApproval" BOOLEAN NOT NULL DEFAULT FALSE,
    "AutomationDateUtc" TIMESTAMPTZ NULL,
    "IsAccountingPosted" BOOLEAN NOT NULL DEFAULT FALSE,
    "IsInventoryPosted" BOOLEAN NOT NULL DEFAULT FALSE,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_CorporateOrderMetas" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_CorporateOrderMetas_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateOrderMetas_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateOrderMetas_Clients" FOREIGN KEY ("ClientId") REFERENCES "CorporateClients" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_CorporateOrderMetas_Employees" FOREIGN KEY ("EmployeeId") REFERENCES "CorporateEmployees" ("Id") ON DELETE SET NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_CompanyId_OrderId"
    ON "CorporateOrderMetas" ("CompanyId", "OrderId");

CREATE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_ClientId_BillingStatus"
    ON "CorporateOrderMetas" ("ClientId", "BillingStatus");

CREATE INDEX IF NOT EXISTS "IX_CorporateOrderMetas_Employee_AutomationDate"
    ON "CorporateOrderMetas" ("EmployeeId", "AutomationDateUtc");

-- 6) Corporate Invoices
CREATE TABLE IF NOT EXISTS "CorporateInvoices" (
    "Id" UUID NOT NULL,
    "CompanyId" UUID NOT NULL,
    "ClientId" UUID NOT NULL,
    "StartDateUtc" TIMESTAMPTZ NOT NULL,
    "EndDateUtc" TIMESTAMPTZ NOT NULL,
    "TotalAmount" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "Status" INTEGER NOT NULL DEFAULT 0,
    "PaidAtUtc" TIMESTAMPTZ NULL,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_CorporateInvoices" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_CorporateInvoices_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateInvoices_Clients" FOREIGN KEY ("ClientId") REFERENCES "CorporateClients" ("Id") ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS "IX_CorporateInvoices_ClientId_CreatedAt"
    ON "CorporateInvoices" ("ClientId", "CreatedAtUtc" DESC);

-- 7) Corporate Invoice Lines
CREATE TABLE IF NOT EXISTS "CorporateInvoiceLines" (
    "Id" UUID NOT NULL,
    "CompanyId" UUID NOT NULL,
    "InvoiceId" UUID NOT NULL,
    "OrderId" UUID NOT NULL,
    "OrderNumber" VARCHAR(50) NOT NULL,
    "OrderDateUtc" TIMESTAMPTZ NOT NULL,
    "Amount" NUMERIC(18,2) NOT NULL DEFAULT 0,
    "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc" TIMESTAMPTZ NULL,
    CONSTRAINT "PK_CorporateInvoiceLines" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_CorporateInvoiceLines_Invoices" FOREIGN KEY ("InvoiceId") REFERENCES "CorporateInvoices" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_CorporateInvoiceLines_Orders" FOREIGN KEY ("OrderId") REFERENCES "Orders" ("Id") ON DELETE RESTRICT,
    CONSTRAINT "FK_CorporateInvoiceLines_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_CorporateInvoiceLines_InvoiceId"
    ON "CorporateInvoiceLines" ("InvoiceId");
