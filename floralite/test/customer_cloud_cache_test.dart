import 'dart:io';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const companyOne = '11111111-1111-4111-8111-111111111111';
const companyTwo = '22222222-2222-4222-8222-222222222222';
const cloudCustomerA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const cloudCustomerB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const cloudCustomerC = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTests = true;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
    AppDatabase.testDatabaseName = null;
    AppDatabase.useInMemoryForTests = false;
  });

  group('Customer Cloud & Cache Migration', () {
    test('database contains cloud columns and indexes on customers and orders', () async {
      final db = await AppDatabase.instance.database;
      final customerCols = await db.rawQuery('PRAGMA table_info(customers)');
      final orderCols = await db.rawQuery('PRAGMA table_info(orders)');

      final customerCloudIdCol = customerCols.singleWhere(
        (row) => row['name'] == 'cloud_customer_id',
      );
      final customerCompanyIdCol = customerCols.singleWhere(
        (row) => row['name'] == 'cloud_company_id',
      );
      final orderCloudIdCol = orderCols.singleWhere(
        (row) => row['name'] == 'cloud_customer_id',
      );

      expect(customerCloudIdCol['type'], 'TEXT');
      expect(customerCloudIdCol['notnull'], 0);
      expect(customerCompanyIdCol['type'], 'TEXT');
      expect(customerCompanyIdCol['notnull'], 0);
      expect(orderCloudIdCol['type'], 'TEXT');
      expect(orderCloudIdCol['notnull'], 0);

      final customerIndexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'customers'",
      );
      final indexNames = customerIndexes.map((r) => r['name']).toSet();
      expect(indexNames, contains('idx_customers_cloud_customer_id_unique'));
      expect(indexNames, contains('idx_customers_cloud_company_id'));

      final orderIndexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'orders'",
      );
      final orderIndexNames = orderIndexes.map((r) => r['name']).toSet();
      expect(orderIndexNames, contains('idx_orders_cloud_customer_id'));
    });

    test('onOpen migration adds columns to existing database without data loss', () async {
      AppDatabase.useInMemoryForTests = false;
      AppDatabase.testDatabaseName =
          'migration_test_${DateTime.now().microsecondsSinceEpoch}.db';

      final dbPath = path.join(
        await getDatabasesPath(),
        AppDatabase.testDatabaseName!,
      );

      await AppDatabase.instance.database;
      final repo = CustomerRepository();

      // Insert a local customer without cloud fields
      final created = await repo.create(
        phone: '9876543210',
        name: 'Existing Customer',
        birthdayMd: '05-12',
        notes: 'Pre-migration notes',
      );
      expect(created.id, isPositive);
      expect(created.cloudCustomerId, isNull);
      expect(created.cloudCompanyId, isNull);

      // Close and reopen to verify onOpen ensures columns and keeps data intact
      await AppDatabase.instance.close();
      await AppDatabase.instance.database;
      final reloaded = await repo.getById(created.id);

      expect(reloaded, isNotNull);
      expect(reloaded!.name, 'Existing Customer');
      expect(reloaded.phone, '9876543210');
      expect(reloaded.birthdayMd, '05-12');
      expect(reloaded.notes, 'Pre-migration notes');
      expect(reloaded.cloudCustomerId, isNull);
      expect(reloaded.cloudCompanyId, isNull);

      // Cleanup disk database file
      await AppDatabase.instance.close();
      if (File(dbPath).existsSync()) {
        File(dbPath).deleteSync();
      }
    });
  });

  group('CustomerRepository Upsert & Cache', () {
    test('upsertFromCloud creates new cached customer when neither cloudId nor phone exists', () async {
      final repo = CustomerRepository();

      final record = await repo.upsertFromCloud(
        cloudCustomerId: cloudCustomerA,
        cloudCompanyId: companyOne,
        phone: '9876500001',
        name: 'Alice Smith',
        birthdayMd: '03-15',
        company: 'Flower Co',
        notes: 'VIP customer',
      );

      expect(record.id, isPositive);
      expect(record.name, 'Alice Smith');
      expect(record.phone, '9876500001');
      expect(record.cloudCustomerId, cloudCustomerA);
      expect(record.cloudCompanyId, companyOne);
      expect(record.birthdayMd, '03-15');
      expect(record.company, 'Flower Co');
      expect(record.notes, 'VIP customer');

      final fetched = await repo.findByCloudId(cloudCustomerA);
      expect(fetched, isNotNull);
      expect(fetched!.id, record.id);
      expect(fetched.cloudCustomerId, cloudCustomerA);
    });

    test('upsertFromCloud updates existing customer when cloudCustomerId matches', () async {
      final repo = CustomerRepository();

      final initial = await repo.upsertFromCloud(
        cloudCustomerId: cloudCustomerA,
        cloudCompanyId: companyOne,
        phone: '9876500001',
        name: 'Alice Smith',
        notes: 'Original note',
      );

      final updated = await repo.upsertFromCloud(
        cloudCustomerId: cloudCustomerA,
        cloudCompanyId: companyOne,
        phone: '9876500001',
        name: 'Alice Johnson',
        notes: 'Updated note',
      );

      expect(updated.id, initial.id);
      expect(updated.name, 'Alice Johnson');
      expect(updated.notes, 'Updated note');
      expect(updated.cloudCustomerId, cloudCustomerA);

      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('upsertFromCloud links existing local customer when phone matches', () async {
      final repo = CustomerRepository();

      // Customer created locally without cloud link
      final local = await repo.create(
        phone: '9876500002',
        name: 'Bob Local',
        birthdayMd: '08-20',
      );
      expect(local.cloudCustomerId, isNull);

      // Cloud customer sync with matching phone should link to existing record
      final linked = await repo.upsertFromCloud(
        cloudCustomerId: cloudCustomerB,
        cloudCompanyId: companyOne,
        phone: '9876500002',
        name: 'Bob Linked',
      );

      expect(linked.id, local.id);
      expect(linked.cloudCustomerId, cloudCustomerB);
      expect(linked.cloudCompanyId, companyOne);
      expect(linked.name, 'Bob Linked');
      expect(linked.birthdayMd, '08-20');

      final all = await repo.getAll();
      expect(all.length, 1);
    });

    test('upsertFromCloud does not relink a phone owned by another company', () async {
      final repo = CustomerRepository();

      // Company One already owns this phone via a prior Cloud sync.
      final ownedByCompanyOne = await repo.upsertFromCloud(
        cloudCustomerId: cloudCustomerA,
        cloudCompanyId: companyOne,
        phone: '9876500009',
        name: 'Tenant One Owner',
      );

      // Company Two's Cloud sync sees the same phone number.
      await expectLater(
        () => repo.upsertFromCloud(
          cloudCustomerId: cloudCustomerB,
          cloudCompanyId: companyTwo,
          phone: '9876500009',
          name: 'Tenant Two Claimant',
        ),
        throwsArgumentError,
      );

      // Company One's record must be untouched, and no cross-tenant link created.
      final unchanged = await repo.getById(ownedByCompanyOne.id);
      expect(unchanged!.name, 'Tenant One Owner');
      expect(unchanged.cloudCompanyId, companyOne);
      expect(await repo.findByCloudId(cloudCustomerB), isNull);
    });

    test('upsertFromCloud throws ArgumentError on empty cloud IDs', () async {
      final repo = CustomerRepository();

      expect(
        () => repo.upsertFromCloud(
          cloudCustomerId: '',
          cloudCompanyId: companyOne,
          phone: '9876500003',
          name: 'Invalid',
        ),
        throwsArgumentError,
      );

      expect(
        () => repo.upsertFromCloud(
          cloudCustomerId: cloudCustomerA,
          cloudCompanyId: '',
          phone: '9876500003',
          name: 'Invalid',
        ),
        throwsArgumentError,
      );
    });
  });

  group('CustomerRepository Update & Linking', () {
    test('update allows modifying cloudCustomerId and cloudCompanyId', () async {
      final repo = CustomerRepository();

      final record = await repo.create(
        phone: '9876500004',
        name: 'Charlie',
      );
      expect(record.cloudCustomerId, isNull);

      final updated = await repo.update(
        id: record.id,
        phone: '9876500004',
        name: 'Charlie Updated',
        cloudCustomerId: cloudCustomerC,
        cloudCompanyId: companyOne,
      );

      expect(updated.id, record.id);
      expect(updated.name, 'Charlie Updated');
      expect(updated.cloudCustomerId, cloudCustomerC);
      expect(updated.cloudCompanyId, companyOne);
    });

    test('setCloudCustomerId links existing customer', () async {
      final repo = CustomerRepository();

      final record = await repo.create(
        phone: '9876500005',
        name: 'David',
      );

      await repo.setCloudCustomerId(record.id, cloudCustomerA, companyOne);

      final fetched = await repo.getById(record.id);
      expect(fetched!.cloudCustomerId, cloudCustomerA);
      expect(fetched.cloudCompanyId, companyOne);
    });
  });

  group('Tenant Isolation for Cached Customers', () {
    late CustomerRepository repo;

    setUp(() async {
      repo = CustomerRepository();
      // Company 1 customers
      await repo.upsertFromCloud(
        cloudCustomerId: 'c-101',
        cloudCompanyId: companyOne,
        phone: '9111111111',
        name: 'Tenant One Alpha',
        birthdayMd: CustomerRepository.todayMonthDay(),
      );
      await repo.upsertFromCloud(
        cloudCustomerId: 'c-102',
        cloudCompanyId: companyOne,
        phone: '9111111112',
        name: 'Tenant One Beta',
      );

      // Company 2 customer
      await repo.upsertFromCloud(
        cloudCustomerId: 'c-201',
        cloudCompanyId: companyTwo,
        phone: '9222222221',
        name: 'Tenant Two Gamma',
        birthdayMd: CustomerRepository.todayMonthDay(),
      );

      // Unassigned local customer
      await repo.create(
        phone: '9333333331',
        name: 'Local Unassigned',
        birthdayMd: CustomerRepository.todayMonthDay(),
      );
    });

    test('getAll without companyId returns all non-deleted customers (preserves local behavior)', () async {
      final all = await repo.getAll();
      expect(all.length, 4);
    });

    test('getAll with companyId returns only that tenant customers', () async {
      final companyOneList = await repo.getAll(companyId: companyOne);
      expect(companyOneList.length, 2);
      expect(
        companyOneList.every((c) => c.cloudCompanyId == companyOne),
        isTrue,
      );

      final companyTwoList = await repo.getAll(companyId: companyTwo);
      expect(companyTwoList.length, 1);
      expect(companyTwoList.first.name, 'Tenant Two Gamma');
    });

    test('getAll with companyId and includeUnassigned returns tenant plus unassigned customers', () async {
      final list = await repo.getAll(
        companyId: companyOne,
        includeUnassigned: true,
      );
      expect(list.length, 3);
      final names = list.map((c) => c.name).toSet();
      expect(names, contains('Tenant One Alpha'));
      expect(names, contains('Tenant One Beta'));
      expect(names, contains('Local Unassigned'));
      expect(names, isNot(contains('Tenant Two Gamma')));
    });

    test('search filters by tenant', () async {
      final resultsComp1 = await repo.search('Tenant', companyId: companyOne);
      expect(resultsComp1.length, 2);
      expect(
        resultsComp1.map((c) => c.name).toSet(),
        {'Tenant One Alpha', 'Tenant One Beta'},
      );

      final resultsComp2 = await repo.search('Tenant', companyId: companyTwo);
      expect(resultsComp2.length, 1);
      expect(resultsComp2.first.name, 'Tenant Two Gamma');

      final resultsAll = await repo.search('Tenant');
      expect(resultsAll.length, 3);
    });

    test('findByPhone isolates by tenant', () async {
      expect(
        await repo.findByPhone('9111111111', companyId: companyOne),
        isNotNull,
      );
      expect(
        await repo.findByPhone('9111111111', companyId: companyTwo),
        isNull,
      );
      // Without companyId, local lookup finds it
      expect(await repo.findByPhone('9111111111'), isNotNull);
    });

    test('findByCloudId isolates by tenant', () async {
      expect(
        await repo.findByCloudId('c-101', companyId: companyOne),
        isNotNull,
      );
      expect(
        await repo.findByCloudId('c-101', companyId: companyTwo),
        isNull,
      );
    });

    test('getTodayBirthdayCount isolates by tenant', () async {
      expect(await repo.getTodayBirthdayCount(companyId: companyOne), 1);
      expect(await repo.getTodayBirthdayCount(companyId: companyTwo), 1);
      expect(
        await repo.getTodayBirthdayCount(
          companyId: companyOne,
          includeUnassigned: true,
        ),
        2, // Alpha + Local Unassigned
      );
      expect(await repo.getTodayBirthdayCount(), 3); // All 3 birthdays
    });
  });
}
