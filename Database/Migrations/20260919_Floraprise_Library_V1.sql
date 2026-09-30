START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    ALTER TABLE "Products" ADD "SourceLibraryProductId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE TABLE "LibraryCategories" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "ImageUrl" character varying(1000),
        "IconKey" character varying(100),
        "ParentCategoryId" uuid,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryCategories" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryCategories_LibraryCategories_ParentCategoryId" FOREIGN KEY ("ParentCategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE TABLE "LibraryProducts" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "CategoryId" uuid,
        "ProductType" character varying(50) NOT NULL,
        "StandardUnit" character varying(50) NOT NULL,
        "StandardSku" character varying(100),
        "Description" text,
        "ReferenceImageUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "SearchKeywords" text,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryProducts" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryProducts_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_Products_SourceLibraryProductId" ON "Products" ("SourceLibraryProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_IsActive" ON "LibraryCategories" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_ParentCategoryId" ON "LibraryCategories" ("ParentCategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE UNIQUE INDEX "IX_LibraryCategories_Slug" ON "LibraryCategories" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryCategories_SortOrder" ON "LibraryCategories" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_CategoryId" ON "LibraryProducts" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_IsActive" ON "LibraryProducts" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE UNIQUE INDEX "IX_LibraryProducts_Slug" ON "LibraryProducts" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_SortOrder" ON "LibraryProducts" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    CREATE INDEX "IX_LibraryProducts_UpdatedAtUtc" ON "LibraryProducts" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919055551_AddFlorapriseLibraryCategoriesAndProducts') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919055551_AddFlorapriseLibraryCategoriesAndProducts', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    ALTER TABLE "FloralRecipes" ADD "SourceLibraryRecipeId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE TABLE "LibraryRecipes" (
        "Id" uuid NOT NULL,
        "Name" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "YieldQuantity" numeric(18,4) NOT NULL DEFAULT 1.0,
        "YieldUnit" character varying(50),
        "Instructions" text,
        "PreparationNotes" text,
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryRecipes" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryRecipes_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE TABLE "LibraryRecipeItems" (
        "Id" uuid NOT NULL,
        "RecipeId" uuid NOT NULL,
        "LibraryProductId" uuid,
        "ProductNameSnapshot" character varying(200) NOT NULL,
        "Quantity" numeric(18,4) NOT NULL,
        "Unit" character varying(50) NOT NULL,
        "Notes" character varying(500),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryRecipeItems" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryRecipeItems_LibraryProducts_LibraryProductId" FOREIGN KEY ("LibraryProductId") REFERENCES "LibraryProducts" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_LibraryRecipeItems_LibraryRecipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES "LibraryRecipes" ("Id") ON DELETE CASCADE
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_FloralRecipes_SourceLibraryRecipeId" ON "FloralRecipes" ("SourceLibraryRecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipeItems_LibraryProductId" ON "LibraryRecipeItems" ("LibraryProductId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipeItems_RecipeId" ON "LibraryRecipeItems" ("RecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_CategoryId" ON "LibraryRecipes" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_IsActive" ON "LibraryRecipes" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE UNIQUE INDEX "IX_LibraryRecipes_Slug" ON "LibraryRecipes" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_SortOrder" ON "LibraryRecipes" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    CREATE INDEX "IX_LibraryRecipes_UpdatedAtUtc" ON "LibraryRecipes" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919095011_AddFlorapriseLibraryRecipes') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919095011_AddFlorapriseLibraryRecipes', '10.0.10');
    END IF;
END $EF$;
COMMIT;

START TRANSACTION;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    ALTER TABLE "CloudDesigns" ADD "SourceLibraryDesignId" uuid;
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryCardTemplates" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Content" text NOT NULL,
        "Occasion" character varying(100),
        "Tone" character varying(100),
        "Language" character varying(20) NOT NULL DEFAULT 'en',
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "SearchKeywords" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryCardTemplates" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryCardTemplates_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryDesigns" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Description" text,
        "CategoryId" uuid,
        "ImageUrl" character varying(1000),
        "HighResImageUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "Occasion" character varying(100),
        "Style" character varying(100),
        "ColorPalette" character varying(200),
        "FlowerTypes" character varying(500),
        "RecipeId" uuid,
        "SearchKeywords" character varying(1000),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryDesigns" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryDesigns_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT,
        CONSTRAINT "FK_LibraryDesigns_LibraryRecipes_RecipeId" FOREIGN KEY ("RecipeId") REFERENCES "LibraryRecipes" ("Id") ON DELETE SET NULL
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE TABLE "LibraryTutorials" (
        "Id" uuid NOT NULL,
        "Title" character varying(200) NOT NULL,
        "Slug" character varying(200) NOT NULL,
        "Summary" text,
        "ContentMarkdown" text NOT NULL,
        "CategoryId" uuid,
        "VideoUrl" character varying(1000),
        "ThumbnailUrl" character varying(1000),
        "DifficultyLevel" character varying(50) NOT NULL DEFAULT 'Beginner',
        "EstimatedReadingMinutes" integer DEFAULT 5,
        "Tags" character varying(500),
        "SortOrder" integer NOT NULL DEFAULT 0,
        "IsActive" boolean NOT NULL DEFAULT TRUE,
        "Version" integer NOT NULL DEFAULT 1,
        "CreatedAtUtc" timestamptz NOT NULL,
        "UpdatedAtUtc" timestamptz,
        CONSTRAINT "PK_LibraryTutorials" PRIMARY KEY ("Id"),
        CONSTRAINT "FK_LibraryTutorials_LibraryCategories_CategoryId" FOREIGN KEY ("CategoryId") REFERENCES "LibraryCategories" ("Id") ON DELETE RESTRICT
    );
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_CloudDesigns_SourceLibraryDesignId" ON "CloudDesigns" ("SourceLibraryDesignId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_CategoryId" ON "LibraryCardTemplates" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_IsActive" ON "LibraryCardTemplates" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Language" ON "LibraryCardTemplates" ("Language");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Occasion" ON "LibraryCardTemplates" ("Occasion");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryCardTemplates_Slug" ON "LibraryCardTemplates" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_SortOrder" ON "LibraryCardTemplates" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_Tone" ON "LibraryCardTemplates" ("Tone");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryCardTemplates_UpdatedAtUtc" ON "LibraryCardTemplates" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_CategoryId" ON "LibraryDesigns" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_IsActive" ON "LibraryDesigns" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_Occasion" ON "LibraryDesigns" ("Occasion");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_RecipeId" ON "LibraryDesigns" ("RecipeId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryDesigns_Slug" ON "LibraryDesigns" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_SortOrder" ON "LibraryDesigns" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_Style" ON "LibraryDesigns" ("Style");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryDesigns_UpdatedAtUtc" ON "LibraryDesigns" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_CategoryId" ON "LibraryTutorials" ("CategoryId");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_DifficultyLevel" ON "LibraryTutorials" ("DifficultyLevel");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_IsActive" ON "LibraryTutorials" ("IsActive");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE UNIQUE INDEX "IX_LibraryTutorials_Slug" ON "LibraryTutorials" ("Slug");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_SortOrder" ON "LibraryTutorials" ("SortOrder");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    CREATE INDEX "IX_LibraryTutorials_UpdatedAtUtc" ON "LibraryTutorials" ("UpdatedAtUtc");
    END IF;
END $EF$;

DO $EF$
BEGIN
    IF NOT EXISTS(SELECT 1 FROM "__EFMigrationsHistory" WHERE "MigrationId" = '20260919101107_AddFlorapriseLibraryAllModules') THEN
    INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
    VALUES ('20260919101107_AddFlorapriseLibraryAllModules', '10.0.10');
    END IF;
END $EF$;
COMMIT;

