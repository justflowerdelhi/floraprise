START TRANSACTION;
ALTER TABLE "Orders" ADD "AssignedDesignerStaffId" uuid;

CREATE INDEX "IX_Orders_AssignedDesignerStaffId" ON "Orders" ("AssignedDesignerStaffId");

ALTER TABLE "Orders" ADD CONSTRAINT "FK_Orders_AssignedDesignerStaff" FOREIGN KEY ("AssignedDesignerStaffId") REFERENCES "Staff" ("Id") ON DELETE SET NULL;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260907170306_AddOrderDesignerStaffAssignment', '10.0.10');

COMMIT;

START TRANSACTION;
CREATE TABLE "IdempotencyRecords" (
    "Id" uuid NOT NULL,
    "CompanyId" uuid NOT NULL,
    "IdempotencyKey" character varying(128) NOT NULL,
    "RequestPath" character varying(256) NOT NULL,
    "RequestHash" character varying(64) NOT NULL,
    "ResponseStatusCode" integer NOT NULL,
    "ResponsePayload" text NOT NULL,
    "OrderId" uuid,
    "ExpiresAt" timestamp with time zone,
    "CreatedAt" timestamp with time zone NOT NULL,
    "UpdatedAtUtc" timestamp with time zone,
    CONSTRAINT "PK_IdempotencyRecords" PRIMARY KEY ("Id")
);

CREATE UNIQUE INDEX "IX_IdempotencyRecords_CompanyId_IdempotencyKey" ON "IdempotencyRecords" ("CompanyId", "IdempotencyKey");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260911173823_AddIdempotencyRecords', '10.0.10');

COMMIT;

