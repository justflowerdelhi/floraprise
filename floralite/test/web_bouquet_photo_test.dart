import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:floraprise/data/repositories/cloud_production_repository.dart';
import 'package:floraprise/data/repositories/production_repository.dart';
import 'package:floraprise/models/printer_models.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/printer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/screens/bouquet_builder_screen.dart';
import 'package:floraprise/services/business_data_event_bus.dart';
import 'package:floraprise/services/design_image_helper.dart';
import 'package:floraprise/services/printer/printer_manager.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/widgets/safe_platform_image.dart';
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
  }) async =>
      const [];
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

  Widget buildTestableWidget(Widget child) {
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

  group('Web Bouquet Photo & SafePlatformImageView Tests', () {
    test('DesignImageHelper processes image bytes to valid data URI', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final jpgBytes = Uint8List.fromList(img.encodeJpg(image));

      final dataUri = DesignImageHelper.processBytesToDataUri(jpgBytes);
      expect(dataUri.startsWith('data:image/jpeg;base64,'), isTrue);

      final base64Part = dataUri.substring('data:image/jpeg;base64,'.length);
      final decodedBytes = base64Decode(base64Part);
      expect(decodedBytes.isNotEmpty, isTrue);
    });

    testWidgets('SafePlatformImageView renders data URI using Image.memory',
        (tester) async {
      final image = img.Image(width: 40, height: 40);
      img.fill(image, color: img.ColorRgb8(0, 255, 0));
      final jpgBytes = Uint8List.fromList(img.encodeJpg(image));
      final dataUri = 'data:image/jpeg;base64,${base64Encode(jpgBytes)}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafePlatformImageView(
              imagePath: dataUri,
              width: 88,
              height: 88,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('SafePlatformImageView renders fallback when imagePath is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafePlatformImageView(
              imagePath: '',
              width: 88,
              height: 88,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    });

    testWidgets('BouquetBuilderScreen renders Recipe Photo card with Capture Photo button',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestableWidget(const BouquetBuilderScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recipe Photo'), findsOneWidget);
      expect(find.text('Capture Photo'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });

    test('CloudProductionRepository preserves sampleImages data URI in save recipe payload',
        () async {
      Map<String, dynamic>? capturedPayload;
      Future<dynamic> sender(
        String method,
        Uri uri, {
        Map<String, dynamic>? body,
      }) async {
        if (uri.path.contains('/recipes') && method == 'POST') {
          capturedPayload = body;
          return {
            'id': '7001',
            'productId': 'prod-7001',
            'productName': 'Rose Basket',
            'category': 'Bouquet',
            'components': [],
          };
        }
        return {};
      }

      final repo = CloudProductionRepository(sender: sender);
      const testDataUri = 'data:image/jpeg;base64,samplebase64data';

      await repo.saveBouquetRecipe(
        productName: 'Rose Basket',
        category: 'Bouquet',
        items: [
          const RecipeItem(
            rawProductId: 1,
            productName: 'Red Roses',
            unit: 'Stem',
            quantity: 12,
            currentQty: 50,
            purchasePricePaise: 1000,
          ),
        ],
        sellingPricePaise: 150000,
        labourCostPaise: 5000,
        shelfLifeDays: 3,
        refreshAfterDays: 2,
        imagePath: testDataUri,
      );

      expect(capturedPayload, isNotNull);
      final sampleImages = capturedPayload!['sampleImages'] as List<dynamic>?;
      expect(sampleImages, isNotNull);
      expect(sampleImages!.first, testDataUri);
    });

    testWidgets('SafePlatformImageView gracefully handles local file path without crashing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafePlatformImageView(
              imagePath: '/data/user/0/com.floraprise/cache/sample.jpg',
              width: 88,
              height: 88,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In test / web environment, local file path falls back or renders safely without throwing assertion
      expect(find.byType(SafePlatformImageView), findsOneWidget);
    });

    test('CloudProductionRepository getRecipeDetail retrieves imagePath from sampleImages',
        () async {
      const testDataUri = 'data:image/jpeg;base64,samplebase64data';
      Future<dynamic> sender(
        String method,
        Uri uri, {
        Map<String, dynamic>? body,
      }) async {
        if (uri.path.contains('/recipes/') && method == 'GET') {
          return {
            'id': '7001',
            'name': 'Rose Basket',
            'category': 'Bouquet',
            'sampleImages': [testDataUri],
            'components': [],
          };
        }
        return {};
      }

      final repo = CloudProductionRepository(sender: sender);
      final detail = await repo.getRecipeDetail(7001);

      expect(detail, isNotNull);
      expect(detail!.imagePath, testDataUri);
    });
  });
}
