using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Adds optional IdentityUserId column to Staff table.
    /// Links a staff member to an ASP.NET Identity user for login access.
    /// FK → AspNetUsers.Id with ON DELETE RESTRICT.
    /// </summary>
    public partial class AddIdentityUserIdToStaff : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add nullable IdentityUserId column (Guid to match ApplicationUser PK)
            migrationBuilder.AddColumn<Guid>(
                name: "IdentityUserId",
                table: "Staff",
                type: "uuid",
                nullable: true);

            // Create index for efficient lookups
            migrationBuilder.CreateIndex(
                name: "IX_Staff_IdentityUserId",
                table: "Staff",
                column: "IdentityUserId");

            // Add FK constraint → AspNetUsers with RESTRICT delete
            migrationBuilder.AddForeignKey(
                name: "FK_Staff_AspNetUsers_IdentityUserId",
                table: "Staff",
                column: "IdentityUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Staff_AspNetUsers_IdentityUserId",
                table: "Staff");

            migrationBuilder.DropIndex(
                name: "IX_Staff_IdentityUserId",
                table: "Staff");

            migrationBuilder.DropColumn(
                name: "IdentityUserId",
                table: "Staff");
        }
    }
}
