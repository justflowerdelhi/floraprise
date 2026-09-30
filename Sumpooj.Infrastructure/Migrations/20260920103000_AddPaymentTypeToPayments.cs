using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Sumpooj.Infrastructure.Persistence;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    [DbContext(typeof(SumpoojDbContext))]
    [Migration("20260920103000_AddPaymentTypeToPayments")]
    public partial class AddPaymentTypeToPayments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PaymentType",
                table: "Payments",
                type: "character varying(32)",
                maxLength: 32,
                nullable: false,
                defaultValue: "SaleTender");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PaymentType",
                table: "Payments");
        }
    }
}
