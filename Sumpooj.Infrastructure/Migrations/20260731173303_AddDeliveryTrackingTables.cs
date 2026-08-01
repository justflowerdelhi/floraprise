using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDeliveryTrackingTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DeliveryLocations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DeliveryId = table.Column<Guid>(type: "uuid", nullable: false),
                    Latitude = table.Column<double>(type: "double precision", nullable: false),
                    Longitude = table.Column<double>(type: "double precision", nullable: false),
                    SpeedKph = table.Column<double>(type: "double precision", nullable: false),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DeliveryRouteId = table.Column<Guid>(type: "uuid", nullable: true),
                    DriverId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryLocations", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DeliveryProofs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DeliveryId = table.Column<Guid>(type: "uuid", nullable: false),
                    PhotoUrl = table.Column<string>(type: "text", nullable: false),
                    RecipientName = table.Column<string>(type: "text", nullable: true),
                    Note = table.Column<string>(type: "text", nullable: true),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    OTPCode = table.Column<string>(type: "text", nullable: true),
                    OTPVerified = table.Column<bool>(type: "boolean", nullable: false),
                    OTPVerifiedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CompletionLatitude = table.Column<double>(type: "double precision", nullable: true),
                    CompletionLongitude = table.Column<double>(type: "double precision", nullable: true),
                    UploadedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    UploadedByUserName = table.Column<string>(type: "text", nullable: true),
                    SignatureData = table.Column<string>(type: "text", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryProofs", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "DeliveryTimelines",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DeliveryId = table.Column<Guid>(type: "uuid", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    Note = table.Column<string>(type: "text", nullable: true),
                    RecordedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ChangedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ChangedByUserName = table.Column<string>(type: "text", nullable: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DeliveryTimelines", x => x.Id);
                });

        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DeliveryLocations");

            migrationBuilder.DropTable(
                name: "DeliveryProofs");

            migrationBuilder.DropTable(
                name: "DeliveryTimelines");
        }
    }
}
