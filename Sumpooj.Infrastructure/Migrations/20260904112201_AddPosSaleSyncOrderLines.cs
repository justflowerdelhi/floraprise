using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddPosSaleSyncOrderLines : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "PosSaleSyncOrderLines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    PosSaleSyncReceiptId = table.Column<Guid>(type: "uuid", nullable: false),
                    CloudOrderId = table.Column<Guid>(type: "uuid", nullable: false),
                    ClientOrderLineId = table.Column<string>(type: "text", nullable: false),
                    LocalOrderLineId = table.Column<int>(type: "integer", nullable: false),
                    LocalProductId = table.Column<int>(type: "integer", nullable: true),
                    CloudProductId = table.Column<Guid>(type: "uuid", nullable: true),
                    Source = table.Column<string>(type: "text", nullable: true),
                    DesignRef = table.Column<string>(type: "text", nullable: true),
                    Description = table.Column<string>(type: "text", nullable: false),
                    Quantity = table.Column<int>(type: "integer", nullable: false),
                    UnitPrice = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    TaxRatePercent = table.Column<decimal>(type: "numeric(8,4)", nullable: true),
                    DiscountType = table.Column<string>(type: "text", nullable: true),
                    DiscountValue = table.Column<decimal>(type: "numeric(18,2)", nullable: true),
                    DiscountAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    LineSubtotal = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    LineTaxAmount = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    LineTotal = table.Column<decimal>(type: "numeric(18,2)", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PosSaleSyncOrderLines", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncOrderLines_Orders_CloudOrderId",
                        column: x => x.CloudOrderId,
                        principalTable: "Orders",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncOrderLines_PosSaleSyncReceipts_PosSaleSyncReceip~",
                        column: x => x.PosSaleSyncReceiptId,
                        principalTable: "PosSaleSyncReceipts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_PosSaleSyncOrderLines_Products_CloudProductId",
                        column: x => x.CloudProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncOrderLines_CloudOrderId",
                table: "PosSaleSyncOrderLines",
                column: "CloudOrderId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncOrderLines_CloudProductId",
                table: "PosSaleSyncOrderLines",
                column: "CloudProductId");

            migrationBuilder.CreateIndex(
                name: "IX_PosSaleSyncOrderLines_PosSaleSyncReceiptId_ClientOrderLineId",
                table: "PosSaleSyncOrderLines",
                columns: new[] { "PosSaleSyncReceiptId", "ClientOrderLineId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "PosSaleSyncOrderLines");
        }
    }
}
