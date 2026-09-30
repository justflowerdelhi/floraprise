-- Migration: Add PhoneNumber to DemoRequests table
-- Date: 2026-09-26

ALTER TABLE "DemoRequests"
ADD COLUMN IF NOT EXISTS "PhoneNumber" text;
