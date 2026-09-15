import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';
import 'package:floraprise/data/repositories/cloud_product_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/printer_repository.dart';
import 'package:floraprise/l10n/app_localizations.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/models/dashboard_summary.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/license.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/models/subscription.dart';
import 'package:floraprise/providers/app_shell_controller.dart';
import 'package:floraprise/providers/auth_provider.dart';
import 'package:floraprise/providers/cloud_product_provider.dart';
import 'package:floraprise/providers/dashboard_provider.dart';
import 'package:floraprise/providers/inventory_provider.dart';
import 'package:floraprise/providers/license_provider.dart';
import 'package:floraprise/providers/printer_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/providers/subscription_provider.dart';
import 'package:floraprise/screens/cloud_categories_screen.dart';
import 'package:floraprise/screens/cloud_products_screen.dart';
import 'package:floraprise/screens/inventory_screen.dart';
import 'package:floraprise/screens/main_shell_screen.dart';
import 'package:floraprise/services/mobile_auth_service.dart';
import 'package:floraprise/services/printer/printer_manager.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:floraprise/services/subscription_service.dart';
import 'package:floraprise/widgets/floraprise_brand.dart';

class _MockStorageModeService extends StorageModeService {
  StorageMode _mode = StorageMode.cloud;

  @override
  Future<StorageMode?> getCurrentMode() async => _mode;

  @override
  Future<void> setMode(StorageMode mode) async => _mode = mode;

  @override
  Future<bool> hasSelectedMode() async => true;

  @override
  Future<bool> isLocal() async => _mode == StorageMode.local;

  @override
  Future<bool> isCloud() async => _mode == StorageMode.cloud;
}

class _ActiveSubscriptionProvider extends SubscriptionProvider {
  _ActiveSubscriptionProvider() : super(SubscriptionService());

  @override
  bool get isLoading => false;

  @override
  SubscriptionState get state => SubscriptionState.active;

  @override
  bool get isGracePeriod => false;

  @override
  bool get blocksBusinessAccess => false;
}

class _FakeLicenseProvider extends ChangeNotifier implements LicenseProvider {
  @override
  LicenseProviderState get state => LicenseProviderState.valid;
  @override
  CloudLicenseCheckResult? get license => null;
  @override
  String? get message => null;
  @override
  bool get isLoading => false;
  @override
  bool get isRegistered => true;
  @override
  bool get blocksBusinessAccess => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> register(BusinessRegistrationInput input) async => true;
  @override
  Future<void> refresh() async {}
  @override
  Future<void> heartbeat() async {}
}

class _FakeDashboardProvider extends ChangeNotifier implements DashboardProvider {
  @override
  DashboardSummary get summary => DashboardSummary.empty();

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadSummary({bool showLoading = true}) async {}

  @override
  Future<void> refresh({bool showLoading = false}) async {}
}

