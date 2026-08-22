using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    public partial class AddDriverLocationsTable : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DriverLocations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DriverId = table.Column<Guid>(type: "uuid", nullable: false),
                    DeliveryId = table.Column<Guid>(type: "uuid", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    Accuracy = table.Column<double>(type: "double precision", nullable: true),
                    Speed = table.Column<double>(type: "double precision", nullable: true),
                    Heading = table.Column<double>(type: "double precision", nullable: true),
                    Altitude = table.Column<double>(type: "double precision", nullable: true),
                    BatteryLevel = table.Column<int>(type: "integer", nullable: true),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DriverLocations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DriverLocations_Deliveries_DeliveryId",
                        column: x => x.DeliveryId,
                        principalTable: "Deliveries",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_DeliveryId",
                table: "DriverLocations",
                column: "DeliveryId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_DriverId",
                table: "DriverLocations",
                column: "DriverId");

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_RecordedAt",
                table: "DriverLocations",
                column: "RecordedAt");

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_CreatedAtUtc",
                table: "DriverLocations",
                column: "CreatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_DriverId_DeliveryId",
                table: "DriverLocations",
                columns: new[] { "DriverId", "DeliveryId" });

            migrationBuilder.CreateIndex(
                name: "IX_DriverLocations_DriverId_RecordedAt",
                table: "DriverLocations",
                columns: new[] { "DriverId", "RecordedAt" });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DriverLocations");
        }
    }
}