using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddIsInventoryProcessed : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // All operations use IF NOT EXISTS / IF NOT EXISTS patterns because
            // several of these were already applied via raw SQL scripts (010, 017, 020).
            // This makes the migration idempotent against any deployment order.

            // ── Column additions ─────────────────────────────────────────────────────
            migrationBuilder.Sql(@"ALTER TABLE ""SalesOrders"" ADD COLUMN IF NOT EXISTS ""IsInventoryProcessed"" boolean NOT NULL DEFAULT false;");
            migrationBuilder.Sql(@"ALTER TABLE ""PurchaseOrders"" ADD COLUMN IF NOT EXISTS ""IsInventoryProcessed"" boolean NOT NULL DEFAULT false;");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" ADD COLUMN IF NOT EXISTS ""CustomerType"" integer NOT NULL DEFAULT 0;");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" ADD COLUMN IF NOT EXISTS ""DeliveryPincode"" text;");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" ADD COLUMN IF NOT EXISTS ""IsInventoryProcessed"" boolean NOT NULL DEFAULT false;");
            migrationBuilder.Sql(@"ALTER TABLE ""Deliveries"" ADD COLUMN IF NOT EXISTS ""CompanyId"" uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid;");

            // ── Table creation (idempotent) ───────────────────────────────────────────
            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""CorporateClients"" (
    ""Id"" uuid NOT NULL,
    ""CompanyId"" uuid NOT NULL,
    ""CustomerId"" uuid NOT NULL,
    ""Name"" text NOT NULL,
    ""BillingEmail"" text NOT NULL,
    ""Phone"" text NULL,
    ""CreditLimit"" numeric NULL,
    ""PaymentTerms"" text NULL,
    ""BillingCycle"" text NOT NULL,
    ""DefaultProductId"" uuid NULL,
    ""DefaultMessage"" text NULL,
    ""IsActive"" boolean NOT NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_CorporateClients"" PRIMARY KEY (""Id"")
);");

            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""InventoryReservations"" (
    ""Id"" uuid NOT NULL,
    ""SalesOrderId"" uuid NOT NULL,
    ""ProductBatchId"" uuid NOT NULL,
    ""ProductId"" uuid NOT NULL,
    ""ReservedUnits"" integer NOT NULL,
    ""Status"" integer NOT NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_InventoryReservations"" PRIMARY KEY (""Id"")
);");

            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""CorporateEmployees"" (
    ""Id"" uuid NOT NULL,
    ""CompanyId"" uuid NOT NULL,
    ""ClientId"" uuid NOT NULL,
    ""Name"" text NOT NULL,
    ""DateOfBirth"" timestamp with time zone NOT NULL,
    ""Address"" text NULL,
    ""IsActive"" boolean NOT NULL,
    ""CorporateClientId"" uuid NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_CorporateEmployees"" PRIMARY KEY (""Id"")
);");

            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""CorporateInvoices"" (
    ""Id"" uuid NOT NULL,
    ""CompanyId"" uuid NOT NULL,
    ""ClientId"" uuid NOT NULL,
    ""StartDateUtc"" timestamp with time zone NOT NULL,
    ""EndDateUtc"" timestamp with time zone NOT NULL,
    ""TotalAmount"" numeric NOT NULL,
    ""Status"" integer NOT NULL,
    ""PaidAtUtc"" timestamp with time zone NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_CorporateInvoices"" PRIMARY KEY (""Id"")
);");

            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""CorporateOrderMetas"" (
    ""Id"" uuid NOT NULL,
    ""CompanyId"" uuid NOT NULL,
    ""OrderId"" uuid NOT NULL,
    ""ClientId"" uuid NOT NULL,
    ""EmployeeId"" uuid NULL,
    ""BillingStatus"" integer NOT NULL,
    ""IsAutoCreated"" boolean NOT NULL,
    ""NeedsApproval"" boolean NOT NULL,
    ""AutomationDateUtc"" timestamp with time zone NULL,
    ""IsAccountingPosted"" boolean NOT NULL,
    ""IsInventoryPosted"" boolean NOT NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_CorporateOrderMetas"" PRIMARY KEY (""Id"")
);");

            migrationBuilder.Sql(@"
CREATE TABLE IF NOT EXISTS ""CorporateInvoiceLines"" (
    ""Id"" uuid NOT NULL,
    ""CompanyId"" uuid NOT NULL,
    ""InvoiceId"" uuid NOT NULL,
    ""OrderId"" uuid NOT NULL,
    ""OrderNumber"" text NOT NULL,
    ""OrderDateUtc"" timestamp with time zone NOT NULL,
    ""Amount"" numeric NOT NULL,
    ""CreatedAtUtc"" timestamp with time zone NOT NULL,
    ""UpdatedAtUtc"" timestamp with time zone NULL,
    CONSTRAINT ""PK_CorporateInvoiceLines"" PRIMARY KEY (""Id"")
);");

            // ── Indexes (idempotent) ──────────────────────────────────────────────────
            migrationBuilder.Sql(@"CREATE UNIQUE INDEX IF NOT EXISTS ""IX_ProductBatches_ProductId_BatchNumber"" ON ""ProductBatches"" (""ProductId"", ""BatchNumber"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateClients_CompanyId_Name"" ON ""CorporateClients"" (""CompanyId"", ""Name"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateClients_CustomerId"" ON ""CorporateClients"" (""CustomerId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateEmployees_ClientId"" ON ""CorporateEmployees"" (""ClientId"");");
            migrationBuilder.Sql(@"ALTER TABLE ""CorporateEmployees"" ADD COLUMN IF NOT EXISTS ""CorporateClientId"" uuid NULL;");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateEmployees_CorporateClientId"" ON ""CorporateEmployees"" (""CorporateClientId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateInvoiceLines_InvoiceId"" ON ""CorporateInvoiceLines"" (""InvoiceId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateInvoices_ClientId"" ON ""CorporateInvoices"" (""ClientId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateOrderMetas_ClientId"" ON ""CorporateOrderMetas"" (""ClientId"");");
            migrationBuilder.Sql(@"CREATE UNIQUE INDEX IF NOT EXISTS ""IX_CorporateOrderMetas_CompanyId_OrderId"" ON ""CorporateOrderMetas"" (""CompanyId"", ""OrderId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateOrderMetas_EmployeeId"" ON ""CorporateOrderMetas"" (""EmployeeId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_CorporateOrderMetas_OrderId"" ON ""CorporateOrderMetas"" (""OrderId"");");
            migrationBuilder.Sql(@"CREATE INDEX IF NOT EXISTS ""IX_InventoryReservations_SalesOrderId_ProductBatchId_Status"" ON ""InventoryReservations"" (""SalesOrderId"", ""ProductBatchId"", ""Status"");");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""CorporateInvoiceLines"";");
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""CorporateOrderMetas"";");
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""InventoryReservations"";");
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""CorporateInvoices"";");
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""CorporateEmployees"";");
            migrationBuilder.Sql(@"DROP TABLE IF EXISTS ""CorporateClients"";");
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_ProductBatches_ProductId_BatchNumber"";");
                migrationBuilder.Sql(@"ALTER TABLE ""CorporateEmployees"" DROP COLUMN IF EXISTS ""CorporateClientId"";");
                migrationBuilder.Sql(@"ALTER TABLE ""SalesOrders"" DROP COLUMN IF EXISTS ""IsInventoryProcessed"";");
            migrationBuilder.Sql(@"ALTER TABLE ""PurchaseOrders"" DROP COLUMN IF EXISTS ""IsInventoryProcessed"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" DROP COLUMN IF EXISTS ""CustomerType"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" DROP COLUMN IF EXISTS ""DeliveryPincode"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Orders"" DROP COLUMN IF EXISTS ""IsInventoryProcessed"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Deliveries"" DROP COLUMN IF EXISTS ""CompanyId"";");
        }
    }
}
