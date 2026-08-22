-- WhatsApp Account Foundation
-- Maps WhatsApp Business API accounts to members (florists)

CREATE TABLE IF NOT EXISTS "WhatsAppAccounts" (
    "Id" uuid NOT NULL DEFAULT uuid_generate_v4(),
    "MemberId" integer NOT NULL,
    "BusinessName" character varying(160) NOT NULL,
    "PhoneNumber" character varying(32) NOT NULL,
    "PhoneNumberId" character varying(100) NOT NULL,
    "WabaId" character varying(100) NOT NULL,
    "AccessToken" character varying(500) NOT NULL,
    "VerifyToken" character varying(100) NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAtUtc" timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UpdatedAtUtc" timestamptz,
    CONSTRAINT "PK_WhatsAppAccounts" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_WhatsAppAccounts_Members_MemberId" FOREIGN KEY ("MemberId") REFERENCES "members" ("id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_WhatsAppAccounts_MemberId" ON "WhatsAppAccounts" ("MemberId");
CREATE UNIQUE INDEX IF NOT EXISTS "IX_WhatsAppAccounts_PhoneNumberId" ON "WhatsAppAccounts" ("PhoneNumberId");
