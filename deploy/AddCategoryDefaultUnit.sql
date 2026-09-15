-- Idempotent migration to add DefaultUnit to ProductCategories table
ALTER TABLE "ProductCategories"
ADD COLUMN IF NOT EXISTS "DefaultUnit" character varying(50);
