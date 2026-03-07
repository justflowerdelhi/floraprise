-- =====================================================
-- Migration 015: Accounting Module + Staff Attendance
-- =====================================================

-- 1. Chart of Accounts
CREATE TABLE IF NOT EXISTS "Accounts" (
    "Id"            UUID            NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"     UUID            NOT NULL,
    "Code"          VARCHAR(50)     NOT NULL,
    "Name"          VARCHAR(200)    NOT NULL,
    "Type"          VARCHAR(50)     NOT NULL,
    "IsActive"      BOOLEAN         NOT NULL DEFAULT TRUE,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ     NULL,
    CONSTRAINT "PK_Accounts" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Accounts_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_Accounts_CompanyId" ON "Accounts" ("CompanyId");

-- 2. Expenses
CREATE TABLE IF NOT EXISTS "Expenses" (
    "Id"            UUID            NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"     UUID            NOT NULL,
    "Category"      VARCHAR(200)    NOT NULL,
    "Amount"        DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "Description"   TEXT            NULL,
    "ExpenseDate"   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "IsActive"      BOOLEAN         NOT NULL DEFAULT TRUE,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ     NULL,
    CONSTRAINT "PK_Expenses" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_Expenses_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_Expenses_CompanyId" ON "Expenses" ("CompanyId");
CREATE INDEX IF NOT EXISTS "IX_Expenses_ExpenseDate" ON "Expenses" ("ExpenseDate" DESC);

-- 3. Journal Entries
CREATE TABLE IF NOT EXISTS "JournalEntries" (
    "Id"             UUID            NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"      UUID            NOT NULL,
    "EntryDate"      TIMESTAMPTZ     NOT NULL,
    "Reference"      VARCHAR(200)    NOT NULL,
    "ReferenceType"  VARCHAR(50)     NOT NULL,
    "Description"    TEXT            NOT NULL,
    "Debit"          DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "Credit"         DECIMAL(18,2)   NOT NULL DEFAULT 0,
    "AccountId"      UUID            NULL,
    "CreatedAtUtc"   TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"   TIMESTAMPTZ     NULL,
    CONSTRAINT "PK_JournalEntries" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_JournalEntries_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_JournalEntries_Accounts" FOREIGN KEY ("AccountId") REFERENCES "Accounts" ("Id") ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "IX_JournalEntries_CompanyId" ON "JournalEntries" ("CompanyId");
CREATE INDEX IF NOT EXISTS "IX_JournalEntries_EntryDate" ON "JournalEntries" ("EntryDate" DESC);

-- 4. Staff Attendance Records
CREATE TABLE IF NOT EXISTS "StaffAttendanceRecords" (
    "Id"            UUID            NOT NULL DEFAULT gen_random_uuid(),
    "CompanyId"     UUID            NOT NULL,
    "StaffId"       UUID            NOT NULL,
    "CheckInUtc"    TIMESTAMPTZ     NOT NULL,
    "CheckOutUtc"   TIMESTAMPTZ     NULL,
    "Status"        INTEGER         NOT NULL DEFAULT 0,
    "CreatedAtUtc"  TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    "UpdatedAtUtc"  TIMESTAMPTZ     NULL,
    CONSTRAINT "PK_StaffAttendanceRecords" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_StaffAttendance_Companies" FOREIGN KEY ("CompanyId") REFERENCES "Companies" ("Id") ON DELETE CASCADE,
    CONSTRAINT "FK_StaffAttendance_Staff" FOREIGN KEY ("StaffId") REFERENCES "Staff" ("Id") ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS "IX_StaffAttendance_CompanyId_Date" ON "StaffAttendanceRecords" ("CompanyId", "CheckInUtc" DESC);
CREATE INDEX IF NOT EXISTS "IX_StaffAttendance_StaffId" ON "StaffAttendanceRecords" ("StaffId");
