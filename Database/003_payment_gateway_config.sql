-- ============================================================================
-- Payment Gateway Configuration Tables
-- Multi-tenant payment gateway support for FloraEdge
-- ============================================================================

-- Payment Gateway Type Enum (stored as int)
-- 1-9: India (Razorpay=1, PayU=2, Cashfree=3)
-- 10-19: USA (Stripe=10, Square=11, PayPal=12)
-- 20-29: GCC (PayTabs=20, HyperPay=21, TapPayments=22, CheckoutCom=23)

-- Gateway Environment Enum: Sandbox=0, Production=1

-- Payment Transaction Status Enum:
-- Pending=0, Processing=1, Authorized=2, Captured=3, Completed=4
-- Failed=5, Cancelled=6, Refunded=7, PartiallyRefunded=8, Disputed=9

-- Payment Method Type Enum:
-- Card=1, UPI=2, NetBanking=3, Wallet=4, BankTransfer=5
-- Cash=6, Check=7, GiftCard=8, StoreCredit=9, PayLater=10

-- ============================================================================
-- PaymentGatewayConfigs - Tenant payment gateway settings
-- ============================================================================
CREATE TABLE IF NOT EXISTS "PaymentGatewayConfigs" (
    "Id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId" UUID NOT NULL REFERENCES "Companies"("Id") ON DELETE CASCADE,
    "GatewayType" INTEGER NOT NULL,
    "Name" VARCHAR(100) NOT NULL,
    "PublicKey" VARCHAR(500) NOT NULL,
    "SecretKeyEncrypted" VARCHAR(1000) NOT NULL,
    "WebhookSecretEncrypted" VARCHAR(500),
    "MerchantId" VARCHAR(200),
    "Environment" INTEGER NOT NULL DEFAULT 0,
    "Currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "SupportedCurrencies" VARCHAR(100),
    "IsActive" BOOLEAN NOT NULL DEFAULT TRUE,
    "IsDefault" BOOLEAN NOT NULL DEFAULT FALSE,
    "AdditionalConfig" JSONB,
    "WebhookUrl" VARCHAR(500),
    "LastTestedAt" TIMESTAMP WITH TIME ZONE,
    "LastTestSuccessful" BOOLEAN,
    "CreatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "UpdatedAt" TIMESTAMP WITH TIME ZONE,
    
    -- Only one config per gateway type per company
    CONSTRAINT "UQ_PaymentGatewayConfigs_Company_Type" UNIQUE ("CompanyId", "GatewayType")
);

-- Indexes for PaymentGatewayConfigs
CREATE INDEX IF NOT EXISTS "IX_PaymentGatewayConfigs_CompanyId" ON "PaymentGatewayConfigs"("CompanyId");
CREATE INDEX IF NOT EXISTS "IX_PaymentGatewayConfigs_CompanyId_IsDefault" ON "PaymentGatewayConfigs"("CompanyId", "IsDefault") WHERE "IsDefault" = TRUE;

COMMENT ON TABLE "PaymentGatewayConfigs" IS 'Tenant-specific payment gateway configurations';
COMMENT ON COLUMN "PaymentGatewayConfigs"."GatewayType" IS 'Payment gateway type: Razorpay=1, PayU=2, Cashfree=3, Stripe=10, Square=11, PayPal=12, PayTabs=20, HyperPay=21, TapPayments=22, CheckoutCom=23';
COMMENT ON COLUMN "PaymentGatewayConfigs"."SecretKeyEncrypted" IS 'Encrypted secret key - never expose';
COMMENT ON COLUMN "PaymentGatewayConfigs"."Environment" IS '0=Sandbox, 1=Production';

