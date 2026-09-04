using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPosSalesSyncPersistence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ClientPaymentId",
                table: "Payments",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Reference",
                table: "Payments",
                type: "character varying(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "PosRoundOffAmount",
                table: "Orders",
                type: "numeric(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<decimal>(
                name: "RewardDiscountAmount",
                table: "Orders",
                type: "numeric(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "ClientOrderLineId",
                table: "OrderItems",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DiscountAmount",
                table: "OrderItems",
                type: "numeric(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "DiscountType",
                table: "OrderItems",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "DiscountValue",
                table: "OrderItems",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "LineSubtotal",
                table: "OrderItems",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "LineTaxAmount",
                table: "OrderItems",
                type: "numeric(18,2)",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "TaxRatePercent",
                table: "OrderItems",
                type: "numeric(8,4)",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "PosSaleSyncReceipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientSyncId = table.Column<string>(type: "text", nullable: false),
                    LocalOrderId = table.Column<int>(type: "integer", nullable: false),
                    DeviceId = table.Column<string>(type: "text", nullable: false),
                    CloudOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    CloudCustomerId = table.Column<Guid>(type: "uuid", nullable: true),
                    PayloadHash = table.Column<string>(type: "text", nullable: false),
                    CompletedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PosSaleSyncReceipts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncReceipts_Customers_CloudCustomerId",
                        column: x => x.CloudCustomerId,
                        principalTable: "Customers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncReceipts_Orders_CloudOrderId",
                        column: x => x.CloudOrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "PosSaleSyncInventoryTransactions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    PosSaleSyncReceiptId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientInventoryTransactionId = table.Column<string>(type: "text", nullable: false),
                    CloudOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    OccurredAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PosSaleSyncInventoryTransactions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncInventoryTransactions_Orders_CloudOrderId",
                        column: x => x.CloudOrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncInventoryTransactions_PosSaleSyncReceipts_PosSal~",
                        column: x => x.PosSaleSyncReceiptId,
                        principalTable: "PosSaleSyncReceipts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncInventoryTransactions_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Payments_OrderId_ClientPaymentId",
                table: "Payments",
                columns: new[] { "OrderId", "ClientPaymentId" },
                unique: true,
                filter: "\"ClientPaymentId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_OrderItems_OrderId_ClientOrderLineId",
                table: "OrderItems",
                columns: new[] { "OrderId", "ClientOrderLineId" },
                unique: true,
                filter: "\"ClientOrderLineId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncInventoryTransactions_CloudOrderId",
                table: "PosSaleSyncInventoryTransactions",
                column: "CloudOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncInventoryTransactions_CompanyId_ClientInventoryT~",
                table: "PosSaleSyncInventoryTransactions",
                columns: new[] { "CompanyId", "ClientInventoryTransactionId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncInventoryTransactions_PosSaleSyncReceiptId_Creat~",
                table: "PosSaleSyncInventoryTransactions",
                columns: new[] { "PosSaleSyncReceiptId", "CreatedAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncInventoryTransactions_ProductId",
                table: "PosSaleSyncInventoryTransactions",
                column: "ProductId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncReceipts_CloudCustomerId",
                table: "PosSaleSyncReceipts",
                column: "CloudCustomerId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncReceipts_CloudOrderId",
                table: "PosSaleSyncReceipts",
                column: "CloudOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncReceipts_CompanyId_ClientSyncId",
                table: "PosSaleSyncReceipts",
                columns: new[] { "CompanyId", "ClientSyncId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncReceipts_CompanyId_DeviceId_LocalOrderId",
                table: "PosSaleSyncReceipts",
                columns: new[] { "CompanyId", "DeviceId", "LocalOrderId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PosSaleSyncInventoryTransactions");

            migrationBuilder.DropTable(
                name: "PosSaleSyncReceipts");

            migrationBuilder.DropIndex(
                name: "IX_Payments_OrderId_ClientPaymentId",
                table: "Payments");

            migrationBuilder.DropIndex(
                name: "IX_OrderItems_OrderId_ClientOrderLineId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "ClientPaymentId",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "Reference",
                table: "Payments");

            migrationBuilder.DropColumn(
                name: "PosRoundOffAmount",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "RewardDiscountAmount",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "ClientOrderLineId",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "DiscountAmount",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "DiscountType",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "DiscountValue",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "LineSubtotal",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "LineTaxAmount",
                table: "OrderItems");

            migrationBuilder.DropColumn(
                name: "TaxRatePercent",
                table: "OrderItems");
        }
    }
}
