-- Data migration path from legacy Floraprise.License.Api schema into unified ERP mobile tables.
-- Legacy tables expected: Customers, Devices, Licenses
-- This script is idempotent and safe to re-run.

DO $$
DECLARE
    v_customer_phone_col text;
    v_customers_schema text;
    v_customers_table text;
    v_devices_schema text;
    v_devices_table text;
    v_licenses_schema text;
    v_licenses_table text;
    v_has_devices_table boolean;
    v_has_licenses_table boolean;
    v_company_column_exists boolean;
    v_default_company_id uuid;
    v_company_count integer;
    v_effective_company_expr text;
    v_business_col text;
    v_owner_col text;
    v_email_col text;
    v_created_col text;
    v_updated_col text;
    v_business_expr text;
    v_owner_expr text;
    v_email_expr text;
    v_created_expr text;
    v_updated_expr text;
    v_rows integer;
    v_null_company_rows integer;
    v_legacy_license_rows bigint := 0;
BEGIN
        SELECT t.table_schema, t.table_name
        INTO v_customers_schema, v_customers_table
        FROM information_schema.tables t
        WHERE t.table_type = 'BASE TABLE'
            AND lower(t.table_name) = 'customers'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
        ORDER BY CASE WHEN t.table_schema = 'public' THEN 0 ELSE 1 END, t.table_schema, t.table_name
        LIMIT 1;

        IF v_customers_table IS NULL THEN
        RAISE NOTICE 'Legacy table Customers not found. Skipping legacy data migration.';
        RETURN;
    END IF;

        SELECT t.table_schema, t.table_name
        INTO v_devices_schema, v_devices_table
        FROM information_schema.tables t
        WHERE t.table_type = 'BASE TABLE'
            AND lower(t.table_name) = 'devices'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
        ORDER BY CASE WHEN t.table_schema = 'public' THEN 0 ELSE 1 END, t.table_schema, t.table_name
        LIMIT 1;

        v_has_devices_table := v_devices_table IS NOT NULL;
        IF NOT v_has_devices_table THEN
        RAISE NOTICE 'Legacy table Devices not found. Device-level legacy migration will be skipped.';
    END IF;

        SELECT t.table_schema, t.table_name
        INTO v_licenses_schema, v_licenses_table
        FROM information_schema.tables t
        WHERE t.table_type = 'BASE TABLE'
            AND lower(t.table_name) = 'licenses'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
        ORDER BY CASE WHEN t.table_schema = 'public' THEN 0 ELSE 1 END, t.table_schema, t.table_name
        LIMIT 1;

        v_has_licenses_table := v_licenses_table IS NOT NULL;
        IF NOT v_has_licenses_table THEN
        RAISE NOTICE 'Legacy table Licenses not found. Legacy license migration will be skipped.';
    END IF;

    -- Legacy customer phone column varies across deployments.
    SELECT c.column_name
    INTO v_customer_phone_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) IN ('phonenumber', 'mobile', 'phone')
    ORDER BY CASE lower(c.column_name)
        WHEN 'phonenumber' THEN 0
        WHEN 'mobile' THEN 1
        WHEN 'phone' THEN 2
        ELSE 9
    END
    LIMIT 1;

    IF v_customer_phone_col IS NULL THEN
        RAISE NOTICE 'No usable phone column found on legacy Customers table. Expected one of PhoneNumber/Mobile/Phone. Skipping migration.';
        RETURN;
    END IF;

    SELECT c.column_name
    INTO v_business_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) IN ('businessname', 'name', 'companyname')
    ORDER BY CASE lower(c.column_name)
        WHEN 'businessname' THEN 0
        WHEN 'name' THEN 1
        WHEN 'companyname' THEN 2
        ELSE 9
    END
    LIMIT 1;

    SELECT c.column_name
    INTO v_owner_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) IN ('ownername', 'contactname', 'name')
    ORDER BY CASE lower(c.column_name)
        WHEN 'ownername' THEN 0
        WHEN 'contactname' THEN 1
        WHEN 'name' THEN 2
        ELSE 9
    END
    LIMIT 1;

    SELECT c.column_name
    INTO v_email_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) = 'email'
    LIMIT 1;

    SELECT c.column_name
    INTO v_created_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) IN ('createdat', 'createdatutc')
    ORDER BY CASE lower(c.column_name)
        WHEN 'createdat' THEN 0
        WHEN 'createdatutc' THEN 1
        ELSE 9
    END
    LIMIT 1;

    SELECT c.column_name
    INTO v_updated_col
    FROM information_schema.columns c
    WHERE c.table_schema = v_customers_schema
      AND c.table_name = v_customers_table
      AND lower(c.column_name) IN ('updatedat', 'updatedatutc')
    ORDER BY CASE lower(c.column_name)
        WHEN 'updatedat' THEN 0
        WHEN 'updatedatutc' THEN 1
        ELSE 9
    END
    LIMIT 1;

    IF v_business_col IS NOT NULL THEN
        v_business_expr := format('COALESCE(NULLIF(TRIM(c.%I), ''''), ''Florist Business'')', v_business_col);
    ELSE
        v_business_expr := '''Florist Business''';
    END IF;

    IF v_owner_col IS NOT NULL THEN
        v_owner_expr := format('COALESCE(NULLIF(TRIM(c.%I), ''''), ''Owner'')', v_owner_col);
    ELSE
        v_owner_expr := '''Owner''';
    END IF;

    IF v_email_col IS NOT NULL THEN
        v_email_expr := format('NULLIF(TRIM(c.%I), '''')', v_email_col);
    ELSE
        v_email_expr := 'NULL';
    END IF;

    IF v_created_col IS NOT NULL THEN
        v_created_expr := format('COALESCE(c.%I, CURRENT_TIMESTAMP)', v_created_col);
    ELSE
        v_created_expr := 'CURRENT_TIMESTAMP';
    END IF;

    IF v_updated_col IS NOT NULL THEN
        v_updated_expr := format('c.%I', v_updated_col);
    ELSE
        v_updated_expr := 'NULL';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
                WHERE table_schema = v_customers_schema
                    AND table_name = v_customers_table
                    AND lower(column_name) = 'companyid'
    )
    INTO v_company_column_exists;

    SELECT COUNT(*) FROM "Companies" INTO v_company_count;
    IF v_company_count = 1 THEN
        SELECT "Id" INTO v_default_company_id FROM "Companies" LIMIT 1;
    END IF;

    IF v_company_column_exists THEN
        IF v_default_company_id IS NOT NULL THEN
            v_effective_company_expr := format('COALESCE(c."CompanyId", ''%s''::uuid)', v_default_company_id);
        ELSE
            v_effective_company_expr := 'c."CompanyId"';
        END IF;
    ELSE
        IF v_default_company_id IS NULL THEN
            RAISE NOTICE 'Legacy Customers.CompanyId column is missing and no single fallback company could be inferred. Skipping migration.';
            RETURN;
        END IF;

        v_effective_company_expr := format('''%s''::uuid', v_default_company_id);
    END IF;

    IF v_company_column_exists AND v_default_company_id IS NULL THEN
        EXECUTE format($fmt$
            SELECT COUNT(*)
                        FROM %2$I.%3$I c
            WHERE c."CompanyId" IS NULL
              AND c.%1$I IS NOT NULL
              AND TRIM(c.%1$I) <> ''
                $fmt$, v_customer_phone_col, v_customers_schema, v_customers_table)
        INTO v_null_company_rows;

        IF v_null_company_rows > 0 THEN
            RAISE NOTICE 'Found % legacy customers with NULL CompanyId and no single-company fallback. Those rows cannot be migrated automatically.', v_null_company_rows;
        END IF;
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
            2,
            2,
            '[]',
            true,
            false,
            CURRENT_TIMESTAMP,
            E'\\x'
        );
    END IF;

    EXECUTE format($fmt$
        INSERT INTO "MobileCustomers"
        (
            "Id", "CompanyId", "BusinessName", "OwnerName", "Mobile", "Email", "City", "State", "Country",
            "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
        )
        SELECT
            uuid_generate_v4(),
            %2$s,
            %5$s,
            %6$s,
            TRIM(c.%1$I),
            %7$s,
            NULL,
            NULL,
            NULL,
            false,
            %8$s,
            %9$s,
            E'\\x'
                                FROM (
                                        SELECT DISTINCT ON (%2$s, TRIM(c.%1$I))
                                                c.*
                                        FROM %3$I.%4$I c
                                        WHERE %2$s IS NOT NULL
                                            AND c.%1$I IS NOT NULL
                                            AND TRIM(c.%1$I) <> ''
                                        ORDER BY %2$s, TRIM(c.%1$I), c."Id"
                                ) c
                                LEFT JOIN "MobileCustomers" mc ON mc."CompanyId" = %2$s AND mc."Mobile" = TRIM(c.%1$I)
        WHERE mc."Id" IS NULL
                    AND %2$s IS NOT NULL
        $fmt$, v_customer_phone_col, v_effective_company_expr, v_customers_schema, v_customers_table, v_business_expr, v_owner_expr, v_email_expr, v_created_expr, v_updated_expr);
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        RAISE NOTICE '022 migrated MobileCustomers rows: %', v_rows;

    INSERT INTO "MobileUsers"
    (
        "Id", "CompanyId", "MobileCustomerId", "FullName", "Mobile", "Email", "Status", "PreferredLanguage", "PreferredTheme",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    SELECT
        uuid_generate_v4(),
        mc."CompanyId",
        mc."Id",
        mc."OwnerName",
        mc."Mobile",
        mc."Email",
        'Active',
        'en-IN',
        'system',
        false,
        COALESCE(mc."CreatedAtUtc", CURRENT_TIMESTAMP),
        mc."UpdatedAtUtc",
        E'\\x'
    FROM "MobileCustomers" mc
    LEFT JOIN "MobileUsers" mu ON mu."CompanyId" = mc."CompanyId" AND mu."Mobile" = mc."Mobile"
    WHERE mu."Id" IS NULL;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '022 migrated MobileUsers rows: %', v_rows;

    INSERT INTO "MobileSubscriptions"
    (
        "Id", "CompanyId", "MobileUserId", "SubscriptionPlanId", "Status", "TrialStartUtc", "TrialEndUtc", "StartUtc", "EndUtc", "GraceEndUtc", "LastValidatedUtc", "AutoRenew",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    SELECT
        uuid_generate_v4(),
        mu."CompanyId",
        mu."Id",
        tp."Id",
        'Trial',
        COALESCE(mu."CreatedAtUtc", CURRENT_TIMESTAMP),
        COALESCE(mu."CreatedAtUtc", CURRENT_TIMESTAMP) + INTERVAL '30 days',
        NULL,
        NULL,
        NULL,
        NULL,
        false,
        false,
        COALESCE(mu."CreatedAtUtc", CURRENT_TIMESTAMP),
        mu."UpdatedAtUtc",
        E'\\x'
    FROM "MobileUsers" mu
    CROSS JOIN (SELECT "Id" FROM "SubscriptionPlans" WHERE "Code" = 'MOBILE_TRIAL' LIMIT 1) tp
    LEFT JOIN "MobileSubscriptions" ms ON ms."MobileUserId" = mu."Id"
    WHERE ms."Id" IS NULL;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '022 migrated MobileSubscriptions rows: %', v_rows;

    -- Recovery path: some deployments already have MobileDevices rows that point to users
    -- without any active subscription. Backfill one trial subscription per such user.
    INSERT INTO "MobileSubscriptions"
    (
        "Id", "CompanyId", "MobileUserId", "SubscriptionPlanId", "Status", "TrialStartUtc", "TrialEndUtc", "StartUtc", "EndUtc", "GraceEndUtc", "LastValidatedUtc", "AutoRenew",
        "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
    )
    SELECT
        uuid_generate_v4(),
        mu."CompanyId",
        mu."Id",
        tp."Id",
        'Trial',
        COALESCE(mu."CreatedAtUtc", CURRENT_TIMESTAMP),
        COALESCE(mu."CreatedAtUtc", CURRENT_TIMESTAMP) + INTERVAL '30 days',
        NULL,
        NULL,
        NULL,
        NULL,
        false,
        false,
        CURRENT_TIMESTAMP,
        NULL,
        E'\\x'
    FROM (
        SELECT DISTINCT d."MobileUserId"
        FROM "MobileDevices" d
        WHERE d."IsDeleted" = false
          AND d."MobileUserId" IS NOT NULL
    ) du
    INNER JOIN "MobileUsers" mu ON mu."Id" = du."MobileUserId"
    CROSS JOIN (SELECT "Id" FROM "SubscriptionPlans" WHERE "Code" = 'MOBILE_TRIAL' LIMIT 1) tp
    LEFT JOIN "MobileSubscriptions" ms
        ON ms."MobileUserId" = mu."Id"
       AND ms."IsDeleted" = false
    WHERE ms."Id" IS NULL;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    RAISE NOTICE '022 recovered MobileSubscriptions rows (from existing devices): %', v_rows;

        -- Recovery path: fix device->user links when a company has exactly one active mobile user.
        UPDATE "MobileDevices" d
        SET "MobileUserId" = su."MobileUserId",
                "UpdatedAtUtc" = CURRENT_TIMESTAMP
        FROM (
            SELECT DISTINCT ON (mu."CompanyId")
                mu."CompanyId",
                mu."Id" AS "MobileUserId"
            FROM "MobileUsers" mu
            INNER JOIN (
                SELECT m2."CompanyId"
                FROM "MobileUsers" m2
                WHERE m2."IsDeleted" = false
                GROUP BY m2."CompanyId"
                HAVING COUNT(*) = 1
            ) single_company ON single_company."CompanyId" = mu."CompanyId"
            WHERE mu."IsDeleted" = false
            ORDER BY mu."CompanyId", mu."Id"
        ) su
        WHERE d."IsDeleted" = false
            AND d."CompanyId" = su."CompanyId"
            AND NOT EXISTS (
                    SELECT 1
                    FROM "MobileUsers" eu
                    WHERE eu."Id" = d."MobileUserId"
                        AND eu."IsDeleted" = false
            );
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        RAISE NOTICE '022 recovered MobileDevices->MobileUserId links: %', v_rows;

        -- Recovery path: revive soft-deleted subscriptions for users that already have devices.
        UPDATE "MobileSubscriptions" s
        SET "IsDeleted" = false,
                "UpdatedAtUtc" = CURRENT_TIMESTAMP
        FROM (
                SELECT DISTINCT d."MobileUserId"
                FROM "MobileDevices" d
                WHERE d."IsDeleted" = false
                    AND d."MobileUserId" IS NOT NULL
        ) du
        WHERE s."MobileUserId" = du."MobileUserId"
            AND s."IsDeleted" = true;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        RAISE NOTICE '022 revived soft-deleted subscriptions: %', v_rows;

    IF v_has_devices_table THEN
        EXECUTE format($fmt$
            INSERT INTO "MobileDevices"
            (
                "Id", "CompanyId", "MobileUserId", "DeviceId", "Manufacturer", "Model", "Platform", "OsVersion", "AppVersion", "PushToken", "LastIpAddress", "LastLoginAtUtc", "LastHeartbeatAtUtc", "LastSyncAtUtc", "Status",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            SELECT
                d."Id",
                %2$s,
                mu."Id",
                TRIM(d."DeviceId"),
                NULL,
                NULL,
                COALESCE(NULLIF(TRIM(d."Platform"), ''), 'android'),
                NULL,
                COALESCE(NULLIF(TRIM(d."AppVersion"), ''), 'legacy'),
                d."PushToken",
                d."LastIpAddress",
                d."LastSeenAt",
                d."LastSeenAt",
                d."LastSeenAt",
                CASE WHEN COALESCE(d."IsBlocked", false) = true THEN 'Disabled' ELSE 'Active' END,
                false,
                COALESCE(d."CreatedAt", CURRENT_TIMESTAMP),
                d."UpdatedAt",
                E'\\x'
                    FROM %3$I.%4$I d
                    INNER JOIN %5$I.%6$I c ON c."Id" = d."CustomerId"
                    INNER JOIN "MobileUsers" mu ON mu."CompanyId" = %2$s AND mu."Mobile" = TRIM(c.%1$I)
                    LEFT JOIN "MobileDevices" md ON md."CompanyId" = %2$s AND md."MobileUserId" = mu."Id" AND md."DeviceId" = TRIM(d."DeviceId")
            WHERE md."Id" IS NULL
                        AND %2$s IS NOT NULL
              AND d."DeviceId" IS NOT NULL
              AND TRIM(d."DeviceId") <> ''
            $fmt$, v_customer_phone_col, v_effective_company_expr, v_devices_schema, v_devices_table, v_customers_schema, v_customers_table);
            GET DIAGNOSTICS v_rows = ROW_COUNT;
            RAISE NOTICE '022 migrated MobileDevices rows: %', v_rows;
    ELSE
            RAISE NOTICE '022 migrated MobileDevices rows: 0 (legacy Devices table unavailable)';
    END IF;

    IF v_has_licenses_table THEN
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I',
            v_licenses_schema,
            v_licenses_table
        )
        INTO v_legacy_license_rows;
    END IF;

    IF v_has_licenses_table AND v_has_devices_table THEN
        EXECUTE format($fmt$
            INSERT INTO "MobileLicenses"
            (
                "Id", "CompanyId", "MobileDeviceId", "MobileSubscriptionId", "Status", "IssuedAtUtc", "ExpiryUtc", "RevokedAtUtc",
                "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
            )
            SELECT
                l."Id",
                md."CompanyId",
                md."Id",
                ms."Id",
                CASE
                    WHEN COALESCE(l."IsRevoked", false) THEN 'Revoked'
                    WHEN l."ExpiryUtc" IS NOT NULL AND l."ExpiryUtc" < CURRENT_TIMESTAMP THEN 'Expired'
                    ELSE 'Active'
                END,
                COALESCE(l."IssuedAtUtc", CURRENT_TIMESTAMP),
                l."ExpiryUtc",
                l."RevokedAtUtc",
                false,
                COALESCE(l."CreatedAt", CURRENT_TIMESTAMP),
                l."UpdatedAt",
                E'\\x'
                    FROM %3$I.%4$I l
                    INNER JOIN %5$I.%6$I d ON d."Id" = l."DeviceId"
                    INNER JOIN %7$I.%8$I c ON c."Id" = d."CustomerId"
            INNER JOIN "MobileUsers" mu ON mu."CompanyId" = %2$s AND mu."Mobile" = TRIM(c.%1$I)
            INNER JOIN "MobileDevices" md ON md."CompanyId" = %2$s AND md."MobileUserId" = mu."Id" AND md."DeviceId" = TRIM(d."DeviceId")
            INNER JOIN "MobileSubscriptions" ms ON ms."MobileUserId" = mu."Id"
            LEFT JOIN "MobileLicenses" ml ON ml."MobileDeviceId" = md."Id"
            WHERE ml."Id" IS NULL
              AND %2$s IS NOT NULL
            $fmt$, v_customer_phone_col, v_effective_company_expr, v_licenses_schema, v_licenses_table, v_devices_schema, v_devices_table, v_customers_schema, v_customers_table);
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        RAISE NOTICE '022 migrated MobileLicenses rows: %', v_rows;
    ELSE
        RAISE NOTICE '022 migrated MobileLicenses rows: 0 (legacy Devices/Licenses table unavailable)';
    END IF;

    -- Fallback for legacy databases that have no rows in Licenses.
    IF v_legacy_license_rows = 0 THEN
        INSERT INTO "MobileLicenses"
        (
            "Id", "CompanyId", "MobileDeviceId", "MobileSubscriptionId", "Status", "IssuedAtUtc", "ExpiryUtc", "RevokedAtUtc",
            "IsDeleted", "CreatedAtUtc", "UpdatedAtUtc", "RowVersion"
        )
        SELECT
            uuid_generate_v4(),
            COALESCE(md."CompanyId", ms."CompanyId"),
            md."Id",
            ms."Id",
            CASE
                WHEN ms."Status" = 'Suspended' THEN 'Suspended'
                WHEN ms."Status" = 'Expired' THEN 'Expired'
                ELSE 'Active'
            END,
            COALESCE(ms."StartUtc", ms."TrialStartUtc", md."CreatedAtUtc", CURRENT_TIMESTAMP),
            COALESCE(ms."EndUtc", ms."TrialEndUtc"),
            NULL,
            false,
            CURRENT_TIMESTAMP,
            NULL,
            E'\\x'
        FROM "MobileDevices" md
        INNER JOIN LATERAL (
            SELECT s.*
            FROM "MobileSubscriptions" s
            WHERE s."IsDeleted" = false
              AND (
                    (md."MobileUserId" IS NOT NULL AND s."MobileUserId" = md."MobileUserId")
                 OR (md."MobileUserId" IS NULL AND md."CompanyId" IS NOT NULL AND s."CompanyId" = md."CompanyId")
              )
            ORDER BY
                CASE s."Status"
                    WHEN 'Active' THEN 0
                    WHEN 'Trial' THEN 1
                    WHEN 'Grace' THEN 2
                    ELSE 9
                END,
                COALESCE(s."UpdatedAtUtc", s."CreatedAtUtc") DESC
            LIMIT 1
        ) ms ON true
        LEFT JOIN "MobileLicenses" ml
            ON ml."MobileDeviceId" = md."Id"
           AND ml."IsDeleted" = false
        WHERE md."IsDeleted" = false
          AND ml."Id" IS NULL;

        GET DIAGNOSTICS v_rows = ROW_COUNT;
        RAISE NOTICE '022 fallback MobileLicenses rows: %', v_rows;
    END IF;
END $$;