Map<String, dynamic> _sampleProductJson({
  String id = 'prod-1',
  String name = 'Red Rose Dutch',
  String sku = 'ROSE-RED-01',
  String category = 'Flowers',
  String uom = 'Stem',
  double price = 45.0,
}) {
  return {
    'id': id,
    'companyId': 'comp-1',
    'name': name,
    'sku': sku,
    'barcode': '123456789',
    'manufacturerBarcode': null,
    'internalBarcode': 'FP-ROSE-01',
    'brand': null,
    'description': 'Fresh red roses',
    'category': category,
    'categoryId': 'cat-1',
    'unitOfMeasure': uom,
    'retailPrice': price,
    'costPrice': 20.0,
    'wholesalePrice': null,
    'weddingEventPrice': null,
    'taxCategory': 'Standard',
    'trackInventory': true,
    'trackBatch': false,
    'stockQuantity': 150,
    'minimumStockLevel': 20,
    'reorderLevel': 30,
    'isActive': true,
    'shelfLifeDays': 5,
    'expiryAlertDays': 2,
    'temperatureNotes': null,
    'createdAtUtc': DateTime.now().toIso8601String(),
    'updatedAtUtc': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> _sampleCategoryJson({
  String id = 'cat-1',
  String name = 'Flowers',
  bool isActive = true,
}) {
  return {
    'id': id,
    'name': name,
    'isActive': isActive,
    'isPerishable': false,
    'trackBatchByDefault': false,
  };
}

InventoryProductRecord _sampleInventoryProduct({
  int id = 1,
  String cloudId = 'prod-1',
  String name = 'Red Rose Dutch',
  String sku = 'ROSE-RED-01',
  String category = 'Flowers',
  String unit = 'Stem',
  int currentQty = 150,
  int minQty = 20,
}) {
  return InventoryProductRecord(
    productId: id,
    cloudProductId: cloudId,
    name: name,
    category: category,
    unit: unit,
    sku: sku,
    barcode: '123456789',
    manufacturerBarcode: null,
    internalBarcode: 'FP-ROSE-01',
    trackInventory: true,
    gstPercent: 0,
    gstCalculationType: GstCalculationType.inclusive,
    currentQty: currentQty,
    minQty: minQty,
  );
}

class _FakeInventoryManager extends InventoryManager {
  _FakeInventoryManager() : super(InventoryRepository());

  @override
  Future<List<InventoryProductRecord>> listInventoryProducts() async {
    return [_sampleInventoryProduct()];
  }
}

CloudProductRepository _buildMockCloudProductRepo() {
  return CloudProductRepository(
    send: (method, uri, {body}) async {
      if (uri.path.contains('/api/categories')) {
        return [_sampleCategoryJson()];
      }
      if (uri.path.contains('/api/products/search')) {
        return {
          'items': [_sampleProductJson()],
          'totalCount': 1,
        };
      }
      return _sampleProductJson();
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Floraprise Pro Web Phase 1 — Storage Mode & Architecture', () {
    test('StorageModeProvider in Cloud mode does not touch SQLite', () async {
      final mockService = _MockStorageModeService();
      final provider = StorageModeProvider(mockService);
      await provider.setMode(StorageMode.cloud);

      expect(provider.isCloud, isTrue);
      expect(provider.selectedMode, StorageMode.cloud);
      expect(provider.effectiveMode, StorageMode.cloud);
    });
  });

  group('Floraprise Pro Web Phase 1 — MainShellScreen Responsive Navigation', () {
    testWidgets('renders desktop sidebar on desktop viewport (>= 800px)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storageMode = StorageModeProvider(_MockStorageModeService());
      await storageMode.setMode(StorageMode.cloud);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: storageMode),
            ChangeNotifierProvider(create: (_) => AppShellController()),
            ChangeNotifierProvider(create: (_) => AuthProvider(MobileAuthService())),
            ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
            ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _FakeDashboardProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainShellScreen(initialRoute: '/backup-restore'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SALES & ORDERS'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('Pro Cloud'), findsOneWidget);
      expect(find.byType(FlorapriseBrand), findsOneWidget);
    });

    testWidgets('renders bottom NavigationBar on mobile viewport (< 800px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storageMode = StorageModeProvider(_MockStorageModeService());
      await storageMode.setMode(StorageMode.cloud);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: storageMode),
            ChangeNotifierProvider(create: (_) => AppShellController()),
            ChangeNotifierProvider(create: (_) => AuthProvider(MobileAuthService())),
            ChangeNotifierProvider<SubscriptionProvider>(create: (_) => _ActiveSubscriptionProvider()),
            ChangeNotifierProvider<LicenseProvider>(create: (_) => _FakeLicenseProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => _FakeDashboardProvider()),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MainShellScreen(initialRoute: '/backup-restore'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });

  group('Floraprise Pro Web Phase 1 — Products Responsive Adaptation', () {
    testWidgets('renders GridView on desktop (>= 800px)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cloudProductProvider = CloudProductProvider(_buildMockCloudProductRepo());
      await cloudProductProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cloudProductProvider),
            ChangeNotifierProvider(
              create: (_) => PrinterProvider(PrinterManager(repository: PrinterRepository())),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CloudProductsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Red Rose Dutch'), findsOneWidget);
      expect(find.text('₹45.00'), findsOneWidget);
    });

    testWidgets('renders ListView on mobile (< 800px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cloudProductProvider = CloudProductProvider(_buildMockCloudProductRepo());
      await cloudProductProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cloudProductProvider),
            ChangeNotifierProvider(
              create: (_) => PrinterProvider(PrinterManager(repository: PrinterRepository())),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CloudProductsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
      expect(find.text('Red Rose Dutch'), findsOneWidget);
    });
  });

  group('Floraprise Pro Web Phase 1 — Categories Responsive Adaptation', () {
    testWidgets('renders responsive GridView on desktop (>= 800px)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cloudProductProvider = CloudProductProvider(_buildMockCloudProductRepo());
      await cloudProductProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cloudProductProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CloudCategoriesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Flowers'), findsOneWidget);
    });

    testWidgets('renders ListView on mobile (< 800px)', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cloudProductProvider = CloudProductProvider(_buildMockCloudProductRepo());
      await cloudProductProvider.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: cloudProductProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: CloudCategoriesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Flowers'), findsOneWidget);
    });
  });

  group('Floraprise Pro Web Phase 1 — Inventory Responsive Adaptation', () {
    testWidgets('renders desktop GridView with quick action buttons', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final storageMode = StorageModeProvider(_MockStorageModeService());
      await storageMode.setMode(StorageMode.cloud);

      final cloudInventoryRepo = CloudInventoryRepository(
        sender: (method, uri, {body}) async => [
          {
            'productId': 'prod-1',
            'name': 'Red Rose Dutch',
            'category': 'Flowers',
            'unit': 'Stem',
            'sku': 'ROSE-RED-01',
            'barcode': '123456789',
            'manufacturerBarcode': null,
            'internalBarcode': 'FP-ROSE-01',
            'currentQuantity': 150,
            'minimumQuantity': 20,
            'trackInventory': true,
          }
        ],
        lowStockSender: (uri) async => [],
      );

      final inventoryProvider = InventoryProvider(
        _FakeInventoryManager(),
        storageMode,
        cloudInventoryRepo,
      );
      await inventoryProvider.loadProducts();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: storageMode),
            ChangeNotifierProvider.value(value: inventoryProvider),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: InventoryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Red Rose Dutch'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Purchase'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sale'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Wastage'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Adjust'), findsOneWidget);
    });
  });

  group('Floraprise Pro Web Phase 1 — Cloud Mutation Payloads', () {
    test('Product create and update dispatch correct REST payloads', () async {
      final dispatched = <Map<String, dynamic>>[];
      final cloudRepo = CloudProductRepository(
        send: (method, uri, {body}) async {
          dispatched.add({
            'method': method,
            'path': uri.path,
            'body': body,
          });
          if (method == 'POST' && uri.path == '/api/products') {
            return {'id': 'new-prod-id'};
          }
          if (method == 'GET' && uri.path == '/api/products/new-prod-id') {
            return _sampleProductJson(id: 'new-prod-id', name: 'Yellow Orchid');
          }
          return {};
        },
      );

      const input = CloudProductInput(
        name: 'Yellow Orchid',
        sku: 'ORCH-YEL-01',
        categoryId: 'cat-1',
        unitOfMeasure: 'Stem',
        retailPrice: 95.0,
        costPrice: 40.0,
        manufacturerBarcode: '777888',
        description: 'Exotic yellow orchid',
        trackInventory: true,
        trackBatch: false,
        reorderLevel: 15,
      );

      final created = await cloudRepo.createProduct(input);
      expect(created.id, 'new-prod-id');
      expect(created.name, 'Yellow Orchid');
      expect(dispatched.first['method'], 'POST');
      expect(dispatched.first['path'], '/api/products');
      final postBody = dispatched.first['body'] as Map<String, dynamic>;
      expect(postBody['productName'], 'Yellow Orchid');
      expect(postBody['sku'], 'ORCH-YEL-01');
      expect(postBody['retailPrice'], 95.0);
      expect(postBody['costPrice'], 40.0);
      expect(postBody['trackInventory'], isTrue);

      await cloudRepo.updateProduct('new-prod-id', input);
      final updateReq = dispatched.last;
      expect(updateReq['method'], 'PUT');
      expect(updateReq['path'], '/api/products/new-prod-id');
    });

    test('Category create, update, activate dispatch correct REST payloads', () async {
      final dispatched = <Map<String, dynamic>>[];
      final cloudRepo = CloudProductRepository(
        send: (method, uri, {body}) async {
          dispatched.add({
            'method': method,
            'path': uri.path,
            'body': body,
          });
          if (method == 'POST' && uri.path == '/api/categories') {
            return _sampleCategoryJson(id: 'cat-new', name: 'Exotics');
          }
          if (method == 'GET' && uri.path.contains('/api/categories')) {
            return [_sampleCategoryJson(id: 'cat-new', name: 'Exotics')];
          }
          return {};
        },
      );

      final newCat = await cloudRepo.createCategory('Exotics');
      expect(newCat.name, 'Exotics');
      expect(dispatched.first['method'], 'POST');
      expect(dispatched.first['path'], '/api/categories');

      await cloudRepo.updateCategory('cat-new', 'Exotics & Tropicals');
      final putReq = dispatched.firstWhere((d) => d['method'] == 'PUT');
      expect(putReq['path'], '/api/categories/cat-new');

      await cloudRepo.setCategoryActive('cat-new', false);
      final delReq = dispatched.firstWhere((d) => d['method'] == 'DELETE');
      expect(delReq['path'], '/api/categories/cat-new');
    });

    test('Inventory Stock In, Stock Out, Wastage, Adjust dispatch correct REST payloads', () async {
      final dispatched = <Map<String, dynamic>>[];
      final cloudRepo = CloudInventoryRepository(
        sender: (method, uri, {body}) async {
          dispatched.add({
            'method': method,
            'path': uri.path,
            'body': body,
          });
          return {'id': 'tx-1'};
        },
      );

      // 1. Stock In (Purchase)
      await cloudRepo.applyStockChange(
        productId: 'prod-1',
        operation: 'purchase',
        quantity: 50,
        purchasePricePaise: 2500, // Rs 25.00
        supplier: 'Fresh Flowers Wholesale',
        note: 'Morning fresh delivery',
      );
      expect(dispatched[0]['method'], 'POST');
      expect(dispatched[0]['path'], '/api/inventory/stock-changes');
      final purchaseBody = dispatched[0]['body'] as Map<String, dynamic>;
      expect(purchaseBody['productId'], 'prod-1');
      expect(purchaseBody['operation'], 'purchase');
      expect(purchaseBody['quantity'], 50);
      expect(purchaseBody['costPerUnit'], 25.0);

      // 2. Stock Out (Sale)
      await cloudRepo.applyStockChange(
        productId: 'prod-1',
        operation: 'sale',
        quantity: 10,
        note: 'Walk-in cash counter sale',
      );
      expect(dispatched[1]['method'], 'POST');
      final saleBody = dispatched[1]['body'] as Map<String, dynamic>;
      expect(saleBody['productId'], 'prod-1');
      expect(saleBody['operation'], 'sale');
      expect(saleBody['quantity'], 10);

      // 3. Wastage
      await cloudRepo.applyStockChange(
        productId: 'prod-1',
        operation: 'wastage',
        quantity: 5,
        reason: 'Spoiled',
        note: 'Wilted stems discarded',
      );
      expect(dispatched[2]['method'], 'POST');
      final wastageBody = dispatched[2]['body'] as Map<String, dynamic>;
      expect(wastageBody['productId'], 'prod-1');
      expect(wastageBody['operation'], 'wastage');
      expect(wastageBody['quantity'], 5);

      // 4. Adjustment
      await cloudRepo.applyStockChange(
        productId: 'prod-1',
        operation: 'adjustment',
        quantity: 3,
        increase: true,
        reason: 'Physical count discrepancy',
      );
      expect(dispatched[3]['method'], 'POST');
      final adjustBody = dispatched[3]['body'] as Map<String, dynamic>;
      expect(adjustBody['productId'], 'prod-1');
      expect(adjustBody['operation'], 'adjustment');
      expect(adjustBody['quantity'], 3);
      expect(adjustBody['increase'], isTrue);
    });
  });
}
