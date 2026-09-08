import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_inventory_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/models/gst_calculation_type.dart';
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/providers/inventory_provider.dart';
import 'package:floraprise/providers/storage_mode_provider.dart';
import 'package:floraprise/services/storage_mode_service.dart';

Future<StorageModeProvider> _storageMode(StorageMode mode) async {
  final provider = StorageModeProvider(StorageModeService());
  await provider.setMode(mode);
  return provider;
}

class _FakeInventoryManager extends InventoryManager {
  _FakeInventoryManager() : super(InventoryRepository());

  int listCalls = 0;
  List<InventoryProductRecord> cannedProducts = [];

  @override
  Future<List<InventoryProductRecord>> listInventoryProducts() async {
    listCalls++;
    return cannedProducts;
  }
}

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
    AppDatabase.useInMemoryForTests = false;
  });

  test('Cloud mode loadLowStockProducts fetches from Cloud repository and maps', () async {
    final storage = await _storageMode(StorageMode.cloud);
    final localManager = _FakeInventoryManager();

    var cloudCalls = 0;
    final cloudRepo = CloudInventoryRepository(
      lowStockSender: (uri) async {
        cloudCalls++;
        expect(uri.path, '/api/v1/mobile/inventory/low-stock');
        return [
          {
            'productId': 'cloud-prod-1',
            'name': 'Cloud Rose',
            'sku': 'ROSE-CL-1',
            'currentQuantity': 2,
            'minimumQuantity': 5,
            'status': 'lowStock',
          },
          {
            'productId': 'cloud-prod-2',
            'name': 'Cloud Tulip',
            'sku': 'TULIP-CL-2',
            'currentQuantity': 0,
            'minimumQuantity': 3,
            'status': 'outOfStock',
          },
        ];
      },
    );

    final provider = InventoryProvider(localManager, storage, cloudRepo);

    final items = await provider.loadLowStockProducts();

    expect(localManager.listCalls, 0);
    expect(cloudCalls, 1);
    expect(items.length, 2);
    expect(items[0].cloudProductId, 'cloud-prod-1');
    expect(items[0].name, 'Cloud Rose');
    expect(items[0].currentQty, 2);
    expect(items[0].minQty, 5);

    expect(items[1].cloudProductId, 'cloud-prod-2');
    expect(items[1].name, 'Cloud Tulip');
    expect(items[1].currentQty, 0);
    expect(items[1].minQty, 3);

    expect(provider.lowStockCount, 1);
    expect(provider.outOfStockCount, 1);
  });

  test('Local mode remains unchanged and computes low stock from local manager products', () async {
    final storage = await _storageMode(StorageMode.local);
    final localManager = _FakeInventoryManager();
    localManager.cannedProducts = const [
      InventoryProductRecord(
        productId: 1,
        cloudProductId: null,
        name: 'Local Orchid',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'ORC-LOC',
        barcode: '',
        manufacturerBarcode: null,
        internalBarcode: null,
        trackInventory: true,
        gstPercent: 0,
        gstCalculationType: GstCalculationType.inclusive,
        currentQty: 1,
        minQty: 4,
      ),
      InventoryProductRecord(
        productId: 2,
        cloudProductId: null,
        name: 'Local Rose',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'ROSE-LOC',
        barcode: '',
        manufacturerBarcode: null,
        internalBarcode: null,
        trackInventory: true,
        gstPercent: 0,
        gstCalculationType: GstCalculationType.inclusive,
        currentQty: 0,
        minQty: 2,
      ),
      InventoryProductRecord(
        productId: 3,
        cloudProductId: null,
        name: 'Local Lily',
        category: 'Flowers',
        unit: 'Stem',
        sku: 'LILY-LOC',
        barcode: '',
        manufacturerBarcode: null,
        internalBarcode: null,
        trackInventory: true,
        gstPercent: 0,
        gstCalculationType: GstCalculationType.inclusive,
        currentQty: 10,
        minQty: 3,
      ),
    ];

    final cloudRepo = CloudInventoryRepository(
      lowStockSender: (uri) async {
        throw StateError('Cloud repository must not be called in local mode');
      },
    );

    final provider = InventoryProvider(localManager, storage, cloudRepo);
    await provider.loadProducts();

    expect(localManager.listCalls, 1);
    expect(provider.lowStockCount, 1);
    expect(provider.outOfStockCount, 1);

    final lowStockItems = await provider.loadLowStockProducts();
    expect(lowStockItems.length, 2);
    expect(lowStockItems.map((e) => e.name), containsAll(['Local Orchid', 'Local Rose']));
  });
}
