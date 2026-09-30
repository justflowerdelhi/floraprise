import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_customer_repository.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/providers/customer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/customer_cloud_lookup_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/widgets/customer_name_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const testCompanyId = '11111111-1111-4111-8111-111111111111';

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

  group('CustomerCloudLookupService search & bidirectional lookup', () {
    test('Solo mode: searches local SQLite customers by name or phone offline', () async {
      final repo = CustomerRepository();
      await repo.create(phone: '9990012345', name: 'Rahul Sharma');
      await repo.create(phone: '9880054321', name: 'Priya Patel');

      final service = CustomerCloudLookupService(
        customerRepository: repo,
        isOnline: () async => false,
      );

      final byName = await service.search('Rahul', isCloud: false);
      expect(byName.length, 1);
      expect(byName.first.name, 'Rahul Sharma');
      expect(byName.first.phone, '9990012345');

      final byPhone = await service.search('98800', isCloud: false);
      expect(byPhone.length, 1);
      expect(byPhone.first.name, 'Priya Patel');
    });

    test('Cloud mode: returns cached tenant customers when offline', () async {
      final repo = CustomerRepository();
      await repo.upsertFromCloud(
        cloudCustomerId: 'c-101',
        cloudCompanyId: testCompanyId,
        phone: '9990012345',
        name: 'Rahul Cloud',
      );

      final service = CustomerCloudLookupService(
        customerRepository: repo,
        currentCompanyId: () async => testCompanyId,
        isOnline: () async => false,
      );

      final results = await service.search('Rahul', isCloud: true);
      expect(results.length, 1);
      expect(results.first.name, 'Rahul Cloud');
      expect(results.first.phone, '9990012345');
    });

    test('Cloud mode: fetches from Cloud and caches locally when online', () async {
      final repo = CustomerRepository();
      var cloudCalled = false;

      final service = CustomerCloudLookupService(
        customerRepository: repo,
        currentCompanyId: () async => testCompanyId,
        isOnline: () async => true,
        cloudSearcher: ({String? query}) async {
          cloudCalled = true;
          return const [
            CloudCustomer(
              id: 'c-202',
              name: 'Ananya Roy',
              phone: '9770011223',
            ),
          ];
        },
      );

      final results = await service.search('Ananya', isCloud: true);
      expect(cloudCalled, isTrue);
      expect(results.length, 1);
      expect(results.first.name, 'Ananya Roy');
      expect(results.first.phone, '9770011223');

      // Verify cached in SQLite
      final local = await repo.findByPhone('9770011223', companyId: testCompanyId);
      expect(local, isNotNull);
      expect(local!.name, 'Ananya Roy');
    });
  });

  group('CustomerNameAutocomplete Widget Tests', () {
    testWidgets('shows suggestions with Name and Phone on typing >= 2 chars', (tester) async {
      final repo = CustomerRepository();
      await tester.runAsync(() async {
        await repo.create(phone: '9990012345', name: 'Rahul Sharma');
        await repo.create(phone: '9990055555', name: 'Rahul Verma');
        await repo.create(phone: '9880011111', name: 'Pooja Singh');
      });

      final customerManager = CustomerManager(repo);
      final storageModeProvider = StorageModeProvider(StorageModeService());
      final customerProvider = CustomerProvider(customerManager, storageModeProvider);

      final controller = TextEditingController();
      CustomerRecord? selectedCustomer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CustomerProvider>.value(
              value: customerProvider,
              child: CustomerNameAutocomplete(
                controller: controller,
                labelText: 'Customer Name',
                debounceDuration: Duration.zero,
                onCustomerSelected: (customer) {
                  selectedCustomer = customer;
                },
              ),
            ),
          ),
        ),
      );

      // Typing 1 char does NOT show suggestions
      await tester.enterText(find.byType(TextField), 'R');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      expect(find.text('Rahul Sharma'), findsNothing);

      // Typing >= 2 chars shows suggestions
      await tester.enterText(find.byType(TextField), 'Rah');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('9990012345'), findsOneWidget);
      expect(find.text('Rahul Verma'), findsOneWidget);
      expect(find.text('9990055555'), findsOneWidget);
      expect(find.text('Pooja Singh'), findsNothing);

      // Tapping a suggestion selects it
      await tester.tap(find.text('Rahul Sharma'));
      await tester.pump();

      expect(selectedCustomer, isNotNull);
      expect(selectedCustomer!.name, 'Rahul Sharma');
      expect(selectedCustomer!.phone, '9990012345');
      expect(controller.text, 'Rahul Sharma');
    });

    testWidgets('does not auto-select ambiguous partial matches', (tester) async {
      final repo = CustomerRepository();
      await tester.runAsync(() async {
        await repo.create(phone: '9990012345', name: 'Amit Kumar');
        await repo.create(phone: '9990098765', name: 'Amit Shah');
      });

      final customerManager = CustomerManager(repo);
      final storageModeProvider = StorageModeProvider(StorageModeService());
      final customerProvider = CustomerProvider(customerManager, storageModeProvider);

      final controller = TextEditingController();
      CustomerRecord? selectedCustomer;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CustomerProvider>.value(
              value: customerProvider,
              child: CustomerNameAutocomplete(
                controller: controller,
                labelText: 'Customer Name',
                debounceDuration: Duration.zero,
                onCustomerSelected: (customer) {
                  selectedCustomer = customer;
                },
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Amit');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();

      // Suggestions are shown, but no automatic selection happened
      expect(selectedCustomer, isNull);
      expect(find.text('Amit Kumar'), findsOneWidget);
      expect(find.text('Amit Shah'), findsOneWidget);
    });
  });
}
