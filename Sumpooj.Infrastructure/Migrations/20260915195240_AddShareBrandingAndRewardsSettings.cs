using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddShareBrandingAndRewardsSettings : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DefaultUnit",
                table: "ProductCategories",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "OperatorName",
                table: "FinishedGoodsBatches",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReversalNote",
                table: "FinishedGoodsBatches",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ReversedAt",
                table: "FinishedGoodsBatches",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "CashExpenses",
                table: "DayCloses",
                type: "numeric",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.CreateTable(
                name: "RewardsSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    Enabled = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    EarnSpendPaisePerPoint = table.Column<int>(type: "integer", nullable: false, defaultValue: 10000),
                    MinimumBillPaise = table.Column<int>(type: "integer", nullable: false, defaultValue: 30000),
                    PointValuePaise = table.Column<int>(type: "integer", nullable: false, defaultValue: 100),
                    MaximumRedemptionPercent = table.Column<int>(type: "integer", nullable: false, defaultValue: 20),
                    ExpiryDays = table.Column<int>(type: "integer", nullable: false, defaultValue: 365),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RewardsSettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RewardsSettings_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ShareBrandingSettings",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    CompanyId = table.Column<Guid>(type: "uuid", nullable: false),
                    ShowPrice = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowShopName = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowPhoneNumber = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowWebsite = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowLogo = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    ShowWatermark = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowWatermarkBusinessName = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    ShowWatermarkCity = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    WatermarkOpacity = table.Column<double>(type: "double precision", nullable: false, defaultValue: 0.71999999999999997),
                    WatermarkSize = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "medium"),
                    WatermarkPosition = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "bottomCenter"),
                    FooterColorArgb = table.Column<long>(type: "bigint", nullable: false, defaultValue: 3424345632L),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ShareBrandingSettings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ShareBrandingSettings_Companies_CompanyId",
                        column: x => x.CompanyId,
                        principalTable: "Companies",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RewardsSettings_CompanyId",
                table: "RewardsSettings",
                column: "CompanyId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ShareBrandingSettings_CompanyId",
                table: "ShareBrandingSettings",
                column: "CompanyId",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RewardsSettings");

            migrationBuilder.DropTable(
                name: "ShareBrandingSettings");

            migrationBuilder.DropColumn(
                name: "DefaultUnit",
                table: "ProductCategories");

            migrationBuilder.DropColumn(
                name: "OperatorName",
                table: "FinishedGoodsBatches");

            migrationBuilder.DropColumn(
                name: "ReversalNote",
                table: "FinishedGoodsBatches");

            migrationBuilder.DropColumn(
                name: "ReversedAt",
                table: "FinishedGoodsBatches");

            migrationBuilder.DropColumn(
                name: "CashExpenses",
                table: "DayCloses");
        }
    }
}
