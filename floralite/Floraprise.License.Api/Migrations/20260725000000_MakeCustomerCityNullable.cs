using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Floraprise.License.Api.Migrations;

public partial class MakeCustomerCityNullable : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AlterColumn<string>(
            name: "City",
            table: "Customers",
            type: "character varying(100)",
            maxLength: 100,
            nullable: true,
            oldClrType: typeof(string),
            oldType: "character varying(100)",
            oldMaxLength: 100);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.Sql("UPDATE \"Customers\" SET \"City\" = '' WHERE \"City\" IS NULL;");

        migrationBuilder.AlterColumn<string>(
            name: "City",
            table: "Customers",
            type: "character varying(100)",
            maxLength: 100,
            nullable: false,
            defaultValue: "",
            oldClrType: typeof(string),
            oldType: "character varying(100)",
            oldMaxLength: 100,
            oldNullable: true);
    }
}
