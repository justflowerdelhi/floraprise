-- =====================================================
-- SUMPOOJ FLORIST ERP - Add Multi-Unit Batch Columns
-- Migration Script - Add StemsInStock, UsedUnits,
-- DamagedUnits, ReservedUnits to ProductBatches
-- =====================================================

-- Add StemsInStock column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ProductBatches' AND column_name = 'StemsInStock'
    ) THEN
        ALTER TABLE "ProductBatches" ADD COLUMN "StemsInStock" INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- Add UsedUnits column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ProductBatches' AND column_name = 'UsedUnits'
    ) THEN
        ALTER TABLE "ProductBatches" ADD COLUMN "UsedUnits" INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- Add DamagedUnits column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ProductBatches' AND column_name = 'DamagedUnits'
    ) THEN
        ALTER TABLE "ProductBatches" ADD COLUMN "DamagedUnits" INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- Add ReservedUnits column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ProductBatches' AND column_name = 'ReservedUnits'
    ) THEN
        ALTER TABLE "ProductBatches" ADD COLUMN "ReservedUnits" INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- =====================================================
-- COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Multi-unit batch columns (StemsInStock, UsedUnits, DamagedUnits, ReservedUnits) added to ProductBatches table successfully!';
END $$;