-- ============================================================================
-- PaymentTransactions - Payment transaction records
-- ============================================================================
CREATE TABLE IF NOT EXISTS "PaymentTransactions" (
    "Id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CompanyId" UUID NOT NULL REFERENCES "Companies"("Id") ON DELETE CASCADE,
    "PaymentGatewayConfigId" UUID NOT NULL REFERENCES "PaymentGatewayConfigs"("Id"),
    "OrderId" UUID REFERENCES "Orders"("Id"),
    "TransactionRef" VARCHAR(50) NOT NULL UNIQUE,
    "GatewayPaymentId" VARCHAR(200),
    "GatewayOrderId" VARCHAR(200),
    "Amount" DECIMAL(18,2) NOT NULL,
    "Currency" VARCHAR(3) NOT NULL DEFAULT 'USD',
    "Status" INTEGER NOT NULL DEFAULT 0,
    "PaymentMethod" INTEGER,
    "CardLast4" VARCHAR(4),
    "CardBrand" VARCHAR(20),
    "BankName" VARCHAR(100),
    "UpiId" VARCHAR(100),
    "WalletName" VARCHAR(50),
    "CustomerEmail" VARCHAR(200),
    "CustomerPhone" VARCHAR(20),
    "FailureReason" VARCHAR(500),
    "ErrorCode" VARCHAR(50),
    "RefundedAmount" DECIMAL(18,2) NOT NULL DEFAULT 0,
    "GatewayResponse" JSONB,
    "GatewayFee" DECIMAL(18,4),
    "NetAmount" DECIMAL(18,2),
    "AuthorizedAt" TIMESTAMP WITH TIME ZONE,
    "CapturedAt" TIMESTAMP WITH TIME ZONE,
    "CompletedAt" TIMESTAMP WITH TIME ZONE,
    "FailedAt" TIMESTAMP WITH TIME ZONE,
    "Metadata" JSONB,
    "CreatedAt" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    "UpdatedAt" TIMESTAMP WITH TIME ZONE
);

-- Indexes for PaymentTransactions
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_CompanyId" ON "PaymentTransactions"("CompanyId");
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_OrderId" ON "PaymentTransactions"("OrderId");
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_TransactionRef" ON "PaymentTransactions"("TransactionRef");
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_GatewayPaymentId" ON "PaymentTransactions"("CompanyId", "GatewayPaymentId");
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_Status" ON "PaymentTransactions"("CompanyId", "Status");
CREATE INDEX IF NOT EXISTS "IX_PaymentTransactions_CreatedAt" ON "PaymentTransactions"("CompanyId", "CreatedAt" DESC);

COMMENT ON TABLE "PaymentTransactions" IS 'Payment transaction records';
COMMENT ON COLUMN "PaymentTransactions"."Status" IS 'Pending=0, Processing=1, Authorized=2, Captured=3, Completed=4, Failed=5, Cancelled=6, Refunded=7, PartiallyRefunded=8, Disputed=9';
COMMENT ON COLUMN "PaymentTransactions"."PaymentMethod" IS 'Card=1, UPI=2, NetBanking=3, Wallet=4, BankTransfer=5, Cash=6, Check=7, GiftCard=8, StoreCredit=9, PayLater=10';

-- ============================================================================
-- Sample Data (for testing)
-- ============================================================================
-- Note: Don't run this in production. This is for development testing only.
-- Uncomment below to insert test data:

-- INSERT INTO "PaymentGatewayConfigs" ("CompanyId", "GatewayType", "Name", "PublicKey", "SecretKeyEncrypted", "Environment", "Currency", "IsDefault")
-- SELECT 
--     c."Id",
--     10, -- Stripe
--     'Test Stripe Account',
--     'pk_test_xxxx',
--     'c2tfdGVzdF94eHh4', -- base64 encoded 'sk_test_xxxx'
--     0, -- Sandbox
--     'USD',
--     TRUE
-- FROM "Companies" c
-- LIMIT 1;

-- ============================================================================
-- Migration helper: Check existing payments table
-- ============================================================================
-- If you have an existing Payments table, you may want to migrate data
-- Run this query to check: SELECT * FROM information_schema.tables WHERE table_name = 'Payments';
