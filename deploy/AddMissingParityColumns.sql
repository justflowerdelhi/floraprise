-- Idempotent migration to add missing parity columns to DayCloses and FinishedGoodsBatches

-- DayCloses: CashExpenses
ALTER TABLE "DayCloses"
ADD COLUMN IF NOT EXISTS "CashExpenses" numeric NOT NULL DEFAULT 0;

-- FinishedGoodsBatches: OperatorName, ReversedAt, ReversalNote
ALTER TABLE "FinishedGoodsBatches"
ADD COLUMN IF NOT EXISTS "OperatorName" text;

ALTER TABLE "FinishedGoodsBatches"
ADD COLUMN IF NOT EXISTS "ReversedAt" timestamp with time zone;

ALTER TABLE "FinishedGoodsBatches"
ADD COLUMN IF NOT EXISTS "ReversalNote" text;
