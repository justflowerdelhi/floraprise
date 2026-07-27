using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Floraprise.License.Api.Migrations;

public partial class InitialCreate : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "Customers",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                BusinessName = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: false),
                OwnerName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                Mobile = table.Column<string>(type: "character varying(32)", maxLength: 32, nullable: false),
                Email = table.Column<string>(type: "character varying(160)", maxLength: 160, nullable: true),
                City = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                State = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                Country = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Customers", x => x.Id);
            });

        migrationBuilder.CreateTable(
            name: "Devices",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                DeviceId = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                Platform = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                Model = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: true),
                AndroidVersion = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: true),
                AppVersion = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                RegisteredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                LastSeen = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Devices", x => x.Id);
                table.ForeignKey(
                    name: "FK_Devices_Customers_CustomerId",
                    column: x => x.CustomerId,
                    principalTable: "Customers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateTable(
            name: "Licenses",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                CustomerId = table.Column<Guid>(type: "uuid", nullable: false),
                Plan = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                Status = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                TrialStart = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                TrialEnd = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                LicenseStart = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                LicenseEnd = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_Licenses", x => x.Id);
                table.ForeignKey(
                    name: "FK_Licenses_Customers_CustomerId",
                    column: x => x.CustomerId,
                    principalTable: "Customers",
                    principalColumn: "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_Customers_Mobile",
            table: "Customers",
            column: "Mobile",
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Devices_CustomerId_DeviceId",
            table: "Devices",
            columns: new[] { "CustomerId", "DeviceId" },
            unique: true);

        migrationBuilder.CreateIndex(
            name: "IX_Licenses_CustomerId",
            table: "Licenses",
            column: "CustomerId",
            unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable(name: "Devices");
        migrationBuilder.DropTable(name: "Licenses");
        migrationBuilder.DropTable(name: "Customers");
    }
}