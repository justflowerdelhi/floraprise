using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderDesignerStaffAssignment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "AssignedDesignerStaffId",
                table: "Orders",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Orders_AssignedDesignerStaffId",
                table: "Orders",
                column: "AssignedDesignerStaffId");

            migrationBuilder.AddForeignKey(
                name: "FK_Orders_AssignedDesignerStaff",
                table: "Orders",
                column: "AssignedDesignerStaffId",
                principalTable: "Staff",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Orders_AssignedDesignerStaff",
                table: "Orders");

            migrationBuilder.DropIndex(
                name: "IX_Orders_AssignedDesignerStaffId",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "AssignedDesignerStaffId",
                table: "Orders");
        }
    }
}
