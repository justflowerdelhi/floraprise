using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixDeliveryPersonFk : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("ALTER TABLE \"Deliveries\" DROP CONSTRAINT IF EXISTS \"FK_Deliveries_Users\";");

            migrationBuilder.CreateIndex(
                name: "IX_Deliveries_DeliveryPersonId",
                table: "Deliveries",
                column: "DeliveryPersonId");

            migrationBuilder.AddForeignKey(
                name: "FK_Deliveries_Staff_DeliveryPersonId",
                table: "Deliveries",
                column: "DeliveryPersonId",
                principalTable: "Staff",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Deliveries_Staff_DeliveryPersonId",
                table: "Deliveries");

            migrationBuilder.DropIndex(
                name: "IX_Deliveries_DeliveryPersonId",
                table: "Deliveries");
        }
    }
}
