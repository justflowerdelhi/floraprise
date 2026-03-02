-- =====================================================
-- SUMPOOJ FLORIST ERP - Migration Script 012
-- Add RefreshTokens table for JWT refresh token support
-- =====================================================

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'RefreshTokens'
    ) THEN
        CREATE TABLE "RefreshTokens" (
            "Id" UUID NOT NULL DEFAULT uuid_generate_v4(),
            "UserId" UUID NOT NULL,
            "Token" VARCHAR(256) NOT NULL,
            "ExpiresAtUtc" TIMESTAMPTZ NOT NULL,
            "CreatedAtUtc" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            "RevokedAtUtc" TIMESTAMPTZ NULL,
            "IsRevoked" BOOLEAN NOT NULL DEFAULT FALSE,
            "ReplacedByToken" VARCHAR(256) NULL,
            CONSTRAINT "PK_RefreshTokens" PRIMARY KEY ("Id"),
            CONSTRAINT "FK_RefreshTokens_AspNetUsers" FOREIGN KEY ("UserId") REFERENCES "AspNetUsers" ("Id") ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX "IX_RefreshTokens_Token" ON "RefreshTokens" ("Token");
        CREATE INDEX "IX_RefreshTokens_UserId" ON "RefreshTokens" ("UserId");

        RAISE NOTICE 'RefreshTokens table created successfully.';
    END IF;

    RAISE NOTICE 'Migration 012 completed.';
END $$;
