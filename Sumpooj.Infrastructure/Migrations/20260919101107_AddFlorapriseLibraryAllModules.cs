using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sumpooj.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddFlorapriseLibraryAllModules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "SourceLibraryDesignId",
                table: "CloudDesigns",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "LibraryCardTemplates",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Content = table.Column<string>(type: "text", nullable: false),
                    Occasion = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Tone = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Language = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "en"),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SearchKeywords = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryCardTemplates", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryCardTemplates_LibraryCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "LibraryDesigns",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    ImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    HighResImageUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ThumbnailUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Occasion = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Style = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    ColorPalette = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    FlowerTypes = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    RecipeId = table.Column<Guid>(type: "uuid", nullable: true),
                    SearchKeywords = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryDesigns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryDesigns_LibraryCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_LibraryDesigns_LibraryRecipes_RecipeId",
                        column: x => x.RecipeId,
                        principalTable: "LibraryRecipes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "LibraryTutorials",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Summary = table.Column<string>(type: "text", nullable: true),
                    ContentMarkdown = table.Column<string>(type: "text", nullable: false),
                    CategoryId = table.Column<Guid>(type: "uuid", nullable: true),
                    VideoUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ThumbnailUrl = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    DifficultyLevel = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false, defaultValue: "Beginner"),
                    EstimatedReadingMinutes = table.Column<int>(type: "integer", nullable: true, defaultValue: 5),
                    Tags = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    SortOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    Version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    CreatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: false),
                    UpdatedAtUtc = table.Column<DateTime>(type: "timestamptz", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_LibraryTutorials", x => x.Id);
                    table.ForeignKey(
                        name: "FK_LibraryTutorials_LibraryCategories_CategoryId",
                        column: x => x.CategoryId,
                        principalTable: "LibraryCategories",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CloudDesigns_SourceLibraryDesignId",
                table: "CloudDesigns",
                column: "SourceLibraryDesignId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_CategoryId",
                table: "LibraryCardTemplates",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_IsActive",
                table: "LibraryCardTemplates",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_Language",
                table: "LibraryCardTemplates",
                column: "Language");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_Occasion",
                table: "LibraryCardTemplates",
                column: "Occasion");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_Slug",
                table: "LibraryCardTemplates",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_SortOrder",
                table: "LibraryCardTemplates",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_Tone",
                table: "LibraryCardTemplates",
                column: "Tone");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryCardTemplates_UpdatedAtUtc",
                table: "LibraryCardTemplates",
                column: "UpdatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_CategoryId",
                table: "LibraryDesigns",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_IsActive",
                table: "LibraryDesigns",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_Occasion",
                table: "LibraryDesigns",
                column: "Occasion");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_RecipeId",
                table: "LibraryDesigns",
                column: "RecipeId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_Slug",
                table: "LibraryDesigns",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_SortOrder",
                table: "LibraryDesigns",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_Style",
                table: "LibraryDesigns",
                column: "Style");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryDesigns_UpdatedAtUtc",
                table: "LibraryDesigns",
                column: "UpdatedAtUtc");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_CategoryId",
                table: "LibraryTutorials",
                column: "CategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_DifficultyLevel",
                table: "LibraryTutorials",
                column: "DifficultyLevel");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_IsActive",
                table: "LibraryTutorials",
                column: "IsActive");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_Slug",
                table: "LibraryTutorials",
                column: "Slug",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_SortOrder",
                table: "LibraryTutorials",
                column: "SortOrder");

            migrationBuilder.CreateIndex(
                name: "IX_LibraryTutorials_UpdatedAtUtc",
                table: "LibraryTutorials",
                column: "UpdatedAtUtc");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "LibraryCardTemplates");

            migrationBuilder.DropTable(
                name: "LibraryDesigns");

            migrationBuilder.DropTable(
                name: "LibraryTutorials");

            migrationBuilder.DropIndex(
                name: "IX_CloudDesigns_SourceLibraryDesignId",
                table: "CloudDesigns");

            migrationBuilder.DropColumn(
                name: "SourceLibraryDesignId",
                table: "CloudDesigns");
        }
    }
}
