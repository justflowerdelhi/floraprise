import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_enquiry_repository.dart';
import 'package:floraprise/data/repositories/enquiry_repository.dart';
import 'package:floraprise/models/crm_models.dart';
import 'package:floraprise/providers/crm_provider.dart';
import 'package:floraprise/screens/crm/crm_enquiries_screen.dart';
import 'package:floraprise/services/crm_service.dart';

class _FakeCrmService extends CrmService {
  _FakeCrmService({this.initialEnquiries = const []});

  final List<CrmEnquiryItem> initialEnquiries;

  @override
  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    var result = List<CrmEnquiryItem>.from(initialEnquiries);
    if (status != null && status != 'all') {
      result = result.where((e) => e.status.toLowerCase() == status.toLowerCase()).toList();
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((e) =>
          e.customerName.toLowerCase().contains(q) ||
          e.customerPhone.toLowerCase().contains(q) ||
          e.requirement.toLowerCase().contains(q)).toList();
    }
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CRM Enquiry Model & Budget Conversions', () {
    test('CrmEnquiryItem correctly converts between paise and rupees', () {
      // 5000 rupees = 500000 paise
      final item = CrmEnquiryItem(
        clientSyncId: 'test-sync-1',
        customerName: 'Priya Sharma',
        customerPhone: '9876543210',
        requirement: 'Wedding stage backdrop',
        budgetPaise: 500000,
        createdAt: DateTime(2026, 9, 28),
      );

      expect(item.budgetPaise, 500000);
      expect(item.budgetAmount, 5000.0);
      expect(item.budget, 5000.0);

      // Cloud JSON serialization
      final cloudJson = item.toCloudJson();
      expect(cloudJson['budgetAmount'], 5000.0);
      expect(cloudJson['requirement'], 'Wedding stage backdrop');

      // Cloud JSON deserialization with decimal budget
      final deserialized = CrmEnquiryItem.fromCloudJson(const {
        'id': 'cloud-123',
        'clientSyncId': 'test-sync-1',
        'customerId': 'cust-guid-1',
        'customerName': 'Priya Sharma',
        'customerPhone': '9876543210',
        'category': 'Wedding',
        'requirement': 'Wedding stage backdrop',
        'budgetAmount': 7500.50,
        'status': 'follow_up',
        'createdAt': '2026-09-28T10:00:00Z',
        'updatedAt': '2026-09-28T10:00:00Z',
      });

      expect(deserialized.cloudId, 'cloud-123');
      expect(deserialized.budgetPaise, 750050);
      expect(deserialized.budgetAmount, 7500.50);
      expect(deserialized.status, 'follow_up');
    });

