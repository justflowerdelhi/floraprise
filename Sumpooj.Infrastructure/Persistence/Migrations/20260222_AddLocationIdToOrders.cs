using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Adds required LocationId column to Orders table with FK to Locations.
    /// </summary>
    public partial class AddLocationIdToOrders : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Step 1: Add the column as nullable first (to handle existing rows)
            migrationBuilder.AddColumn<Guid>(
                name: "LocationId",
                table: "Orders",
                type: "uuid",
                nullable: true);

            // Step 2: Backfill existing orders with the company's default location
            migrationBuilder.Sql(@"
                UPDATE ""Orders"" o
                SET ""LocationId"" = (
                    SELECT l.""Id""
                    FROM ""Locations"" l
                    WHERE l.""CompanyId"" = o.""CompanyId""
                      AND l.""IsDefault"" = TRUE
                    LIMIT 1
                )
                WHERE o.""LocationId"" IS NULL;
            ");

            // Step 3: For any remaining NULLs, use the first active location for the company
            migrationBuilder.Sql(@"
                UPDATE ""Orders"" o
                SET ""LocationId"" = (
                    SELECT l.""Id""
                    FROM ""Locations"" l
                    WHERE l.""CompanyId"" = o.""CompanyId""
                      AND l.""IsActive"" = TRUE
                    ORDER BY l.""CreatedAtUtc""
                    LIMIT 1
                )
                WHERE o.""LocationId"" IS NULL;
            ");

            // Step 4: Make the column NOT NULL now that all rows have a value
            migrationBuilder.AlterColumn<Guid>(
                name: "LocationId",
                table: "Orders",
                type: "uuid",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            // Step 5: Create index on LocationId for query performance
            migrationBuilder.CreateIndex(
                name: "IX_Orders_LocationId",
                table: "Orders",
                column: "LocationId");

            // Step 6: Add FK constraint
            migrationBuilder.AddForeignKey(
                name: "FK_Orders_Locations_LocationId",
                table: "Orders",
                column: "LocationId",
                principalTable: "Locations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_Locations_LocationId",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_LocationId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "LocationId",
                table: "Orders");
        }
    }
}
