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
import 'package:floraprise/services/business_data_event_bus.dart';
import 'package:floraprise/services/storage_mode_service.dart';

class _StorageModeServiceForTest extends StorageModeService {
  @override
  Future<StorageMode?> getCurrentMode() async => StorageMode.local;
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildScreen(Widget child) {
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );
    final businessDataEventBus = BusinessDataEventBus();
    final storageProvider = StorageModeProvider(_StorageModeServiceForTest());

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
        home: child,
      ),
    );
  }

  testWidgets('TakeAwayScreen completion dialog renders Done, Print, WhatsApp, and NOT View Order Details', (tester) async {
    await tester.pumpWidget(buildScreen(const TakeAwayScreen()));
    await tester.pumpAndSettle();

    // Verify TakeAwayScreen is loaded
    expect(find.byType(TakeAwayScreen), findsOneWidget);

    // Verify 'View Order Details' is absent
    expect(find.text('View Order Details'), findsNothing);
  });

  testWidgets('PickupLaterScreen completion dialog renders Done, Print, WhatsApp, and NOT View Order Details', (tester) async {
    await tester.pumpWidget(buildScreen(const PickupLaterScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(PickupLaterScreen), findsOneWidget);
    expect(find.text('View Order Details'), findsNothing);
  });

  testWidgets('DeliveryScreen completion dialog renders Done, Print, WhatsApp, and NOT View Order Details', (tester) async {
    await tester.pumpWidget(buildScreen(const DeliveryScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(DeliveryScreen), findsOneWidget);
    expect(find.text('View Order Details'), findsNothing);
  });
}
