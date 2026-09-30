using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddLibraryFestivalAndWeddingDates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "LibraryFestivals",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    FestivalDate = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    Month = table.Column<int>(type: "integer", nullable: false),
                    Day = table.Column<int>(type: "integer", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    IsRecurring = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    FlowerDemands = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SearchKeywords = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryFestivals", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "LibraryWeddingDates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    WeddingDate = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    Tithi = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Nakshatra = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Notes = table.Column<string>(type: "text", nullable: true),
                    Season = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    DemandLevel = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false, defaultValue: "High"),
                    SearchKeywords = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryWeddingDates", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_Slug",
                table: "LibraryFestivals",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_FestivalDate",
                table: "LibraryFestivals",
                column: "FestivalDate");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_Month",
                table: "LibraryFestivals",
                column: "Month");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_IsActive",
                table: "LibraryFestivals",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_SortOrder",
                table: "LibraryFestivals",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryFestivals_UpdatedAtUtc",
                table: "LibraryFestivals",
                column: "UpdatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_Slug",
                table: "LibraryWeddingDates",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_WeddingDate",
                table: "LibraryWeddingDates",
                column: "WeddingDate");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_DemandLevel",
                table: "LibraryWeddingDates",
                column: "DemandLevel");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_Season",
                table: "LibraryWeddingDates",
                column: "Season");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_IsActive",
                table: "LibraryWeddingDates",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_SortOrder",
                table: "LibraryWeddingDates",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryWeddingDates_UpdatedAtUtc",
                table: "LibraryWeddingDates",
                column: "UpdatedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LibraryFestivals");

            migrationBuilder.DropTable(
                name: "LibraryWeddingDates");
        }
    }
}
