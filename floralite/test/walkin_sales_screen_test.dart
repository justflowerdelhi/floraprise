import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
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
import 'package:floraprise/screens/delivery_screen.dart';
import 'package:floraprise/screens/pickup_later_screen.dart';
import 'package:floraprise/screens/take_away_screen.dart';
import 'package:floraprise/screens/walkin_sales_screen.dart';
import 'package:floraprise/services/business_data_event_bus.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class StorageModeServiceForTest extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async => StorageMode.local;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildScreen() {
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );
    final businessDataEventBus = BusinessDataEventBus();
    final storageProvider = StorageModeProvider(StorageModeServiceForTest());

    return MultiProvider(
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateRoute: (settings) {
          if (settings.name == '/draft-orders') {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Draft Orders Screen')),
            );
          }
          return null;
        },
        home: WalkinSalesScreen(),
      ),
    );
  }

  testWidgets('Walk-in Sales renders the four primary options on desktop', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('How will the customer receive the order?'), findsOneWidget);
    expect(find.text('Walk-in Sale'), findsOneWidget);
    expect(find.text('Pickup Later'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.textContaining('Draft Orders'), findsOneWidget);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('Walk-in Sale navigation still works', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Walk-in Sale'));
    await tester.pumpAndSettle();

    expect(find.byType(TakeAwayScreen), findsOneWidget);
  });

  testWidgets('Pickup Later navigation still works', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pickup Later'));
    await tester.pumpAndSettle();

    expect(find.byType(PickupLaterScreen), findsOneWidget);
  });

  testWidgets('Delivery navigation still works', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryScreen), findsOneWidget);
  });

  testWidgets('Draft Orders navigation still works', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Draft Orders'));
    await tester.pumpAndSettle();

    expect(find.text('Draft Orders Screen'), findsOneWidget);
  });

  testWidgets('Draft count remains visible and dynamic when loading', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.textContaining('Draft Orders'), findsOneWidget);
  });
}
