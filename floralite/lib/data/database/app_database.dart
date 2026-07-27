import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _db;

  static final bool _isTest = Platform.environment['FLUTTER_TEST'] == 'true';
  static int _testCounter = 0;

  /// Override used by tests to give each test its own database file.
  static String? testDatabaseName;

  /// When true, tests use an in-memory database instead of a file.
  static bool useInMemoryForTests = false;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) return;
    await db.close();
    _db = null;
  }

  Future<Database> _open() async {
    final path = useInMemoryForTests
        ? inMemoryDatabasePath
        : p.join(
            await getDatabasesPath(),
            testDatabaseName ??
                (_isTest
                    ? 'floraprise_test_${pid}_${_testCounter++}.db'
                    : 'floraprise.db'),
          );

    return openDatabase(
      path,
      version: 38,
      onOpen: (db) async {
        await _ensureOccasionContactColumns(db);
        await _ensureAttendanceTable(db);
        await _ensureAccountingTables(db);
        await _ensureSubscriptionTables(db);
        await _ensurePrinterTables(db);
        await _ensureSchedulerTaskColumns(db);
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            phone TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            birthday_md TEXT,
            anniversary_md TEXT,
            company TEXT,
            department TEXT,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            name TEXT NOT NULL,
            category TEXT NOT NULL DEFAULT 'Others',
            selling_price_paise INTEGER NOT NULL,
            purchase_price_paise INTEGER,
            gst_percent INTEGER NOT NULL DEFAULT 12,
            sku TEXT,
            barcode TEXT,
            manufacturer_barcode TEXT,
            floraprise_barcode TEXT,
            default_unit TEXT NOT NULL DEFAULT 'Piece',
            track_inventory INTEGER NOT NULL DEFAULT 0,
            min_stock INTEGER NOT NULL DEFAULT 0,
            supplier TEXT,
            notes TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            active INTEGER NOT NULL DEFAULT 1,
            image_path TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE product_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            default_unit TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE designs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bouquet_id TEXT NOT NULL UNIQUE,
            image_path TEXT,
            description TEXT NOT NULL,
            selling_price_paise INTEGER,
            flowers TEXT,
            occasion TEXT,
            color TEXT,
            collection TEXT,
            notes TEXT,
            status TEXT NOT NULL DEFAULT 'draft',
            is_favorite INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE inventory_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            current_qty INTEGER NOT NULL DEFAULT 0,
            min_qty INTEGER NOT NULL DEFAULT 0,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE inventory_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            order_id INTEGER,
            order_line_id INTEGER,
            txn_type TEXT NOT NULL,
            qty INTEGER NOT NULL,
            purchase_price_paise INTEGER,
            supplier TEXT,
            source TEXT NOT NULL DEFAULT 'Manual',
            reason TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(product_id) REFERENCES products(id),
            FOREIGN KEY(order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE business_profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            shop_name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            mobile_number TEXT NOT NULL,
            email TEXT,
            address TEXT,
            city TEXT,
            state TEXT,
            pin_code TEXT,
            gst_registered INTEGER NOT NULL DEFAULT 0,
            gst_number TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await _createProductionTables(db);
        await _createReadyBouquetTables(db);

        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_no TEXT NOT NULL UNIQUE,
            source TEXT NOT NULL DEFAULT 'walkIn',
            channel TEXT NOT NULL DEFAULT 'retail',
            fulfilment_type TEXT NOT NULL,
            status TEXT NOT NULL,
            customer_id INTEGER,
            customer_phone TEXT,
            customer_name TEXT,
            occasion TEXT,
            recipient_name TEXT,
            recipient_phone TEXT,
            delivery_address TEXT,
            delivery_pincode TEXT,
            delivery_landmark TEXT,
            card_message TEXT,
            special_instructions TEXT,
            scheduled_at TEXT,
            delivery_slot TEXT,
            website_order_number TEXT,
            corporate_account TEXT,
            corporate_department TEXT,
            corporate_employee_name TEXT,
            corporate_occasion TEXT,
            marketplace_name TEXT,
            marketplace_order_id TEXT,
            marketplace_status TEXT,
            relay_partner_name TEXT,
            relay_partner_phone TEXT,
            relay_partner_email TEXT,
            relay_partner_order_number TEXT,
            relay_token TEXT,
            relay_status TEXT,
            relay_sent_at TEXT,
            relay_accepted_at TEXT,
            relay_delivered_at TEXT,
            settlement_status TEXT,
            settlement_amount_paise INTEGER,
            commission_amount_paise INTEGER,
            is_paid INTEGER NOT NULL DEFAULT 0,
            subtotal_paise INTEGER NOT NULL DEFAULT 0,
            gst_total_paise INTEGER NOT NULL DEFAULT 0,
            discount_total_paise INTEGER NOT NULL DEFAULT 0,
            bill_discount_type TEXT,
            bill_discount_value INTEGER,
            round_off_paise INTEGER NOT NULL DEFAULT 0,
            grand_total_paise INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            confirmed_at TEXT,
            FOREIGN KEY(customer_id) REFERENCES customers(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_timeline_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            status TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            created_by TEXT NOT NULL DEFAULT 'system',
            FOREIGN KEY(order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_workflow_assignments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            assignment_type TEXT NOT NULL,
            associate_id INTEGER NOT NULL,
            notes TEXT,
            assigned_at TEXT NOT NULL,
            FOREIGN KEY(order_id) REFERENCES orders(id),
            FOREIGN KEY(associate_id) REFERENCES associates(id),
            UNIQUE(order_id, assignment_type)
          )
        ''');

        await db.execute('''
          CREATE TABLE relay_action_links (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            relay_token TEXT NOT NULL,
            action_name TEXT NOT NULL,
            secure_link_path TEXT NOT NULL,
            template_channel TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'prepared',
            created_at TEXT NOT NULL,
            FOREIGN KEY(order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            product_id INTEGER,
            design_ref TEXT,
            description TEXT NOT NULL,
            qty INTEGER NOT NULL,
            unit_price_paise INTEGER NOT NULL,
            gst_percent INTEGER NOT NULL,
            discount_paise INTEGER NOT NULL DEFAULT 0,
            discount_type TEXT,
            discount_value INTEGER,
            line_subtotal_paise INTEGER NOT NULL,
            line_gst_paise INTEGER NOT NULL,
            line_total_paise INTEGER NOT NULL,
            source TEXT NOT NULL,
            FOREIGN KEY(order_id) REFERENCES orders(id),
            FOREIGN KEY(product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE order_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            method TEXT NOT NULL,
            amount_paise INTEGER NOT NULL,
            reference TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE scheduler_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            priority TEXT NOT NULL DEFAULT 'normal',
            status TEXT NOT NULL DEFAULT 'pending',
            scheduled_at TEXT NOT NULL,
            deadline_at TEXT,
            notes TEXT,
            linked_customer_id INTEGER,
            linked_order_id INTEGER,
            assigned_staff_id INTEGER,
            producer TEXT NOT NULL,
            source_ref TEXT,
            requires_confirmation INTEGER NOT NULL DEFAULT 0,
            requires_alarm INTEGER NOT NULL DEFAULT 0,
            next_reminder_at TEXT,
            started_at TEXT,
            completed_at TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            FOREIGN KEY(linked_customer_id) REFERENCES customers(id),
            FOREIGN KEY(linked_order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE scheduler_notification_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id INTEGER NOT NULL,
            action TEXT NOT NULL,
            run_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            payload_json TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(task_id) REFERENCES scheduler_tasks(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE receipt_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            payload_json TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE whatsapp_share_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            payload_json TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE barcode_print_jobs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            payload_json TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE barcode_lookup_audit (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode TEXT NOT NULL,
            matched_product_id INTEGER,
            requested_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await _ensurePrinterTables(db);

        await _ensureSubscriptionTables(db);

        await db.execute('''
          CREATE TABLE occasion_contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            recipient_name TEXT NOT NULL,
            normalized_recipient_name TEXT NOT NULL,
            relationship TEXT NOT NULL,
            occasion TEXT NOT NULL,
            normalized_occasion TEXT NOT NULL,
            occasion_date TEXT NOT NULL,
            phone TEXT,
            recipient_phone TEXT,
            company TEXT,
            notes TEXT,
            reminder_enabled INTEGER NOT NULL DEFAULT 1,
            source TEXT NOT NULL DEFAULT 'Manual',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            FOREIGN KEY(customer_id) REFERENCES customers(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE relationship_master (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE occasion_master (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE festival_master (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            month INTEGER NOT NULL,
            day INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE occasion_followup_actions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            source_type TEXT NOT NULL,
            source_id INTEGER NOT NULL,
            occurrence_date TEXT NOT NULL,
            status TEXT NOT NULL,
            snoozed_to TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE morning_purchase_list_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            list_date TEXT NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            unit TEXT NOT NULL,
            supplier TEXT,
            priority TEXT NOT NULL DEFAULT 'Normal',
            remarks TEXT,
            purchased INTEGER NOT NULL DEFAULT 0,
            inventory_updated INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT,
            FOREIGN KEY(product_id) REFERENCES products(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE associates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            associate_code TEXT NOT NULL UNIQUE,
            business_name TEXT NOT NULL,
            contact_person TEXT,
            phone TEXT NOT NULL,
            whatsapp TEXT,
            email TEXT,
            city TEXT NOT NULL,
            state TEXT,
            pincode TEXT NOT NULL,
            address TEXT,
            gst_number TEXT,
            website TEXT,
            notes TEXT,
            types TEXT NOT NULL DEFAULT 'Other',
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE staff (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            staff_code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            phone TEXT NOT NULL UNIQUE,
            whatsapp TEXT,
            same_as_phone INTEGER NOT NULL DEFAULT 1,
            email TEXT,
            role TEXT NOT NULL,
            city TEXT,
            address TEXT,
            joining_date TEXT,
            salary_type TEXT,
            salary_amount REAL,
            can_design INTEGER NOT NULL DEFAULT 0,
            can_deliver INTEGER NOT NULL DEFAULT 0,
            can_manage_orders INTEGER NOT NULL DEFAULT 0,
            active INTEGER NOT NULL DEFAULT 1,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE third_party_deliveries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            delivery_partner TEXT NOT NULL,
            booking_reference TEXT,
            driver_name TEXT,
            driver_mobile TEXT,
            delivery_charges_paise INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            FOREIGN KEY(order_id) REFERENCES orders(id)
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_orders_type_status ON orders(fulfilment_type, status)',
        );
        await db.execute(
          'CREATE INDEX idx_products_active_category ON products(active, category)',
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_products_sku_unique_active ON products(sku) WHERE sku IS NOT NULL AND TRIM(sku) <> '' AND deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_products_manufacturer_barcode_unique_active ON products(manufacturer_barcode) WHERE manufacturer_barcode IS NOT NULL AND TRIM(manufacturer_barcode) <> '' AND deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_products_floraprise_barcode_unique_active ON products(floraprise_barcode) WHERE floraprise_barcode IS NOT NULL AND TRIM(floraprise_barcode) <> '' AND deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_product_categories_name_unique_active ON product_categories(normalized_name) WHERE deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_occasion_contacts_unique_active ON occasion_contacts(customer_id, normalized_recipient_name, normalized_occasion) WHERE deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_relationship_master_unique_active ON relationship_master(normalized_name) WHERE deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_occasion_master_unique_active ON occasion_master(normalized_name) WHERE deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_festival_master_unique_active ON festival_master(normalized_name) WHERE deleted_at IS NULL",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_followup_actions_unique ON occasion_followup_actions(source_type, source_id, occurrence_date)",
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_morning_purchase_list_unique_active ON morning_purchase_list_items(list_date, product_id) WHERE deleted_at IS NULL",
        );
        await db.execute(
          'CREATE INDEX idx_morning_purchase_list_date_status ON morning_purchase_list_items(list_date, purchased)',
        );
        await db.execute(
          "CREATE UNIQUE INDEX idx_associates_business_name_phone_unique_active ON associates(business_name, phone) WHERE deleted_at IS NULL",
        );
        await db.execute(
          'CREATE INDEX idx_associates_code ON associates(associate_code)',
        );
        await db.execute(
          'CREATE INDEX idx_associates_active ON associates(is_active, deleted_at)',
        );
        await db.execute(
          'CREATE INDEX idx_associates_search ON associates(business_name, contact_person, phone, city)',
        );
        await db.execute(
          'CREATE INDEX idx_staff_search ON staff(name, phone, role)',
        );
        await db.execute(
          'CREATE INDEX idx_staff_role_active ON staff(role, active)',
        );
        await db.execute(
            'CREATE INDEX idx_orders_created_at ON orders(created_at)');
        await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
        await db.execute('CREATE INDEX idx_orders_source ON orders(source)');
        await db.execute('CREATE INDEX idx_orders_channel ON orders(channel)');
        await db.execute('CREATE INDEX idx_orders_paid ON orders(is_paid)');
        await db.execute(
            'CREATE INDEX idx_orders_search_order_no ON orders(order_no)');
        await db.execute(
            'CREATE INDEX idx_orders_search_customer_phone ON orders(customer_phone)');
        await db.execute(
            'CREATE INDEX idx_orders_search_recipient ON orders(recipient_name)');
        await db.execute(
            'CREATE INDEX idx_orders_search_website_order ON orders(website_order_number)');
        await db.execute(
            'CREATE INDEX idx_orders_search_marketplace_order ON orders(marketplace_order_id)');
        await db.execute(
            'CREATE INDEX idx_orders_search_relay_partner ON orders(relay_partner_name)');
        await db.execute('CREATE INDEX idx_customer_phone ON customers(phone)');
        await db.execute(
          'CREATE INDEX idx_designs_active ON designs(deleted_at, updated_at)',
        );
        await db.execute(
          'CREATE INDEX idx_designs_search ON designs(bouquet_id, description, flowers, occasion)',
        );
        await db.execute(
            'CREATE INDEX idx_order_lines_order ON order_lines(order_id)');
        await db.execute(
          'CREATE INDEX idx_inventory_transactions_product_created ON inventory_transactions(product_id, created_at DESC)',
        );
        await db.execute(
          'CREATE INDEX idx_timeline_order_created ON order_timeline_events(order_id, created_at)',
        );
        await db.execute(
          'CREATE INDEX idx_scheduler_tasks_operational ON scheduler_tasks(status, scheduled_at)',
        );
        await db.execute(
          'CREATE INDEX idx_scheduler_tasks_type_date ON scheduler_tasks(type, scheduled_at)',
        );
        await db.execute(
          'CREATE INDEX idx_scheduler_tasks_order ON scheduler_tasks(linked_order_id)',
        );
        await db.execute(
          'CREATE INDEX idx_scheduler_tasks_customer ON scheduler_tasks(linked_customer_id)',
        );
        await db.execute(
          'CREATE UNIQUE INDEX idx_scheduler_tasks_producer_ref ON scheduler_tasks(producer, source_ref) WHERE source_ref IS NOT NULL',
        );

        await _seedDefaultCategories(db);
        await _seedOccasionMasters(db);
        await _seedOwnerStaff(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS scheduler_tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              type TEXT NOT NULL,
              category TEXT NOT NULL,
              priority TEXT NOT NULL DEFAULT 'normal',
              status TEXT NOT NULL DEFAULT 'pending',
              scheduled_at TEXT NOT NULL,
              deadline_at TEXT,
              notes TEXT,
              linked_customer_id INTEGER,
              linked_order_id INTEGER,
              assigned_staff_id INTEGER,
              producer TEXT NOT NULL,
              source_ref TEXT,
              requires_confirmation INTEGER NOT NULL DEFAULT 0,
              requires_alarm INTEGER NOT NULL DEFAULT 0,
              next_reminder_at TEXT,
              started_at TEXT,
              completed_at TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT,
              FOREIGN KEY(linked_customer_id) REFERENCES customers(id),
              FOREIGN KEY(linked_order_id) REFERENCES orders(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS scheduler_notification_jobs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              task_id INTEGER NOT NULL,
              action TEXT NOT NULL,
              run_at TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              payload_json TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY(task_id) REFERENCES scheduler_tasks(id)
            )
          ''');

          final hasLegacyTable = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='scheduler_entries'",
          );

          if (hasLegacyTable.isNotEmpty) {
            await db.execute('''
              INSERT INTO scheduler_tasks (
                title,
                type,
                category,
                priority,
                status,
                scheduled_at,
                notes,
                linked_order_id,
                producer,
                source_ref,
                requires_confirmation,
                created_at,
                updated_at
              )
              SELECT
                title,
                entry_type,
                CASE
                  WHEN entry_type = 'delivery' THEN 'delivery'
                  WHEN entry_type = 'pickup' THEN 'delivery'
                  ELSE 'operational'
                END,
                'normal',
                status,
                due_at,
                note,
                order_id,
                'walkIn',
                'walkin_' || order_id || '_' || entry_type,
                0,
                created_at,
                created_at
              FROM scheduler_entries
            ''');
          }

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_scheduler_tasks_operational ON scheduler_tasks(status, scheduled_at)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_scheduler_tasks_type_date ON scheduler_tasks(type, scheduled_at)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_scheduler_tasks_order ON scheduler_tasks(linked_order_id)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_scheduler_tasks_customer ON scheduler_tasks(linked_customer_id)',
          );
          await db.execute(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_scheduler_tasks_producer_ref ON scheduler_tasks(producer, source_ref) WHERE source_ref IS NOT NULL',
          );
        }

        if (oldVersion < 3) {
          await db.execute(
              "ALTER TABLE orders ADD COLUMN source TEXT NOT NULL DEFAULT 'walkIn'");
          await db.execute(
              "ALTER TABLE orders ADD COLUMN channel TEXT NOT NULL DEFAULT 'retail'");
          await db.execute(
              'ALTER TABLE orders ADD COLUMN website_order_number TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN corporate_account TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN corporate_department TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN corporate_employee_name TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN corporate_occasion TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN marketplace_name TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN marketplace_order_id TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN marketplace_status TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN relay_partner_name TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN relay_partner_phone TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN relay_partner_email TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN relay_partner_order_number TEXT');
          await db.execute('ALTER TABLE orders ADD COLUMN relay_token TEXT');
          await db.execute('ALTER TABLE orders ADD COLUMN relay_status TEXT');
          await db.execute('ALTER TABLE orders ADD COLUMN relay_sent_at TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN relay_accepted_at TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN relay_delivered_at TEXT');
          await db
              .execute('ALTER TABLE orders ADD COLUMN settlement_status TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN settlement_amount_paise INTEGER');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN commission_amount_paise INTEGER');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN is_paid INTEGER NOT NULL DEFAULT 0');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS order_timeline_events (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL,
              status TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL,
              created_by TEXT NOT NULL DEFAULT 'system',
              FOREIGN KEY(order_id) REFERENCES orders(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS relay_action_links (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL,
              relay_token TEXT NOT NULL,
              action_name TEXT NOT NULL,
              secure_link_path TEXT NOT NULL,
              template_channel TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'prepared',
              created_at TEXT NOT NULL,
              FOREIGN KEY(order_id) REFERENCES orders(id)
            )
          ''');

          await db.execute('''
            INSERT INTO order_timeline_events(order_id, status, notes, created_at, created_by)
            SELECT o.id, 'created', 'Backfilled timeline created event', o.created_at, 'migration'
            FROM orders o
            WHERE NOT EXISTS (
              SELECT 1 FROM order_timeline_events t WHERE t.order_id = o.id
            )
          ''');

          await db.execute('''
            INSERT INTO order_timeline_events(order_id, status, notes, created_at, created_by)
            SELECT o.id, 'confirmed', 'Backfilled confirmation event', o.confirmed_at, 'migration'
            FROM orders o
            WHERE o.confirmed_at IS NOT NULL
              AND NOT EXISTS (
                SELECT 1 FROM order_timeline_events t
                WHERE t.order_id = o.id AND t.status = 'confirmed'
              )
          ''');

          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_source ON orders(source)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_channel ON orders(channel)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_paid ON orders(is_paid)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_order_no ON orders(order_no)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_customer_phone ON orders(customer_phone)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_recipient ON orders(recipient_name)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_website_order ON orders(website_order_number)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_marketplace_order ON orders(marketplace_order_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_orders_search_relay_partner ON orders(relay_partner_name)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_timeline_order_created ON order_timeline_events(order_id, created_at)');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('ALTER TABLE customers ADD COLUMN deleted_at TEXT');
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS designs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              bouquet_id TEXT NOT NULL UNIQUE,
              image_path TEXT,
              description TEXT NOT NULL,
              selling_price_paise INTEGER,
              flowers TEXT,
              occasion TEXT,
              color TEXT,
              collection TEXT,
              notes TEXT,
              status TEXT NOT NULL DEFAULT 'draft',
              is_favorite INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_designs_active ON designs(deleted_at, updated_at)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_designs_search ON designs(bouquet_id, description, flowers, occasion)',
          );
        }

        if (oldVersion < 7) {
          await db.execute('ALTER TABLE designs ADD COLUMN collection TEXT');
          await db.execute(
            "ALTER TABLE designs ADD COLUMN status TEXT NOT NULL DEFAULT 'draft'",
          );
          await db.execute(
            "UPDATE designs SET status = 'draft' WHERE status IS NULL OR TRIM(status) = ''",
          );
        }

        if (oldVersion < 8) {
          await db.execute('ALTER TABLE orders ADD COLUMN delivery_slot TEXT');
        }

        if (oldVersion < 9) {
          await db.execute(
              "ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'");
          await db.execute(
              'ALTER TABLE products ADD COLUMN purchase_price_paise INTEGER');
          await db.execute('ALTER TABLE products ADD COLUMN sku TEXT');
          await db.execute(
              'ALTER TABLE products ADD COLUMN manufacturer_barcode TEXT');
          await db.execute(
              'ALTER TABLE products ADD COLUMN floraprise_barcode TEXT');
          await db.execute(
              'ALTER TABLE products ADD COLUMN track_inventory INTEGER NOT NULL DEFAULT 0');
          await db.execute(
              'ALTER TABLE products ADD COLUMN min_stock INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE products ADD COLUMN supplier TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN notes TEXT');
          await db.execute(
              'ALTER TABLE products ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE products ADD COLUMN deleted_at TEXT');

          await db.execute(
            "UPDATE products SET sku = code WHERE (sku IS NULL OR TRIM(sku) = '') AND code IS NOT NULL AND TRIM(code) <> ''",
          );
          await db.execute(
            "UPDATE products SET manufacturer_barcode = barcode WHERE (manufacturer_barcode IS NULL OR TRIM(manufacturer_barcode) = '') AND barcode IS NOT NULL AND TRIM(barcode) <> ''",
          );
          await db.execute(
            "UPDATE products SET floraprise_barcode = 'FLR-' || id WHERE floraprise_barcode IS NULL OR TRIM(floraprise_barcode) = ''",
          );
          await db.execute(
            'UPDATE products SET min_stock = COALESCE((SELECT min_qty FROM inventory_items i WHERE i.product_id = products.id LIMIT 1), 0) WHERE COALESCE(min_stock, 0) = 0',
          );

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_products_active_category ON products(active, category)',
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_products_sku_unique_active ON products(sku) WHERE sku IS NOT NULL AND TRIM(sku) <> '' AND deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_products_manufacturer_barcode_unique_active ON products(manufacturer_barcode) WHERE manufacturer_barcode IS NOT NULL AND TRIM(manufacturer_barcode) <> '' AND deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_products_floraprise_barcode_unique_active ON products(floraprise_barcode) WHERE floraprise_barcode IS NOT NULL AND TRIM(floraprise_barcode) <> '' AND deleted_at IS NULL",
          );
        }

        if (oldVersion < 10) {
          await db.execute(
            "ALTER TABLE products ADD COLUMN default_unit TEXT NOT NULL DEFAULT 'Piece'",
          );
          await db.execute(
            "UPDATE products SET default_unit = 'Piece' WHERE default_unit IS NULL OR TRIM(default_unit) = ''",
          );
        }

        if (oldVersion < 11) {
          await db.execute(
            "ALTER TABLE inventory_transactions ADD COLUMN source TEXT NOT NULL DEFAULT 'Manual'",
          );
          await db.execute(
            'ALTER TABLE inventory_transactions ADD COLUMN reason TEXT',
          );
          await db.execute(
            "UPDATE inventory_transactions SET source = 'Walk-in Sale' WHERE txn_type = 'sale' AND order_id IS NOT NULL",
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_inventory_transactions_product_created ON inventory_transactions(product_id, created_at DESC)',
          );
        }

        if (oldVersion < 12) {
          await db.execute(
            'ALTER TABLE inventory_transactions ADD COLUMN purchase_price_paise INTEGER',
          );
          await db.execute(
            'ALTER TABLE inventory_transactions ADD COLUMN supplier TEXT',
          );
        }

        if (oldVersion < 13) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS barcode_print_jobs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id INTEGER NOT NULL,
              payload_json TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              FOREIGN KEY(product_id) REFERENCES products(id)
            )
          ''');
        }

        if (oldVersion < 14) {
          await db.execute('ALTER TABLE customers ADD COLUMN birthday_md TEXT');
          await db
              .execute('ALTER TABLE customers ADD COLUMN anniversary_md TEXT');
          await db.execute('ALTER TABLE customers ADD COLUMN company TEXT');
          await db.execute('ALTER TABLE customers ADD COLUMN department TEXT');
          await db.execute('ALTER TABLE customers ADD COLUMN notes TEXT');
        }

        if (oldVersion < 15) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS product_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              normalized_name TEXT NOT NULL,
              default_unit TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');

          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_product_categories_name_unique_active ON product_categories(normalized_name) WHERE deleted_at IS NULL",
          );

          await _seedDefaultCategories(db);
          await _migrateLegacyProductCategories(db);
        }

        if (oldVersion < 16) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS occasion_contacts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              customer_id INTEGER NOT NULL,
              recipient_name TEXT NOT NULL,
              normalized_recipient_name TEXT NOT NULL,
              relationship TEXT NOT NULL,
              occasion TEXT NOT NULL,
              normalized_occasion TEXT NOT NULL,
              occasion_date TEXT NOT NULL,
              phone TEXT,
              recipient_phone TEXT,
              company TEXT,
              notes TEXT,
              reminder_enabled INTEGER NOT NULL DEFAULT 1,
              source TEXT NOT NULL DEFAULT 'Manual',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT,
              FOREIGN KEY(customer_id) REFERENCES customers(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS relationship_master (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              normalized_name TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS occasion_master (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              normalized_name TEXT NOT NULL,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS festival_master (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              normalized_name TEXT NOT NULL,
              month INTEGER NOT NULL,
              day INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS occasion_followup_actions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              source_type TEXT NOT NULL,
              source_id INTEGER NOT NULL,
              occurrence_date TEXT NOT NULL,
              status TEXT NOT NULL,
              snoozed_to TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_occasion_contacts_unique_active ON occasion_contacts(customer_id, normalized_recipient_name, normalized_occasion) WHERE deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_relationship_master_unique_active ON relationship_master(normalized_name) WHERE deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_occasion_master_unique_active ON occasion_master(normalized_name) WHERE deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_festival_master_unique_active ON festival_master(normalized_name) WHERE deleted_at IS NULL",
          );
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_followup_actions_unique ON occasion_followup_actions(source_type, source_id, occurrence_date)",
          );

          await _seedOccasionMasters(db);
        }

        if (oldVersion < 17) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS morning_purchase_list_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              list_date TEXT NOT NULL,
              product_id INTEGER NOT NULL,
              quantity INTEGER NOT NULL,
              unit TEXT NOT NULL,
              supplier TEXT,
              priority TEXT NOT NULL DEFAULT 'Normal',
              remarks TEXT,
              purchased INTEGER NOT NULL DEFAULT 0,
              inventory_updated INTEGER NOT NULL DEFAULT 0,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT,
              FOREIGN KEY(product_id) REFERENCES products(id)
            )
          ''');

          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_morning_purchase_list_unique_active ON morning_purchase_list_items(list_date, product_id) WHERE deleted_at IS NULL",
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_morning_purchase_list_date_status ON morning_purchase_list_items(list_date, purchased)',
          );
        }

        if (oldVersion < 18) {
          await db
              .execute('ALTER TABLE order_lines ADD COLUMN discount_type TEXT');
          await db.execute(
              'ALTER TABLE order_lines ADD COLUMN discount_value INTEGER');
          await db
              .execute('ALTER TABLE orders ADD COLUMN bill_discount_type TEXT');
          await db.execute(
              'ALTER TABLE orders ADD COLUMN bill_discount_value INTEGER');
        }

        if (oldVersion < 19) {
          await _ensureColumn(
            db,
            'occasion_contacts',
            'recipient_phone',
            'TEXT',
          );
        }

        if (oldVersion < 20) {
          await _ensureColumn(
            db,
            'occasion_contacts',
            'source',
            'TEXT',
            defaultValue: "'Manual'",
            notNull: true,
          );
        }

        if (oldVersion < 21) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS associates (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              associate_code TEXT NOT NULL UNIQUE,
              business_name TEXT NOT NULL,
              contact_person TEXT,
              phone TEXT NOT NULL,
              whatsapp TEXT,
              email TEXT,
              city TEXT NOT NULL,
              state TEXT,
              pincode TEXT NOT NULL,
              address TEXT,
              gst_number TEXT,
              website TEXT,
              notes TEXT,
              types TEXT NOT NULL DEFAULT 'Other',
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');

          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS idx_associates_business_name_phone_unique_active ON associates(business_name, phone) WHERE deleted_at IS NULL",
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_associates_code ON associates(associate_code)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_associates_active ON associates(is_active, deleted_at)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_associates_search ON associates(business_name, contact_person, phone, city)',
          );
        }

        if (oldVersion < 22) {
          // Order Workflow module extension: store designer, delivery and
          // relay assignments separately from the core orders table.
          await db.execute('''
            CREATE TABLE IF NOT EXISTS order_workflow_assignments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL,
              assignment_type TEXT NOT NULL,
              associate_id INTEGER NOT NULL,
              notes TEXT,
              assigned_at TEXT NOT NULL,
              FOREIGN KEY(order_id) REFERENCES orders(id),
              FOREIGN KEY(associate_id) REFERENCES associates(id),
              UNIQUE(order_id, assignment_type)
            )
          ''');
        }

        if (oldVersion < 23) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS staff (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              staff_code TEXT NOT NULL UNIQUE,
              name TEXT NOT NULL,
              phone TEXT NOT NULL UNIQUE,
              whatsapp TEXT,
              same_as_phone INTEGER NOT NULL DEFAULT 1,
              email TEXT,
              role TEXT NOT NULL,
              city TEXT,
              address TEXT,
              joining_date TEXT,
              salary_type TEXT,
              salary_amount REAL,
              active INTEGER NOT NULL DEFAULT 1,
              notes TEXT,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_staff_search ON staff(name, phone, role)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_staff_role_active ON staff(role, active)',
          );
          await _seedOwnerStaff(db);
        }

        if (oldVersion < 24 && oldVersion >= 23) {
          await db.execute('ALTER TABLE staff ADD COLUMN salary_type TEXT');
          await db.execute('ALTER TABLE staff ADD COLUMN salary_amount REAL');
        }

        if (oldVersion < 24) {
          await _ensureOccasionContactColumns(db);
        }

        if (oldVersion < 25) {
          await _addStaffPermissionColumns(db);
          await _addThirdPartyDeliveryTable(db);
        }

        if (oldVersion < 26) {
          await _addAttendanceTable(db);
        }

        if (oldVersion < 27) {
          await _ensureAttendanceTable(db);
        }

        if (oldVersion < 28) {
          await _addAccountingTables(db);
        }

        if (oldVersion < 29) {
          await _ensureSubscriptionTables(db);
        }

        if (oldVersion < 30) {
          await _addBusinessProfileTable(db);
        }

        if (oldVersion < 31) {
          await _createProductionTables(db);
        }

        if (oldVersion < 32 && oldVersion >= 31) {
          await _extendProductionAuditSchema(db);
        }

        if (oldVersion < 33) {
          await _ensureColumn(
            db,
            'product_recipes',
            'shelf_life_days',
            'INTEGER',
            defaultValue: '3',
            notNull: true,
          );
          await _ensureColumn(
            db,
            'product_recipes',
            'refresh_after_days',
            'INTEGER',
            defaultValue: '2',
            notNull: true,
          );
          await _createReadyBouquetTables(db);
        }

        if (oldVersion < 34) {
          await _ensurePrinterTables(db);
        }

        if (oldVersion < 35) {
          await _makeReadyBouquetRecipeIdNullable(db);
        }

        if (oldVersion < 36) {
          await _ensureColumn(
            db,
            'products',
            'image_path',
            'TEXT',
          );
          await _ensureColumn(
            db,
            'product_recipes',
            'occasion',
            'TEXT',
          );
        }

        if (oldVersion < 37) {
          // Repair databases that were created without the ready-bouquet tables
          // (or with an older, incomplete version of them).
          await _createReadyBouquetTables(db);
          await _ensureColumn(
            db,
            'products',
            'image_path',
            'TEXT',
          );
          await _ensureColumn(
            db,
            'product_recipes',
            'occasion',
            'TEXT',
          );
        }

        if (oldVersion < 38) {
          await _ensureSchedulerTaskColumns(db);
        }
      },
    );
  }

  Future<void> _makeReadyBouquetRecipeIdNullable(Database db) async {
    // SQLite doesn't support dropping NOT NULL, so recreate the table.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ready_bouquet_batches_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        finished_product_id INTEGER NOT NULL,
        recipe_id INTEGER,
        production_id INTEGER,
        initial_quantity INTEGER NOT NULL CHECK(initial_quantity > 0),
        remaining_quantity INTEGER NOT NULL CHECK(remaining_quantity >= 0),
        shelf_life_days INTEGER NOT NULL DEFAULT 3,
        refresh_after_days INTEGER NOT NULL DEFAULT 2,
        produced_at TEXT NOT NULL,
        last_refresh_at TEXT,
        expiry_at TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT 'Store',
        status TEXT NOT NULL DEFAULT 'fresh',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(finished_product_id) REFERENCES products(id),
        FOREIGN KEY(recipe_id) REFERENCES product_recipes(id),
        FOREIGN KEY(production_id) REFERENCES productions(id)
      )
    ''');
    await db.execute('''
      INSERT INTO ready_bouquet_batches_new (
        id, finished_product_id, recipe_id, production_id,
        initial_quantity, remaining_quantity,
        shelf_life_days, refresh_after_days,
        produced_at, last_refresh_at, expiry_at,
        location, status, note, created_at
      )
      SELECT
        id, finished_product_id, recipe_id, production_id,
        initial_quantity, remaining_quantity,
        shelf_life_days, refresh_after_days,
        produced_at, last_refresh_at, expiry_at,
        location, status, note, created_at
      FROM ready_bouquet_batches
    ''');
    await db.execute('DROP TABLE ready_bouquet_batches');
    await db.execute(
        'ALTER TABLE ready_bouquet_batches_new RENAME TO ready_bouquet_batches');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ready_bouquet_batches_product ON ready_bouquet_batches(finished_product_id, produced_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ready_bouquet_batches_status ON ready_bouquet_batches(status)',
    );
  }

  Future<void> _ensurePrinterTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS printer_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        connection_type TEXT NOT NULL DEFAULT 'bluetooth',
        paper_width_mm INTEGER NOT NULL DEFAULT 80,
        printer_name TEXT,
        printer_address TEXT,
        auto_connect INTEGER NOT NULL DEFAULT 1,
        auto_print_after_billing INTEGER NOT NULL DEFAULT 0,
        copies INTEGER NOT NULL DEFAULT 1,
        cut_paper INTEGER NOT NULL DEFAULT 1,
        print_logo INTEGER NOT NULL DEFAULT 0,
        print_qr_code INTEGER NOT NULL DEFAULT 0,
        print_barcode INTEGER NOT NULL DEFAULT 1,
        print_duplicate_copy INTEGER NOT NULL DEFAULT 0,
        thank_you_message TEXT NOT NULL DEFAULT 'Thank you for shopping with us',
        website TEXT,
        whatsapp_number TEXT,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS print_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        copies INTEGER NOT NULL DEFAULT 1,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        printed_at TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_print_queue_status_created ON print_queue(status, created_at)',
    );

    final existing = await db.query(
      'printer_config',
      columns: ['id'],
      where: 'id = 1',
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('printer_config', {
        'id': 1,
        'connection_type': 'bluetooth',
        'paper_width_mm': 80,
        'auto_connect': 1,
        'auto_print_after_billing': 0,
        'copies': 1,
        'cut_paper': 1,
        'print_logo': 0,
        'print_qr_code': 0,
        'print_barcode': 1,
        'print_duplicate_copy': 0,
        'thank_you_message': 'Thank you for shopping with us',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _ensureSubscriptionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscription (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        status TEXT NOT NULL,
        plan TEXT NOT NULL DEFAULT 'trial',
        purchase_token TEXT,
        expiry_date TEXT NOT NULL,
        grace_end_date TEXT NOT NULL,
        last_verification TEXT NOT NULL,
        offline_expiry TEXT NOT NULL,
        last_app_version TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS license_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_license_log_event ON license_log(event)',
    );
  }

  Future<void> _ensureOccasionContactColumns(Database db) async {
    await _ensureColumn(
      db,
      'occasion_contacts',
      'recipient_phone',
      'TEXT',
    );
    await _ensureColumn(
      db,
      'occasion_contacts',
      'company',
      'TEXT',
    );
    await _ensureColumn(
      db,
      'occasion_contacts',
      'source',
      'TEXT',
      defaultValue: "'Manual'",
      notNull: true,
    );
  }

  Future<void> _ensureSchedulerTaskColumns(Database db) async {
    await _ensureColumn(
      db,
      'scheduler_tasks',
      'requires_alarm',
      'INTEGER',
      defaultValue: '0',
      notNull: true,
    );
    await _ensureColumn(
      db,
      'scheduler_tasks',
      'next_reminder_at',
      'TEXT',
    );
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String sqlType, {
    String? defaultValue,
    bool notNull = false,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (exists) return;

    final buffer =
        StringBuffer('ALTER TABLE $table ADD COLUMN $column $sqlType');
    if (notNull) {
      buffer.write(' NOT NULL');
    }
    if (defaultValue != null) {
      buffer.write(' DEFAULT $defaultValue');
    }
    await db.execute(buffer.toString());
  }

  Future<void> _seedOwnerStaff(Database db) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM staff');
    if ((rows.first['count'] as int? ?? 0) > 0) return;
    final now = DateTime.now().toIso8601String();
    await db.insert('staff', {
      'staff_code': 'STF000001',
      'name': 'Owner',
      'phone': 'OWNER',
      'whatsapp': 'OWNER',
      'same_as_phone': 1,
      'role': 'Owner',
      'can_design': 1,
      'can_deliver': 1,
      'can_manage_orders': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _addStaffPermissionColumns(Database db) async {
    await _ensureColumn(
      db,
      'staff',
      'can_design',
      'INTEGER',
      defaultValue: '0',
      notNull: true,
    );
    await _ensureColumn(
      db,
      'staff',
      'can_deliver',
      'INTEGER',
      defaultValue: '0',
      notNull: true,
    );
    await _ensureColumn(
      db,
      'staff',
      'can_manage_orders',
      'INTEGER',
      defaultValue: '0',
      notNull: true,
    );
  }

  Future<void> _addThirdPartyDeliveryTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='third_party_deliveries'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE third_party_deliveries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        delivery_partner TEXT NOT NULL,
        booking_reference TEXT,
        driver_name TEXT,
        driver_mobile TEXT,
        delivery_charges_paise INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(order_id) REFERENCES orders(id)
      )
    ''');
  }

  Future<void> _addAttendanceTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='attendance'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staff_id INTEGER NOT NULL,
        attendance_date TEXT NOT NULL,
        status TEXT NOT NULL,
        clock_in TEXT,
        clock_out TEXT,
        overtime_hours INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(staff_id) REFERENCES staff(id),
        UNIQUE(staff_id, attendance_date)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_attendance_date ON attendance(attendance_date)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_staff_date ON attendance(staff_id, attendance_date)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_status ON attendance(status)',
    );
  }

  Future<void> _ensureAttendanceTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='attendance'",
    );
    if (tables.isEmpty) {
      await _addAttendanceTable(db);
    }
  }

  Future<void> _addAccountingTables(Database db) async {
    await _addExpenseCategoriesTable(db);
    await _addOpeningCashTable(db);
    await _addCashBookTable(db);
    await _addExpensesTable(db);
    await _addDayClosingTable(db);
  }

  Future<void> _ensureAccountingTables(Database db) async {
    await _ensureExpenseCategoriesTable(db);
    await _ensureOpeningCashTable(db);
    await _ensureCashBookTable(db);
    await _ensureExpensesTable(db);
    await _ensureDayClosingTable(db);
  }

  Future<void> _addExpenseCategoriesTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expense_categories'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        emoji TEXT NOT NULL,
        group_name TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expense_categories_active ON expense_categories(active)',
    );

    await _seedDefaultExpenseCategories(db);
  }

  Future<void> _ensureExpenseCategoriesTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expense_categories'",
    );
    if (tables.isEmpty) {
      await _addExpenseCategoriesTable(db);
    }
  }

  Future<void> _seedDefaultExpenseCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = <Map<String, String>>[
      {'name': 'Purchase', 'emoji': '🌸', 'group': 'Business'},
      {'name': 'Packing Material', 'emoji': '📦', 'group': 'Business'},
      {'name': 'Delivery', 'emoji': '🚚', 'group': 'Business'},
      {'name': 'Marketing', 'emoji': '📢', 'group': 'Business'},
      {'name': 'Rent', 'emoji': '🏠', 'group': 'Shop'},
      {'name': 'Electricity', 'emoji': '⚡', 'group': 'Shop'},
      {'name': 'Phone & Internet', 'emoji': '📱', 'group': 'Shop'},
      {'name': 'Shop Maintenance', 'emoji': '🧹', 'group': 'Shop'},
      {'name': 'Salary', 'emoji': '👨‍💼', 'group': 'Staff'},
      {'name': 'Tea & Snacks', 'emoji': '☕', 'group': 'Staff'},
      {'name': 'Fuel', 'emoji': '⛽', 'group': 'Travel'},
      {'name': 'Miscellaneous', 'emoji': '📝', 'group': 'Others'},
    ];

    for (final item in defaults) {
      await db.insert(
        'expense_categories',
        {
          'name': item['name'],
          'emoji': item['emoji'],
          'group_name': item['group'],
          'active': 1,
          'created_at': now,
          'updated_at': now,
        },
      );
    }
  }

  Future<void> _addOpeningCashTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='opening_cash'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE opening_cash (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_opening_cash_date ON opening_cash(date)',
    );
  }

  Future<void> _ensureOpeningCashTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='opening_cash'",
    );
    if (tables.isEmpty) {
      await _addOpeningCashTable(db);
    }
  }

  Future<void> _addCashBookTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cash_book'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE cash_book (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        description TEXT NOT NULL,
        amount INTEGER NOT NULL,
        cash_in INTEGER NOT NULL DEFAULT 0,
        cash_out INTEGER NOT NULL DEFAULT 0,
        running_balance INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_cash_book_date ON cash_book(date)',
    );
    await db.execute(
      'CREATE INDEX idx_cash_book_transaction_type ON cash_book(transaction_type)',
    );
  }

  Future<void> _ensureCashBookTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='cash_book'",
    );
    if (tables.isEmpty) {
      await _addCashBookTable(db);
    }
  }

  Future<void> _addExpensesTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        payment_mode TEXT NOT NULL,
        notes TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES expense_categories(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_expenses_date ON expenses(expense_date)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category_id)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_payment_mode ON expenses(payment_mode)',
    );
  }

  Future<void> _ensureExpensesTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'",
    );
    if (tables.isEmpty) {
      await _addExpensesTable(db);
    }
  }

  Future<void> _addBusinessProfileTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='business_profile'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE business_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        mobile_number TEXT NOT NULL,
        email TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        pin_code TEXT,
        gst_registered INTEGER NOT NULL DEFAULT 0,
        gst_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _extendProductionAuditSchema(Database db) async {
    await db.execute("ALTER TABLE productions ADD COLUMN note TEXT");
    await db.execute(
        "ALTER TABLE productions ADD COLUMN operator_name TEXT NOT NULL DEFAULT 'Admin'");
    await db.execute('ALTER TABLE productions ADD COLUMN device_name TEXT');
    await db.execute('ALTER TABLE productions ADD COLUMN reversed_at TEXT');
    await db.execute('ALTER TABLE productions ADD COLUMN reversal_note TEXT');
    await db.execute(
        'ALTER TABLE production_consumptions ADD COLUMN raw_product_name TEXT NOT NULL DEFAULT \'\'');
    await db.execute(
        "ALTER TABLE production_consumptions ADD COLUMN unit TEXT NOT NULL DEFAULT 'Piece'");
  }

  Future<void> _createProductionTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        finished_product_id INTEGER NOT NULL UNIQUE,
        shelf_life_days INTEGER NOT NULL DEFAULT 3,
        refresh_after_days INTEGER NOT NULL DEFAULT 2,
        occasion TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(finished_product_id) REFERENCES products(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_recipe_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        raw_product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        unit TEXT NOT NULL,
        FOREIGN KEY(recipe_id) REFERENCES product_recipes(id) ON DELETE CASCADE,
        FOREIGN KEY(raw_product_id) REFERENCES products(id),
        UNIQUE(recipe_id, raw_product_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS productions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        finished_product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        production_cost_paise INTEGER NOT NULL,
        note TEXT,
        operator_name TEXT NOT NULL DEFAULT 'Admin',
        device_name TEXT,
        reversed_at TEXT,
        reversal_note TEXT,
        produced_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(finished_product_id) REFERENCES products(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS production_consumptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        production_id INTEGER NOT NULL,
        raw_product_id INTEGER NOT NULL,
        raw_product_name TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        unit_cost_paise INTEGER NOT NULL,
        total_cost_paise INTEGER NOT NULL,
        FOREIGN KEY(production_id) REFERENCES productions(id) ON DELETE CASCADE,
        FOREIGN KEY(raw_product_id) REFERENCES products(id)
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_recipe_items_recipe ON product_recipe_items(recipe_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_productions_product_date ON productions(finished_product_id, produced_at DESC)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_production_consumptions_production ON production_consumptions(production_id)');
  }

  Future<void> _createReadyBouquetTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ready_bouquet_batches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        finished_product_id INTEGER NOT NULL,
        recipe_id INTEGER,
        production_id INTEGER,
        initial_quantity INTEGER NOT NULL CHECK(initial_quantity > 0),
        remaining_quantity INTEGER NOT NULL CHECK(remaining_quantity >= 0),
        shelf_life_days INTEGER NOT NULL DEFAULT 3,
        refresh_after_days INTEGER NOT NULL DEFAULT 2,
        produced_at TEXT NOT NULL,
        last_refresh_at TEXT,
        expiry_at TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT 'Store',
        status TEXT NOT NULL DEFAULT 'fresh',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(finished_product_id) REFERENCES products(id),
        FOREIGN KEY(recipe_id) REFERENCES product_recipes(id),
        FOREIGN KEY(production_id) REFERENCES productions(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ready_bouquet_batches_product ON ready_bouquet_batches(finished_product_id, produced_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ready_bouquet_batches_status ON ready_bouquet_batches(status)',
    );

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ready_bouquet_refresh_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id INTEGER NOT NULL,
        action_type TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        wastage_quantity INTEGER NOT NULL DEFAULT 0,
        reason TEXT,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(batch_id) REFERENCES ready_bouquet_batches(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ready_bouquet_refresh_events_batch ON ready_bouquet_refresh_events(batch_id)',
    );
  }

  Future<void> _addDayClosingTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='day_closing'",
    );
    if (tables.isNotEmpty) return;

    await db.execute('''
      CREATE TABLE day_closing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        cash_sales INTEGER NOT NULL DEFAULT 0,
        upi_sales INTEGER NOT NULL DEFAULT 0,
        card_sales INTEGER NOT NULL DEFAULT 0,
        credit_sales INTEGER NOT NULL DEFAULT 0,
        cash_expenses INTEGER NOT NULL DEFAULT 0,
        upi_expenses INTEGER NOT NULL DEFAULT 0,
        card_expenses INTEGER NOT NULL DEFAULT 0,
        opening_cash INTEGER NOT NULL DEFAULT 0,
        expected_cash INTEGER NOT NULL DEFAULT 0,
        counted_cash INTEGER NOT NULL DEFAULT 0,
        difference INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        closed_at TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_day_closing_date ON day_closing(date)',
    );
  }

  Future<void> _ensureDayClosingTable(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='day_closing'",
    );
    if (tables.isEmpty) {
      await _addDayClosingTable(db);
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = <Map<String, String>>[
      {'name': 'Flowers', 'default_unit': 'Stem'},
      {'name': 'Fillers', 'default_unit': 'Bunch'},
      {'name': 'Foliage', 'default_unit': 'Bunch'},
      {'name': 'Packing', 'default_unit': 'Piece'},
      {'name': 'Accessories', 'default_unit': 'Piece'},
      {'name': 'Finished Products', 'default_unit': 'Piece'},
      {'name': 'Others', 'default_unit': 'Piece'},
    ];

    for (final item in defaults) {
      final name = item['name']!;
      await db.insert(
        'product_categories',
        {
          'name': name,
          'normalized_name': name.trim().toLowerCase(),
          'default_unit': item['default_unit']!,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _migrateLegacyProductCategories(Database db) async {
    final mapping = <String, String>{
      'flower': 'Flowers',
      'filler': 'Fillers',
      'foliage': 'Foliage',
      'packing': 'Packing',
      'accessory': 'Accessories',
      'finished product': 'Finished Products',
      'other': 'Others',
    };

    for (final entry in mapping.entries) {
      await db.update(
        'products',
        {'category': entry.value},
        where: 'LOWER(TRIM(category)) = ? AND deleted_at IS NULL',
        whereArgs: [entry.key],
      );
    }
  }

  Future<void> _seedOccasionMasters(Database db) async {
    final now = DateTime.now().toIso8601String();
    const relationships = <String>[
      'Self',
      'Wife',
      'Husband',
      'Son',
      'Daughter',
      'Mother',
      'Father',
      'Brother',
      'Sister',
      'Friend',
      'Girlfriend',
      'Boyfriend',
      'Client',
      'Employee',
      'Boss',
      'Family',
      'Other',
    ];

    const occasions = <String>[
      'Birthday',
      'Anniversary',
      'Wedding Anniversary',
      'Congratulations',
      'Get Well Soon',
      'Love & Romance',
      'Corporate',
      'Festival Greeting',
      'General Reminder',
    ];

    for (final relation in relationships) {
      await db.insert(
        'relationship_master',
        {
          'name': relation,
          'normalized_name': relation.toLowerCase(),
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    for (final occasion in occasions) {
      await db.insert(
        'occasion_master',
        {
          'name': occasion,
          'normalized_name': occasion.toLowerCase(),
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    const festivalRows = <Map<String, Object>>[
      {'name': 'New Year', 'month': 1, 'day': 1},
      {'name': 'Valentine', 'month': 2, 'day': 14},
      {'name': 'Women\'s Day', 'month': 3, 'day': 8},
      {'name': 'Mother\'s Day', 'month': 5, 'day': 12},
      {'name': 'Raksha Bandhan', 'month': 8, 'day': 19},
      {'name': 'Janmashtami', 'month': 8, 'day': 26},
      {'name': 'Ganesh Chaturthi', 'month': 9, 'day': 7},
      {'name': 'Navratri', 'month': 10, 'day': 3},
      {'name': 'Dussehra', 'month': 10, 'day': 12},
      {'name': 'Karwa Chauth', 'month': 10, 'day': 20},
      {'name': 'Diwali', 'month': 11, 'day': 1},
      {'name': 'Christmas', 'month': 12, 'day': 25},
    ];

    for (final item in festivalRows) {
      final name = item['name']! as String;
      await db.insert(
        'festival_master',
        {
          'name': name,
          'normalized_name': name.toLowerCase(),
          'month': item['month'] as int,
          'day': item['day'] as int,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
