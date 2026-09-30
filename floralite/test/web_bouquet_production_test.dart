import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/repositories/cloud_production_repository.dart';
import 'package:floraprise/models/printer_models.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/printer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/screens/bouquet_builder_screen.dart';
import 'package:floraprise/screens/bouquet_production_entry_screen.dart';
import 'package:floraprise/services/business_data_event_bus.dart';
import 'package:floraprise/services/printer/printer_manager.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeStorageModeService extends StorageModeService {
  final StorageMode _mode;
  _FakeStorageModeService(this._mode);

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;
  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;
  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;
  @override
  Future<bool> hasSelectedMode() async => true;
}

class _FakePrinterManager extends PrinterManager {
  @override
  bool get isConnected => false;
  @override
  Future<bool> refreshConnectionState() async => false;
  @override
  Future<List<PrinterDeviceInfo>> scanBluetoothPrinters({
    Duration timeout = const Duration(seconds: 6),
  }) async => const [];
  @override
  Future<List<PrintQueueJob>> listQueue() async => const [];
  @override
  Future<bool> hasLastSuccessfulReceipt() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Widget buildTestableWidget(Widget child, {CloudProductionSender? sender}) {
    final storageModeService = _FakeStorageModeService(StorageMode.cloud);
    final storageModeProvider = StorageModeProvider(storageModeService);
    final eventBus = BusinessDataEventBus();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageModeProvider>.value(
          value: storageModeProvider,
        ),
        ChangeNotifierProvider<BusinessDataEventBus>.value(
          value: eventBus,
        ),
        ChangeNotifierProvider<PrinterProvider>(
          create: (_) => PrinterProvider(_FakePrinterManager()),
        ),
      ],
      child: MaterialApp(
        home: child,
        routes: {
          '/ready-bouquets': (_) =>
              const Scaffold(body: Text('Ready Bouquets Screen')),
        },
      ),
    );
  }

  group('Bouquet Production Cloud & Web Widget Tests', () {
    testWidgets('BouquetProductionEntryScreen renders properly in Cloud mode',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(const BouquetProductionEntryScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ready Bouquet Production'), findsOneWidget);
      expect(find.text('What do you want to make?'), findsOneWidget);
      expect(find.text('New Bouquet'), findsOneWidget);
      expect(find.text('Select Existing Recipe'), findsOneWidget);
      expect(find.text('Use Library Recipe'), findsOneWidget);
    });

    testWidgets('BouquetBuilderScreen loads for new bouquet without DB errors',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(const BouquetBuilderScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('New Bouquet'), findsOneWidget);
      expect(find.text('Components'), findsOneWidget);
      expect(find.text('+ Add Item'), findsOneWidget);
      expect(find.text('Save as Recipe'), findsOneWidget);
      expect(find.text('Produce'), findsOneWidget);
      expect(find.text('How many bouquets?'), findsNothing);
    });
  });
}
