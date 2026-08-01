-- Reset mobile-module data and seed deterministic sample rows for UI testing.
-- WARNING: This removes existing mobile test/live rows from mobile tables.

DO $$
DECLARE
    v_company_id uuid;
    v_trial_plan_id uuid;
BEGIN
    SELECT c."Id"
    INTO v_company_id
    FROM "Companies" c
    ORDER BY c."Id"
    LIMIT 1;

    IF v_company_id IS NULL THEN
        RAISE EXCEPTION 'No company exists in Companies table. Create a company first.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM "SubscriptionPlans" WHERE "Code" = 'MOBILE_TRIAL') THEN
        INSERT INTO "SubscriptionPlans"
        (
            "Id", "Code", "Name", "PlanType", "MonthlyPrice", "AnnualPrice", "LifetimePrice", "TrialDays",
            "OfflineDays", "GraceDays", "MaximumDevices", "MaximumStaff", "IncludedModulesJson", "IsActive",
            "IsDeleted", "CreatedAtUtc", "RowVersion"
        )
        VALUES
        (
            uuid_generate_v4(),
            'MOBILE_TRIAL',
            'Mobile Trial',
            'Basic',
            0,
            0,
            0,
            7,
            3,
            30,
            5,
            5,
            '[]',
            true,
            false,
            CURRENT_TIMESTAMP,
            E'\\x'
        );
    END IF;

    SELECT "Id"
    INTO v_trial_plan_id
    FROM "SubscriptionPlans"
    WHERE "Code" = 'MOBILE_TRIAL'
    LIMIT 1;

    -- Clear module data in FK-safe order.
    DELETE FROM "FeatureEntitlements";
    DELETE FROM "TrialHistory";
    DELETE FROM "MobilePaymentTransactions";
    DELETE FROM "DeviceSessions";
    DELETE FROM "MobileLicenses";
    DELETE FROM "MobileSubscriptions";
    DELETE FROM "MobileDevices";
    DELETE FROM "MobileUsers";
    DELETE FROM "MobileCustomers";

    -- Seed customers
    INSERT INTO "MobileCustomers"
    (
        "Id", "CompanyId", "BusinessName", "OwnerName", "Mobile", "Email", "City", "State", "Country",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    VALUES
    ('60000000-0000-0000-0000-000000000001'::uuid, v_company_id, 'Petal Basket Florals', 'Aarav Shah', '9000000001', 'aarav@petalb.com', 'Mumbai', 'Maharashtra', 'India', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '1 day', E'\\x'),
    ('60000000-0000-0000-0000-000000000002'::uuid, v_company_id, 'Rose Craft Studio', 'Meera Patel', '9000000002', 'meera@rosecraft.in', 'Pune', 'Maharashtra', 'India', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
    ('60000000-0000-0000-0000-000000000003'::uuid, v_company_id, 'Bloomlane Boutique', 'Rohan Verma', '9000000003', 'rohan@bloomlane.in', 'Bengaluru', 'Karnataka', 'India', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '1 day', E'\\x');

    -- Seed users
    INSERT INTO "MobileUsers"
    (
        "Id", "CompanyId", "MobileCustomerId", "FullName", "Mobile", "Email", "Status", "PreferredLanguage", "PreferredTheme",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    VALUES
    ('70000000-0000-0000-0000-000000000001'::uuid, v_company_id, '60000000-0000-0000-0000-000000000001'::uuid, 'Aarav Shah', '9000000001', 'aarav@petalb.com', 'Active', 'en-IN', 'system', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '1 day', E'\\x'),
    ('70000000-0000-0000-0000-000000000002'::uuid, v_company_id, '60000000-0000-0000-0000-000000000002'::uuid, 'Meera Patel', '9000000002', 'meera@rosecraft.in', 'Active', 'en-IN', 'system', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
    ('70000000-0000-0000-0000-000000000003'::uuid, v_company_id, '60000000-0000-0000-0000-000000000003'::uuid, 'Rohan Verma', '9000000003', 'rohan@bloomlane.in', 'Active', 'en-IN', 'system', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '1 day', E'\\x');

    -- Seed subscriptions (1 per user)
    INSERT INTO "MobileSubscriptions"
    (
        "Id", "CompanyId", "MobileUserId", "SubscriptionPlanId", "Status", "TrialStartUtc", "TrialEndUtc", "StartUtc", "EndUtc", "GraceEndUtc", "LastValidatedUtc", "AutoRenew",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    VALUES
    ('80000000-0000-0000-0000-000000000001'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, v_trial_plan_id, 'Trial', CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP + INTERVAL '22 days', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '2 hours', false, false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
    ('80000000-0000-0000-0000-000000000002'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, v_trial_plan_id, 'Trial', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP + INTERVAL '24 days', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '5 hours', false, false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '5 hours', E'\\x'),
    ('80000000-0000-0000-0000-000000000003'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, v_trial_plan_id, 'Trial', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP + INTERVAL '26 days', NULL, NULL, NULL, CURRENT_TIMESTAMP - INTERVAL '1 hours', false, false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '1 hours', E'\\x');

    -- Seed devices (legacy compatibility: some schemas still require
    -- "UserId" and/or "DeviceFingerprintHash" NOT NULL).
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'MobileDevices'
          AND column_name = 'UserId'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'MobileDevices'
              AND column_name = 'DeviceFingerprintHash'
        ) THEN
            INSERT INTO "MobileDevices"
            (
                "Id", "CompanyId", "UserId", "DeviceFingerprintHash", "MobileUserId", "DeviceId", "DeviceName", "Manufacturer", "Model", "Platform", "OsVersion", "AppVersion", "PushToken", "LastIpAddress", "LastLoginAtUtc", "LastHeartbeatAtUtc", "LastSyncAtUtc", "Status",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            VALUES
            ('90000000-0000-0000-0000-000000000001'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, 'FP-DEV-A1', '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A1', 'Galaxy A34', 'Samsung', 'Galaxy A34', 'android', '14', '1.0.0', 'push_a1', '122.176.11.10', CURRENT_TIMESTAMP - INTERVAL '1 hours', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '10 minutes', E'\\x'),
            ('90000000-0000-0000-0000-000000000002'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, 'FP-DEV-A2', '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A2', 'Redmi Note 12', 'Xiaomi', 'Redmi Note 12', 'android', '13', '1.0.0', 'push_a2', '122.176.11.11', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
            ('90000000-0000-0000-0000-000000000003'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, 'FP-DEV-M1', '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M1', 'Nord 3', 'OnePlus', 'Nord 3', 'android', '14', '1.1.0', 'push_m1', '49.207.44.20', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000004'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, 'FP-DEV-R1', '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R1', 'V29', 'Vivo', 'V29', 'android', '13', '1.1.0', 'push_r1', '117.195.80.30', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '6 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000005'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, 'FP-DEV-R2', '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R2', 'Pixel 7a', 'Google', 'Pixel 7a', 'android', '14', '1.1.1', 'push_r2', '117.195.80.31', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', CURRENT_TIMESTAMP - INTERVAL '26 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000006'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, 'FP-DEV-M2', '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M2', 'M34', 'Samsung', 'M34', 'android', '14', '1.0.5', 'push_m2', '49.207.44.21', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '20 hours', CURRENT_TIMESTAMP - INTERVAL '20 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '20 hours', E'\\x');
        ELSE
            INSERT INTO "MobileDevices"
            (
                "Id", "CompanyId", "UserId", "MobileUserId", "DeviceId", "Manufacturer", "Model", "Platform", "OsVersion", "AppVersion", "PushToken", "LastIpAddress", "LastLoginAtUtc", "LastHeartbeatAtUtc", "LastSyncAtUtc", "Status",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            VALUES
            ('90000000-0000-0000-0000-000000000001'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A1', 'Samsung', 'Galaxy A34', 'android', '14', '1.0.0', 'push_a1', '122.176.11.10', CURRENT_TIMESTAMP - INTERVAL '1 hours', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '10 minutes', E'\\x'),
            ('90000000-0000-0000-0000-000000000002'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A2', 'Xiaomi', 'Redmi Note 12', 'android', '13', '1.0.0', 'push_a2', '122.176.11.11', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
            ('90000000-0000-0000-0000-000000000003'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M1', 'OnePlus', 'Nord 3', 'android', '14', '1.1.0', 'push_m1', '49.207.44.20', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000004'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R1', 'Vivo', 'V29', 'android', '13', '1.1.0', 'push_r1', '117.195.80.30', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '6 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000005'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R2', 'Google', 'Pixel 7a', 'android', '14', '1.1.1', 'push_r2', '117.195.80.31', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', CURRENT_TIMESTAMP - INTERVAL '26 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000006'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M2', 'Samsung', 'M34', 'android', '14', '1.0.5', 'push_m2', '49.207.44.21', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '20 hours', CURRENT_TIMESTAMP - INTERVAL '20 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '20 hours', E'\\x');
        END IF;
    ELSE
        IF EXISTS (
            SELECT 1
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'MobileDevices'
              AND column_name = 'DeviceFingerprintHash'
        ) THEN
            INSERT INTO "MobileDevices"
            (
                "Id", "CompanyId", "DeviceFingerprintHash", "MobileUserId", "DeviceId", "Manufacturer", "Model", "Platform", "OsVersion", "AppVersion", "PushToken", "LastIpAddress", "LastLoginAtUtc", "LastHeartbeatAtUtc", "LastSyncAtUtc", "Status",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            VALUES
            ('90000000-0000-0000-0000-000000000001'::uuid, v_company_id, 'FP-DEV-A1', '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A1', 'Samsung', 'Galaxy A34', 'android', '14', '1.0.0', 'push_a1', '122.176.11.10', CURRENT_TIMESTAMP - INTERVAL '1 hours', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '10 minutes', E'\\x'),
            ('90000000-0000-0000-0000-000000000002'::uuid, v_company_id, 'FP-DEV-A2', '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A2', 'Xiaomi', 'Redmi Note 12', 'android', '13', '1.0.0', 'push_a2', '122.176.11.11', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
            ('90000000-0000-0000-0000-000000000003'::uuid, v_company_id, 'FP-DEV-M1', '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M1', 'OnePlus', 'Nord 3', 'android', '14', '1.1.0', 'push_m1', '49.207.44.20', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000004'::uuid, v_company_id, 'FP-DEV-R1', '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R1', 'Vivo', 'V29', 'android', '13', '1.1.0', 'push_r1', '117.195.80.30', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '6 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000005'::uuid, v_company_id, 'FP-DEV-R2', '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R2', 'Google', 'Pixel 7a', 'android', '14', '1.1.1', 'push_r2', '117.195.80.31', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', CURRENT_TIMESTAMP - INTERVAL '26 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000006'::uuid, v_company_id, 'FP-DEV-M2', '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M2', 'Samsung', 'M34', 'android', '14', '1.0.5', 'push_m2', '49.207.44.21', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '20 hours', CURRENT_TIMESTAMP - INTERVAL '20 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '20 hours', E'\\x');
        ELSE
            INSERT INTO "MobileDevices"
            (
                "Id", "CompanyId", "MobileUserId", "DeviceId", "Manufacturer", "Model", "Platform", "OsVersion", "AppVersion", "PushToken", "LastIpAddress", "LastLoginAtUtc", "LastHeartbeatAtUtc", "LastSyncAtUtc", "Status",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            VALUES
            ('90000000-0000-0000-0000-000000000001'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A1', 'Samsung', 'Galaxy A34', 'android', '14', '1.0.0', 'push_a1', '122.176.11.10', CURRENT_TIMESTAMP - INTERVAL '1 hours', CURRENT_TIMESTAMP - INTERVAL '10 minutes', CURRENT_TIMESTAMP - INTERVAL '15 minutes', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '10 minutes', E'\\x'),
            ('90000000-0000-0000-0000-000000000002'::uuid, v_company_id, '70000000-0000-0000-0000-000000000001'::uuid, 'DEV-A2', 'Xiaomi', 'Redmi Note 12', 'android', '13', '1.0.0', 'push_a2', '122.176.11.11', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '2 days', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
            ('90000000-0000-0000-0000-000000000003'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M1', 'OnePlus', 'Nord 3', 'android', '14', '1.1.0', 'push_m1', '49.207.44.20', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '2 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000004'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R1', 'Vivo', 'V29', 'android', '13', '1.1.0', 'push_r1', '117.195.80.30', CURRENT_TIMESTAMP - INTERVAL '12 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', CURRENT_TIMESTAMP - INTERVAL '6 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '6 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000005'::uuid, v_company_id, '70000000-0000-0000-0000-000000000003'::uuid, 'DEV-R2', 'Google', 'Pixel 7a', 'android', '14', '1.1.1', 'push_r2', '117.195.80.31', CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', CURRENT_TIMESTAMP - INTERVAL '26 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', E'\\x'),
            ('90000000-0000-0000-0000-000000000006'::uuid, v_company_id, '70000000-0000-0000-0000-000000000002'::uuid, 'DEV-M2', 'Samsung', 'M34', 'android', '14', '1.0.5', 'push_m2', '49.207.44.21', CURRENT_TIMESTAMP - INTERVAL '1 day', CURRENT_TIMESTAMP - INTERVAL '20 hours', CURRENT_TIMESTAMP - INTERVAL '20 hours', 'Active', false, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '20 hours', E'\\x');
        END IF;
    END IF;

    -- Seed one license per device.
    INSERT INTO "MobileLicenses"
    (
        "Id", "CompanyId", "MobileDeviceId", "MobileSubscriptionId", "Status", "IssuedAtUtc", "ExpiryUtc", "RevokedAtUtc",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    VALUES
    ('A0000000-0000-0000-0000-000000000001'::uuid, v_company_id, '90000000-0000-0000-0000-000000000001'::uuid, '80000000-0000-0000-0000-000000000001'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP + INTERVAL '22 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '8 days', CURRENT_TIMESTAMP - INTERVAL '2 hours', E'\\x'),
    ('A0000000-0000-0000-0000-000000000002'::uuid, v_company_id, '90000000-0000-0000-0000-000000000002'::uuid, '80000000-0000-0000-0000-000000000001'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP + INTERVAL '23 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '7 days', CURRENT_TIMESTAMP - INTERVAL '2 days', E'\\x'),
    ('A0000000-0000-0000-0000-000000000003'::uuid, v_company_id, '90000000-0000-0000-0000-000000000003'::uuid, '80000000-0000-0000-0000-000000000002'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP + INTERVAL '24 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '6 days', CURRENT_TIMESTAMP - INTERVAL '5 hours', E'\\x'),
    ('A0000000-0000-0000-0000-000000000004'::uuid, v_company_id, '90000000-0000-0000-0000-000000000004'::uuid, '80000000-0000-0000-0000-000000000003'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP + INTERVAL '26 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '4 days', CURRENT_TIMESTAMP - INTERVAL '6 hours', E'\\x'),
    ('A0000000-0000-0000-0000-000000000005'::uuid, v_company_id, '90000000-0000-0000-0000-000000000005'::uuid, '80000000-0000-0000-0000-000000000003'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP + INTERVAL '27 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '3 days', CURRENT_TIMESTAMP - INTERVAL '26 hours', E'\\x'),
    ('A0000000-0000-0000-0000-000000000006'::uuid, v_company_id, '90000000-0000-0000-0000-000000000006'::uuid, '80000000-0000-0000-0000-000000000002'::uuid, 'Active', CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP + INTERVAL '25 days', NULL, false, CURRENT_TIMESTAMP - INTERVAL '5 days', CURRENT_TIMESTAMP - INTERVAL '20 hours', E'\\x');

    RAISE NOTICE 'Seed complete for CompanyId=%', v_company_id;
END $$;

SELECT
  (SELECT COUNT(*) FROM "MobileCustomers" WHERE NOT "IsDeleted") AS mobile_customers,
  (SELECT COUNT(*) FROM "MobileUsers" WHERE NOT "IsDeleted") AS mobile_users,
  (SELECT COUNT(*) FROM "MobileDevices" WHERE NOT "IsDeleted") AS mobile_devices,
  (SELECT COUNT(*) FROM "MobileLicenses" WHERE NOT "IsDeleted") AS mobile_licenses;
