using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeliveryTrackingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CustomerEmail",
                table: "Deliveries",
                type: "character varying(256)",
                maxLength: 256,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "CustomerPhone",
                table: "Deliveries",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryAddressLatitude",
                table: "Deliveries",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "DeliveryAddressLongitude",
                table: "Deliveries",
                type: "double precision",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TrackingToken",
                table: "Deliveries",
                type: "character varying(256)",
                maxLength: 256,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CustomerEmail",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "CustomerPhone",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "DeliveryAddressLatitude",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "DeliveryAddressLongitude",
                table: "Deliveries");

            migrationBuilder.DropColumn(
                name: "TrackingToken",
                table: "Deliveries");
        }
    }
}
