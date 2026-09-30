START TRANSACTION;
CREATE TABLE "LibraryFestivals" (
    "Id" uuid NOT NULL,
    "Name" character varying(200) NOT NULL,
    "Slug" character varying(200) NOT NULL,
    "FestivalDate" timestamptz NOT NULL,
    "Month" integer NOT NULL,
    "Day" integer NOT NULL,
    "Description" text,
    "IsRecurring" boolean NOT NULL DEFAULT TRUE,
    "FlowerDemands" character varying(500),
    "SearchKeywords" character varying(1000),
    "ImageUrl" character varying(1000),
    "SortOrder" integer NOT NULL DEFAULT 0,
    "IsActive" boolean NOT NULL DEFAULT TRUE,
    "Version" integer NOT NULL DEFAULT 1,
    "CreatedAtUtc" timestamptz NOT NULL,
    "UpdatedAtUtc" timestamptz,
    CONSTRAINT "PK_LibraryFestivals" PRIMARY KEY ("Id")
);

CREATE TABLE "LibraryWeddingDates" (
    "Id" uuid NOT NULL,
    "Title" character varying(200) NOT NULL,
    "Slug" character varying(200) NOT NULL,
    "WeddingDate" timestamptz NOT NULL,
    "Tithi" character varying(200),
    "Nakshatra" character varying(200),
    "Notes" text,
    "Season" character varying(100),
    "DemandLevel" character varying(50) NOT NULL DEFAULT 'High',
    "SearchKeywords" character varying(1000),
    "SortOrder" integer NOT NULL DEFAULT 0,
    "IsActive" boolean NOT NULL DEFAULT TRUE,
    "Version" integer NOT NULL DEFAULT 1,
    "CreatedAtUtc" timestamptz NOT NULL,
    "UpdatedAtUtc" timestamptz,
    CONSTRAINT "PK_LibraryWeddingDates" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX "IX_LibraryFestivals_Slug" ON "LibraryFestivals" ("Slug");

CREATE INDEX "IX_LibraryFestivals_FestivalDate" ON "LibraryFestivals" ("FestivalDate");

CREATE INDEX "IX_LibraryFestivals_Month" ON "LibraryFestivals" ("Month");

CREATE INDEX "IX_LibraryFestivals_IsActive" ON "LibraryFestivals" ("IsActive");

CREATE INDEX "IX_LibraryFestivals_SortOrder" ON "LibraryFestivals" ("SortOrder");

CREATE INDEX "IX_LibraryFestivals_UpdatedAtUtc" ON "LibraryFestivals" ("UpdatedAtUtc");

CREATE UNIQUE INDEX "IX_LibraryWeddingDates_Slug" ON "LibraryWeddingDates" ("Slug");

CREATE INDEX "IX_LibraryWeddingDates_WeddingDate" ON "LibraryWeddingDates" ("WeddingDate");

CREATE INDEX "IX_LibraryWeddingDates_DemandLevel" ON "LibraryWeddingDates" ("DemandLevel");

CREATE INDEX "IX_LibraryWeddingDates_Season" ON "LibraryWeddingDates" ("Season");

CREATE INDEX "IX_LibraryWeddingDates_IsActive" ON "LibraryWeddingDates" ("IsActive");

CREATE INDEX "IX_LibraryWeddingDates_SortOrder" ON "LibraryWeddingDates" ("SortOrder");

CREATE INDEX "IX_LibraryWeddingDates_UpdatedAtUtc" ON "LibraryWeddingDates" ("UpdatedAtUtc");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260920162000_AddLibraryFestivalAndWeddingDates', '10.0.10');

COMMIT;