    test('CrmEnquiryItem SQLite row round-trip', () {
      final now = DateTime.now();
      final item = CrmEnquiryItem(
        localId: 42,
        clientSyncId: 'sync-uuid-99',
        customerId: 10,
        customerName: 'Aarav Patel',
        customerPhone: '9876500001',
        category: 'Anniversary',
        requirement: '50 Red Roses bouquet',
        eventDate: DateTime(2026, 10, 15),
        budgetPaise: 250000,
        location: 'Taj Hotel',
        notes: 'Red ribbon',
        status: 'new',
        nextAction: 'Call on Friday',
        createdAt: now,
        updatedAt: now,
      );

      final row = item.toSqlite();
      expect(row['id'], 42);
      expect(row['client_sync_id'], 'sync-uuid-99');
      expect(row['customer_id'], 10);
      expect(row['budget_paise'], 250000);

      final fromDb = CrmEnquiryItem.fromSqlite(row);
      expect(fromDb.localId, 42);
      expect(fromDb.clientSyncId, 'sync-uuid-99');
      expect(fromDb.customerName, 'Aarav Patel');
      expect(fromDb.budgetPaise, 250000);
      expect(fromDb.budgetAmount, 2500.0);
      expect(fromDb.location, 'Taj Hotel');
    });
  });

  group('CRM SQLite Enquiry Repository', () {
    late AppDatabase appDb;

    setUp(() async {
      AppDatabase.useInMemoryForTests = true;
      AppDatabase.testDatabaseName = 'test_crm_enquiry_${DateTime.now().microsecondsSinceEpoch}.db';
      appDb = AppDatabase.instance;
      await appDb.close();
    });

    tearDown(() async {
      await appDb.close();
      AppDatabase.useInMemoryForTests = false;
    });

    test('EnquiryRepository can insert, query, update, and soft delete', () async {
      final db = await appDb.database;

      // Seed a customer in SQLite
      final custId = await db.insert('customers', {
        'phone': '9876543210',
        'name': 'Priya Sharma',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final repo = EnquiryRepository();
      final now = DateTime.now();

      // 1. Create enquiry
      final created = await repo.create(
        CrmEnquiryItem(
          clientSyncId: 'test-sync-100',
          customerId: custId,
          customerName: 'Priya Sharma',
          customerPhone: '9876543210',
          category: 'Wedding',
          requirement: 'Bridal bouquet and corsages',
          eventDate: DateTime(2026, 11, 20),
          budgetPaise: 1200000,
          location: 'Grand Ballroom',
          notes: 'White lilies and baby breath',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(created.localId, isNotNull);
      expect(created.customerName, 'Priya Sharma');
      expect(created.budgetPaise, 1200000);

      // 2. Query enquiries
      final list = await repo.listEnquiries(status: 'all');
      expect(list.length, 1);
      expect(list.first.requirement, 'Bridal bouquet and corsages');

      // 3. Search query
      final searchFound = await repo.listEnquiries(query: 'Ballroom');
      expect(searchFound.length, 1);

      final searchNotFound = await repo.listEnquiries(query: 'Nonexistent');
      expect(searchNotFound, isEmpty);

      // 4. Update enquiry status
      final updated = await repo.update(
        created.copyWith(status: 'quote_sent', nextAction: 'Send revised quote'),
      );
      expect(updated.status, 'quote_sent');

      final queriedUpdated = await repo.getById(created.localId!);
      expect(queriedUpdated?.status, 'quote_sent');
      expect(queriedUpdated?.nextAction, 'Send revised quote');

      // 5. Soft delete
      await repo.delete(created.localId!);
      final afterDelete = await repo.listEnquiries();
      expect(afterDelete, isEmpty);
    });
  });

  group('CloudEnquiryRepository Mock Integration', () {
    test('CloudEnquiryRepository creates and lists enquiries via HTTP sender', () async {
      final mockRequests = <Map<String, dynamic>>[];

      final cloudRepo = CloudEnquiryRepository(
        sender: (method, uri, {body}) async {
          mockRequests.add({'method': method, 'uri': uri.toString(), 'body': body});

          if (method == 'POST') {
            return {
              'id': 'guid-cloud-1',
              'clientSyncId': body['clientSyncId'],
              'customerId': 'cust-guid-9',
              'customerName': body['customerName'],
              'customerPhone': body['customerPhone'],
              'category': body['category'],
              'requirement': body['requirement'],
              'budgetAmount': body['budgetAmount'],
              'status': 'new',
              'createdAt': '2026-09-28T10:00:00Z',
              'updatedAt': '2026-09-28T10:00:00Z',
            };
          } else if (method == 'GET') {
            return {
              'items': [
                {
                  'id': 'guid-cloud-1',
                  'clientSyncId': 'sync-1',
                  'customerId': 'cust-guid-9',
                  'customerName': 'Priya',
                  'customerPhone': '9876543210',
                  'category': 'Wedding',
                  'requirement': 'Roses',
                  'budgetAmount': 5000.0,
                  'status': 'new',
                  'createdAt': '2026-09-28T10:00:00Z',
                  'updatedAt': '2026-09-28T10:00:00Z',
                }
              ],
              'totalCount': 1,
              'page': 1,
              'pageSize': 50,
            };
          }
          return null;
        },
      );

      final created = await cloudRepo.create(
        CrmEnquiryItem(
          clientSyncId: 'sync-1',
          customerName: 'Priya',
          customerPhone: '9876543210',
          category: 'Wedding',
          requirement: 'Roses',
          budgetPaise: 500000,
          createdAt: DateTime.now(),
        ),
      );

      expect(created.cloudId, 'guid-cloud-1');
      expect(created.budgetAmount, 5000.0);
      expect(mockRequests.first['method'], 'POST');

      final list = await cloudRepo.listEnquiries();
      expect(list.length, 1);
      expect(list.first.customerName, 'Priya');
    });
  });

  group('CRM Enquiries UI Screen Testing', () {
    testWidgets('CrmEnquiriesScreen renders search bar, status chips, and enquiries', (tester) async {
      final fakeEnquiries = [
        CrmEnquiryItem(
          localId: 1,
          clientSyncId: 'sync-1',
          customerName: 'Aarav Patel',
          customerPhone: '9876543210',
          category: 'Wedding',
          requirement: '50 Red Roses for Anniversary',
          eventDate: DateTime(2026, 10, 15),
          budgetPaise: 250000,
          status: 'new',
          nextAction: 'Send Catalog',
          createdAt: DateTime.now(),
        ),
        CrmEnquiryItem(
          localId: 2,
          clientSyncId: 'sync-2',
          customerName: 'Meera Nair',
          customerPhone: '9812345678',
          category: 'Birthday',
          requirement: 'Exotic Orchid Bouquet',
          eventDate: DateTime(2026, 10, 20),
          budgetPaise: 180000,
          status: 'follow_up',
          nextAction: 'Call tomorrow',
          createdAt: DateTime.now(),
        ),
      ];

      final fakeService = _FakeCrmService(initialEnquiries: fakeEnquiries);
      final provider = CrmProvider(crmService: fakeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<CrmProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: CrmEnquiriesScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Screen Elements
      expect(find.text('Enquiries'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget); // Search bar
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Follow-up'), findsWidgets);
      expect(find.text('Quote Sent'), findsWidgets);
      expect(find.text('Won'), findsWidgets);
      expect(find.text('Lost'), findsWidgets);
      expect(find.text('New Enquiry'), findsWidgets); // FAB or Header button
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('Meera Nair'), findsOneWidget);
    });
  });

  group('SQLite Migration 44 -> 45 Safety & Integrity', () {
    test('Version 44 database upgrades cleanly to Version 45 without data loss', () async {
      final dbPath = 'test_migration_${DateTime.now().microsecondsSinceEpoch}.db';
      addTearDown(() async => await deleteDatabase(dbPath));

      // 1. Open at version 44 and create schema with initial tables
      final v44Db = await openDatabase(
        dbPath,
        version: 44,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE customers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              phone TEXT NOT NULL UNIQUE,
              name TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              deleted_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_no TEXT NOT NULL UNIQUE,
              customer_id INTEGER NOT NULL,
              customer_phone TEXT NOT NULL,
              customer_name TEXT NOT NULL,
              grand_total_paise INTEGER NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE scheduler_tasks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE occasion_contacts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              recipient_name TEXT NOT NULL,
              occasion TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        },
      );

      // Insert sample records in version 44
      final custId = await v44Db.insert('customers', {
        'phone': '9825901155',
        'name': 'Existing VIP Customer',
        'created_at': '2026-09-01T10:00:00Z',
        'updated_at': '2026-09-01T10:00:00Z',
      });

      await v44Db.insert('orders', {
        'order_no': 'ORD-44-001',
        'customer_id': custId,
        'customer_phone': '9825901155',
        'customer_name': 'Existing VIP Customer',
        'grand_total_paise': 250000,
        'created_at': '2026-09-01T10:05:00Z',
      });

      await v44Db.insert('scheduler_tasks', {
        'title': 'Prep morning roses',
        'status': 'pending',
        'created_at': '2026-09-01T06:00:00Z',
      });

      await v44Db.insert('occasion_contacts', {
        'recipient_name': 'Ananya',
        'occasion': 'Birthday',
        'created_at': '2026-09-01T10:00:00Z',
      });

      await v44Db.close();

      // 2. Open at version 45 using migration upgrade logic
      final v45Db = await openDatabase(
        dbPath,
        version: 45,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 45) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS crm_enquiries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cloud_id TEXT,
                client_sync_id TEXT NOT NULL UNIQUE,
                customer_id INTEGER NOT NULL,
                cloud_customer_id TEXT,
                customer_name TEXT NOT NULL,
                customer_phone TEXT NOT NULL,
                category TEXT NOT NULL DEFAULT 'General',
                requirement TEXT NOT NULL,
                event_date TEXT,
                budget_paise INTEGER,
                location TEXT,
                notes TEXT,
                status TEXT NOT NULL DEFAULT 'new',
                next_action TEXT,
                next_follow_up_at TEXT,
                quote_order_id INTEGER,
                converted_order_id INTEGER,
                lost_reason TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                deleted_at TEXT,
                FOREIGN KEY(customer_id) REFERENCES customers(id)
              )
            ''');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_customer_id ON crm_enquiries(customer_id)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_status ON crm_enquiries(status)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_event_date ON crm_enquiries(event_date)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_next_follow_up ON crm_enquiries(next_follow_up_at)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_created_at ON crm_enquiries(created_at)');
            await db.execute('CREATE INDEX IF NOT EXISTS idx_crm_enquiries_client_sync_id ON crm_enquiries(client_sync_id)');
          }
        },
      );

      // Verify existing records intact
      final customers = await v45Db.query('customers');
      expect(customers.length, 1);
      expect(customers.first['name'], 'Existing VIP Customer');

      final orders = await v45Db.query('orders');
      expect(orders.length, 1);
      expect(orders.first['order_no'], 'ORD-44-001');

      final tasks = await v45Db.query('scheduler_tasks');
      expect(tasks.length, 1);
      expect(tasks.first['title'], 'Prep morning roses');

      final occasions = await v45Db.query('occasion_contacts');
      expect(occasions.length, 1);
      expect(occasions.first['recipient_name'], 'Ananya');

      // Verify crm_enquiries table exists and writable
      final tables = await v45Db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='crm_enquiries'");
      expect(tables.length, 1);

      // Verify indexes exist
      final indexes = await v45Db.rawQuery("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='crm_enquiries'");
      final indexNames = indexes.map((r) => r['name'] as String).toList();
      expect(indexNames, contains('idx_crm_enquiries_customer_id'));
      expect(indexNames, contains('idx_crm_enquiries_status'));
      expect(indexNames, contains('idx_crm_enquiries_event_date'));
      expect(indexNames, contains('idx_crm_enquiries_next_follow_up'));
      expect(indexNames, contains('idx_crm_enquiries_created_at'));
      expect(indexNames, contains('idx_crm_enquiries_client_sync_id'));

      // Verify insert enquiry referencing existing customer
      final enqId = await v45Db.insert('crm_enquiries', {
        'client_sync_id': 'sync-mig-1',
        'customer_id': custId,
        'customer_name': 'Existing VIP Customer',
        'customer_phone': '9825901155',
        'category': 'Flowers',
        'requirement': 'Roses',
        'created_at': '2026-09-28T12:00:00Z',
        'updated_at': '2026-09-28T12:00:00Z',
      });
      expect(enqId, 1);

      await v45Db.close();
    });
  });
}

