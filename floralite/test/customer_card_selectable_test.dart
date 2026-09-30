import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/customer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/screens/customer_profile_screen.dart';
import 'package:floraprise/screens/customers_screen.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class FakeStorageModeService extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async => StorageMode.local;
  @override
  Future<bool> isCloud() async => false;
}

class FakeCustomerRepository extends CustomerRepository {
  final List<CustomerRecord> _records = [
    const CustomerRecord(
      id: 1,
      name: 'Anand Kumar',
      phone: '9810392755',
      birthdayMd: '01-15',
      createdAt: '2026-09-01T10:00:00.000',
      totalOrders: 2,
      pendingPaymentPaise: 0,
    ),
  ];

  @override
  Future<List<CustomerRecord>> search(
    String query, {
    String? companyId,
    bool includeUnassigned = false,
    List<String>? purchasedCategories,
  }) async {
    return _records;
  }

  @override
  Future<List<CustomerRecord>> getAll({
    String? companyId,
    bool includeUnassigned = false,
  }) async =>
      _records;

  @override
  Future<CustomerRecord?> getById(int id) async =>
      _records.where((r) => r.id == id).firstOrNull;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
  });

  testWidgets('Customer Card renders Name and Phone as SelectableText while maintaining interactions', (tester) async {
    final customerRepo = FakeCustomerRepository();
    final customerManager = CustomerManager(customerRepo);
    final storageProvider = StorageModeProvider(FakeStorageModeService());
    await storageProvider.load();
    final customerProvider = CustomerProvider(customerManager, storageProvider);
    await customerProvider.loadCustomers();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageModeProvider>.value(value: storageProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CustomersScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify Customer Name is rendered as SelectableText
    final nameFinder = find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == 'Anand Kumar',
    );
    expect(nameFinder, findsOneWidget);

    final nameWidget = tester.widget<SelectableText>(nameFinder);
    expect(nameWidget.style?.fontWeight, FontWeight.bold);
    expect(nameWidget.style?.fontSize, 16);

    // 2. Verify Customer Phone is rendered as SelectableText
    final phoneFinder = find.byWidgetPredicate(
      (widget) => widget is SelectableText && widget.data == '9810392755',
    );
    expect(phoneFinder, findsOneWidget);

    final phoneWidget = tester.widget<SelectableText>(phoneFinder);
    expect(phoneWidget.style?.fontSize, 13);

    // 3. Verify three-dot menu button is present and functional
    final menuButton = find.byIcon(Icons.more_vert);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Edit Customer'), findsOneWidget);
    expect(find.text('Delete Customer'), findsOneWidget);

    // Dismiss menu
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 4. Verify tapping customer card navigates to CustomerProfileScreen
    final avatarFinder = find.text('A');
    expect(avatarFinder, findsOneWidget);
    await tester.tap(avatarFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CustomerProfileScreen), findsOneWidget);
  });
}
