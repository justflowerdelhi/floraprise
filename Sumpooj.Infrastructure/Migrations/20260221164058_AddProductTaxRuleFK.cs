using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddProductTaxRuleFK : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "TaxRuleId",
                table: "Products",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Products_TaxRuleId",
                table: "Products",
                column: "TaxRuleId");

            migrationBuilder.AddForeignKey(
                name: "FK_Products_tax_rules_TaxRuleId",
                table: "Products",
                column: "TaxRuleId",
                principalTable: "tax_rules",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Products_tax_rules_TaxRuleId",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_Products_TaxRuleId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "TaxRuleId",
                table: "Products");
        }
    }
}
