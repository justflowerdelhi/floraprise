-- =====================================================
-- SUMPOOJ FLORIST ERP - Add Multi-Unit Columns
-- Migration Script - Add IsMultiUnit & AvgUnitsPerStem to Products
-- =====================================================

-- Add IsMultiUnit column to Products table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'Products' AND column_name = 'IsMultiUnit'
    ) THEN
        ALTER TABLE "Products" ADD COLUMN "IsMultiUnit" BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
END $$;

-- Add AvgUnitsPerStem column to Products table (if not exists)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'Products' AND column_name = 'AvgUnitsPerStem'
    ) THEN
        ALTER TABLE "Products" ADD COLUMN "AvgUnitsPerStem" INTEGER NOT NULL DEFAULT 1;
    END IF;
END $$;

-- =====================================================
-- COMPLETION
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Multi-unit columns added to Products table successfully!';
END $$;
