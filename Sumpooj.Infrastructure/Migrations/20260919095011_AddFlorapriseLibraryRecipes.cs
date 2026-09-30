using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFlorapriseLibraryRecipes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SourceLibraryRecipeId",
                table: "FloralRecipes",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "LibraryRecipes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    YieldQuantity = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false, defaultValue: 1m),
                    YieldUnit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Instructions = table.Column<string>(type: "text", nullable: true),
                    PreparationNotes = table.Column<string>(type: "text", nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryRecipes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryRecipes_LibraryCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LibraryRecipeItems",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RecipeId = table.Column<Guid>(type: "uuid", nullable: false),
                    LibraryProductId = table.Column<Guid>(type: "uuid", nullable: true),
                    ProductNameSnapshot = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric(18,4)", precision: 18, scale: 4, nullable: false),
                    Unit = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    Notes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryRecipeItems", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryRecipeItems_LibraryProducts_LibraryProductId",
                        column: x => x.LibraryProductId,
                        principalTable: "LibraryProducts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_LibraryRecipeItems_LibraryRecipes_RecipeId",
                        column: x => x.RecipeId,
                        principalTable: "LibraryRecipes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FloralRecipes_SourceLibraryRecipeId",
                table: "FloralRecipes",
                column: "SourceLibraryRecipeId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipeItems_LibraryProductId",
                table: "LibraryRecipeItems",
                column: "LibraryProductId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipeItems_RecipeId",
                table: "LibraryRecipeItems",
                column: "RecipeId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipes_CategoryId",
                table: "LibraryRecipes",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipes_IsActive",
                table: "LibraryRecipes",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipes_Slug",
                table: "LibraryRecipes",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipes_SortOrder",
                table: "LibraryRecipes",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryRecipes_UpdatedAtUtc",
                table: "LibraryRecipes",
                column: "UpdatedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LibraryRecipeItems");

            migrationBuilder.DropTable(
                name: "LibraryRecipes");

            migrationBuilder.DropIndex(
                name: "IX_FloralRecipes_SourceLibraryRecipeId",
                table: "FloralRecipes");

            migrationBuilder.DropColumn(
                name: "SourceLibraryRecipeId",
                table: "FloralRecipes");
        }
    }
}
