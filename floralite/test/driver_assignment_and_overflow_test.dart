import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/data/repositories/staff_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/providers/walk_in_session_provider.dart';
import 'package:floraprise/screens/walkin_sales_screen.dart';
import 'package:floraprise/services/business_data_event_bus.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:floraprise/data/database/app_database.dart';

class _StorageModeServiceForTest extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async => StorageMode.local;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await AppDatabase.instance.close();
  });

  group('StaffRepository Driver and Designer Role Filtering Tests', () {
    test('searchStaff identifies staff with delivery role and can_deliver flag', () async {
      final repo = StaffRepository();
      final db = await AppDatabase.instance.database;
      await db.delete('staff');

      // 1. Primary delivery role
      await repo.create(
        const StaffUpsertInput(
          name: 'Ramesh Driver',
          phone: '9876543210',
          sameAsPhone: true,
          role: StaffRole.delivery,
          active: true,
        ),
      );

      // 2. Helper role but can_deliver = true
      await repo.create(
        const StaffUpsertInput(
          name: 'Suresh Helper',
          phone: '9876543211',
          sameAsPhone: true,
          role: StaffRole.helper,
          canDeliver: true,
          active: true,
        ),
      );

      // 3. Manager role, no delivery
      await repo.create(
        const StaffUpsertInput(
          name: 'Vikas Manager',
          phone: '9876543212',
          sameAsPhone: true,
          role: StaffRole.manager,
          canDeliver: false,
          active: true,
        ),
      );

      final deliveryStaff = await repo.searchStaff(
        roles: [StaffRole.delivery],
        activeOnly: true,
      );

      expect(deliveryStaff.length, equals(2));
      final names = deliveryStaff.map((s) => s.name).toSet();
      expect(names, contains('Ramesh Driver'));
      expect(names, contains('Suresh Helper'));
      expect(names, isNot(contains('Vikas Manager')));
    });

    test('searchStaff identifies staff with designer role and can_design flag', () async {
      final repo = StaffRepository();
      final db = await AppDatabase.instance.database;
      await db.delete('staff');

      // 1. Primary designer role
      await repo.create(
        const StaffUpsertInput(
          name: 'Anita Designer',
          phone: '9876543220',
          sameAsPhone: true,
          role: StaffRole.designer,
          active: true,
        ),
      );

      // 2. Sales role with can_design = true
      await repo.create(
        const StaffUpsertInput(
          name: 'Pooja Sales',
          phone: '9876543221',
          sameAsPhone: true,
          role: StaffRole.sales,
          canDesign: true,
          active: true,
        ),
      );

      final designerStaff = await repo.searchStaff(
        roles: [StaffRole.designer],
        activeOnly: true,
      );

      expect(designerStaff.length, equals(2));
      final names = designerStaff.map((s) => s.name).toSet();
      expect(names, contains('Anita Designer'));
      expect(names, contains('Pooja Sales'));
    });
  });

  group('Solo Viewport Overflow Verification', () {
    testWidgets('WalkinSalesScreen renders without overflow on 320x640 viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final walkInManager = WalkInManager(
        customerManager: CustomerManager(CustomerRepository()),
        pricingManager: PricingManager(),
        orderManager: OrderManager(OrderRepository(), JobRepository()),
        inventoryManager: InventoryManager(InventoryRepository()),
        schedulerManager: SchedulerManager(SchedulerRepository()),
      );
      final businessDataEventBus = BusinessDataEventBus();
      final storageProvider = StorageModeProvider(_StorageModeServiceForTest());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: businessDataEventBus),
            ChangeNotifierProvider.value(value: storageProvider),
            ChangeNotifierProvider(
              create: (_) => WalkInSessionProvider(
                walkInManager,
                businessDataEventBus,
                storageProvider,
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: WalkinSalesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(WalkinSalesScreen), findsOneWidget);
    });

    testWidgets('DeliveryScreen unsaved dialog renders cleanly with action overflow spacing on narrow width', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Unsaved Changes'),
                      content: const Text('You have unsaved changes. What would you like to do?'),
                      actionsOverflowButtonSpacing: 8,
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Discard & Leave'),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Save as Draft'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Continue Editing'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Unsaved Changes'), findsOneWidget);
      expect(find.text('Discard & Leave'), findsOneWidget);
      expect(find.text('Save as Draft'), findsOneWidget);
      expect(find.text('Continue Editing'), findsOneWidget);
    });
  });
}
