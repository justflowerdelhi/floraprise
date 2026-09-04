-- Cloud Barcode Foundation
-- Persisted Manufacturer + Internal barcodes per Product, company-scoped.
-- Mirrors Sumpooj.Domain.Entities.Barcode / Sumpooj.Infrastructure.Migrations.AddBarcodesTable.
--
-- Existing "Products"."Barcode" values are migrated below as Manufacturer
-- barcodes (that is what they have always represented - see
-- BarcodeService.SearchAsync's historical ExternalBarcode mapping). The
-- legacy "Products"."Barcode" column itself is left untouched for backward
-- compatibility; it is not read from once the Barcodes table is populated.

CREATE TABLE IF NOT EXISTS "Barcodes" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "CompanyId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Type" integer NOT NULL,
    "Value" text NOT NULL,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    CONSTRAINT "PK_Barcodes" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Barcodes_Products_ProductId" FOREIGN KEY ("ProductId") REFERENCES "Products" ("Id") ON DELETE CASCADE
);

-- A barcode Value is unique within a company (Company A + "ABC123" and
-- Company B + "ABC123" may coexist; the same company cannot have it twice).
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Barcodes_CompanyId_Value" ON "Barcodes" ("CompanyId", "Value");

-- At most one barcode per (Product, Type): a product cannot have two
-- Manufacturer barcodes or two Internal barcodes at once.
-- BarcodeType enum: 0 = Manufacturer, 1 = Internal (Sumpooj.Domain.Entities.BarcodeType).
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Barcodes_ProductId_Type" ON "Barcodes" ("ProductId", "Type");

-- Data migration: existing non-empty Product.Barcode values become
-- Manufacturer barcode records. Duplicates (two products sharing the same
-- legacy Barcode value within a company) are skipped for the second and
-- later occurrences rather than violating the new unique constraint;
-- affected products keep their legacy "Products"."Barcode" value but will
-- not have a row in "Barcodes" until reconciled manually.
INSERT INTO "Barcodes" ("Id", "CompanyId", "ProductId", "Type", "Value", "CreatedAtUtc")
SELECT uuid_generate_v4(), p."CompanyId", p."Id", 0, TRIM(p."Barcode"), CURRENT_TIMESTAMP
FROM "Products" p
WHERE p."Barcode" IS NOT NULL AND TRIM(p."Barcode") <> ''
ON CONFLICT DO NOTHING;
