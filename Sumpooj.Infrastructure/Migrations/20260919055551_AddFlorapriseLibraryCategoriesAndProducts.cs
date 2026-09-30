using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFlorapriseLibraryCategoriesAndProducts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SourceLibraryProductId",
                table: "Products",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "LibraryCategories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    IconKey = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ParentCategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryCategories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryCategories_LibraryCategories_ParentCategoryId",
                        column: x => x.ParentCategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LibraryProducts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProductType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    StandardUnit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    StandardSku = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Description = table.Column<string>(type: "text", nullable: true),
                    ReferenceImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ThumbnailUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SearchKeywords = table.Column<string>(type: "text", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryProducts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryProducts_LibraryCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Products_SourceLibraryProductId",
                table: "Products",
                column: "SourceLibraryProductId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCategories_IsActive",
                table: "LibraryCategories",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCategories_ParentCategoryId",
                table: "LibraryCategories",
                column: "ParentCategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCategories_Slug",
                table: "LibraryCategories",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCategories_SortOrder",
                table: "LibraryCategories",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryProducts_CategoryId",
                table: "LibraryProducts",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryProducts_IsActive",
                table: "LibraryProducts",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryProducts_Slug",
                table: "LibraryProducts",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryProducts_SortOrder",
                table: "LibraryProducts",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryProducts_UpdatedAtUtc",
                table: "LibraryProducts",
                column: "UpdatedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LibraryProducts");

            migrationBuilder.DropTable(
                name: "LibraryCategories");

            migrationBuilder.DropIndex(
                name: "IX_Products_SourceLibraryProductId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "SourceLibraryProductId",
                table: "Products");
        }
    }
}
