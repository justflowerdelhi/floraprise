import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/cloud_order_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/product_repository.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/order_status.dart';
import 'package:floraprise/models/order_workspace_models.dart';
import 'package:floraprise/models/walk_in_enums.dart' hide OrderStatus;
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/widgets/product_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  group('Phase 2A: Event Inventory Reservation / Hold Architecture Tests', () {
    test('1. Database schema v46 contains inventory_reservations table with proper columns', () async {
      final db = await AppDatabase.instance.database;
      final version = await db.getVersion();
      expect(version, 46);

      final tableInfo = await db.rawQuery("PRAGMA table_info('inventory_reservations')");
      final columnNames = tableInfo.map((row) => row['name'] as String).toSet();

      expect(columnNames.contains('id'), isTrue);
      expect(columnNames.contains('order_id'), isTrue);
      expect(columnNames.contains('order_line_id'), isTrue);
      expect(columnNames.contains('product_id'), isTrue);
      expect(columnNames.contains('cloud_product_id'), isTrue);
      expect(columnNames.contains('quantity'), isTrue);
      expect(columnNames.contains('status'), isTrue);
      expect(columnNames.contains('event_date'), isTrue);
      expect(columnNames.contains('event_name'), isTrue);
      expect(columnNames.contains('notes'), isTrue);
      expect(columnNames.contains('created_at'), isTrue);
      expect(columnNames.contains('updated_at'), isTrue);
      expect(columnNames.contains('released_at'), isTrue);
      expect(columnNames.contains('consumed_at'), isTrue);
    });

    test('2. Event booking does NOT deduct physical inventory at booking/confirmation time', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      // Setup product with 10 stems in stock
      final productId = await db.insert('products', {
        'name': 'White Asiatic Lily Stem',
        'category': 'Flowers',
        'selling_price_paise': 8000,
        'purchase_price_paise': 4000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 10,
        'min_qty': 2,
        'updated_at': nowStr,
      });

      // Customer
      final customerId = await db.insert('customers', {
        'name': 'Grand Hotel Reception',
        'phone': '9876543210',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Create draft event order requiring 25 stems (more than today's stock of 10!)
      final draftId = await db.insert('orders', {
        'order_no': 'EVT-RES-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'subtotal_paise': 200000,
        'grand_total_paise': 200000,
        'is_paid': 0,
        'occasion': 'Wedding Reception',
        'scheduled_at': '2026-10-25T18:00:00.000',
        'delivery_address': 'Grand Ballroom',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'White Asiatic Lily Stem',
        'qty': 25,
        'unit_price_paise': 8000,
        'gst_percent': 0,
        'line_subtotal_paise': 200000,
        'line_gst_paise': 0,
        'line_total_paise': 200000,
        'source': 'product',
      });

      // Confirm order draft
      final orderRepo = OrderRepository();
      await orderRepo.confirmDraft(orderId: draftId);

      // Core rule assertion: Booking does NOT consume physical inventory
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 10, reason: 'Physical stock must remain 10 after event booking');

      final orderRow = await db.query('orders', where: 'id = ?', whereArgs: [draftId]);
      expect(orderRow.first['status'], 'confirmed');
    });

    test('3. Available-to-Sell formula correctly subtracts active reservations from physical stock', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      // Product with 20 units physical stock
      final productId = await db.insert('products', {
        'name': 'Orchid Stem Purple',
        'category': 'Exotic',
        'selling_price_paise': 12000,
        'purchase_price_paise': 6000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 20,
        'min_qty': 5,
        'updated_at': nowStr,
      });

      final inventoryRepo = InventoryRepository();
      final productRepo = ProductRepository();

      // Before reservation: Available to sell == 20, reserved == 0
      var prods = await productRepo.listActiveProductsWithInventory();
      var orchid = prods.firstWhere((p) => p.id == productId);
      expect(orchid.currentQty, 20);
      expect(orchid.reservedQty, 0);
      expect(orchid.availableToSell, 20);

      // Reserve 8 stems for Event A
      final resId1 = await inventoryRepo.reserveStock(
        orderId: 101,
        productId: productId,
        quantity: 8,
        eventDate: '2026-10-15',
        eventName: 'Anniversary Dinner',
        notes: 'Hold 8 orchids',
      );
      expect(resId1, greaterThan(0));

      // Check Available-to-Sell: 20 - 8 = 12
      prods = await productRepo.listActiveProductsWithInventory();
      orchid = prods.firstWhere((p) => p.id == productId);
      expect(orchid.currentQty, 20, reason: 'Physical stock must remain 20');
      expect(orchid.reservedQty, 8, reason: 'Reserved quantity must be 8');
      expect(orchid.availableToSell, 12, reason: 'Available to sell must be 12');

      // Reserve another 7 stems for Event B
      final resId2 = await inventoryRepo.reserveStock(
        orderId: 102,
        productId: productId,
        quantity: 7,
        eventDate: '2026-10-20',
        eventName: 'Corporate Gala',
      );
      expect(resId2, greaterThan(0));

      // Check Available-to-Sell: 20 - (8 + 7) = 5
      prods = await productRepo.listActiveProductsWithInventory();
      orchid = prods.firstWhere((p) => p.id == productId);
      expect(orchid.currentQty, 20);
      expect(orchid.reservedQty, 15);
      expect(orchid.availableToSell, 5);

      // Reserve remaining 5 stems for Event C
      await inventoryRepo.reserveStock(
        orderId: 103,
        productId: productId,
        quantity: 5,
        eventDate: '2026-10-22',
        eventName: 'Private Party',
      );

      // Check Available-to-Sell: 20 - 20 = 0
      prods = await productRepo.listActiveProductsWithInventory();
      orchid = prods.firstWhere((p) => p.id == productId);
      expect(orchid.currentQty, 20);
      expect(orchid.reservedQty, 20);
      expect(orchid.availableToSell, 0);
    });

    test('4. POS Product Picker availability helper behavior for normal POS vs Event POS', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Red Carnation Bundle',
        'category': 'Flowers',
        'selling_price_paise': 4000,
        'purchase_price_paise': 2000,
        'default_unit': 'Bundle',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 10,
        'min_qty': 2,
        'updated_at': nowStr,
      });

      final inventoryRepo = InventoryRepository();
      final productRepo = ProductRepository();

      // Reserve all 10 bundles for an event
      await inventoryRepo.reserveStock(
        orderId: 201,
        productId: productId,
        quantity: 10,
        eventDate: '2026-10-18',
        eventName: 'Wedding Decor',
      );

      final prods = await productRepo.listActiveProductsWithInventory();
      final product = prods.firstWhere((p) => p.id == productId);

      // For Normal POS (Take Away, Delivery, Pickup Later):
      // Available to sell is 0, so product cannot be directly selected without releasing hold
      expect(productPickerCanSelect(product, isEventSale: false), isFalse);
      expect(productPickerIsOutOfStock(product, isEventSale: false), isTrue);
      expect(productPickerAvailabilityText(product, isEventSale: false), 'Stock: 10 (All held for Events)');

      // For Event POS (isEventSale: true):
      // Future event orders CAN be selected even when today's available stock is 0!
      expect(productPickerCanSelect(product, isEventSale: true), isTrue);
      expect(productPickerIsOutOfStock(product, isEventSale: true), isFalse);
      expect(productPickerAvailabilityText(product, isEventSale: true), 'Stock: 10 Bundles (Held: 10)');
    });

    test('5. Releasing reservation frees availableToSell without affecting physical stock', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Hydrangea Blue',
        'category': 'Exotic',
        'selling_price_paise': 15000,
        'purchase_price_paise': 7500,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 15,
        'min_qty': 2,
        'updated_at': nowStr,
      });

      final inventoryRepo = InventoryRepository();
      final productRepo = ProductRepository();

      final resId = await inventoryRepo.reserveStock(
        orderId: 301,
        productId: productId,
        quantity: 10,
        eventDate: '2026-10-30',
        eventName: 'Stage Decor',
      );

      var prods = await productRepo.listActiveProductsWithInventory();
      var prod = prods.firstWhere((p) => p.id == productId);
      expect(prod.availableToSell, 5);
      expect(prod.reservedQty, 10);
      expect(prod.currentQty, 15);

      // Release partial reservation (release 4 units from hold)
      final released = await inventoryRepo.releaseQuantityFromProductReservations(
        productId: productId,
        quantityToRelease: 4,
      );
      expect(released, 4);

      prods = await productRepo.listActiveProductsWithInventory();
      prod = prods.firstWhere((p) => p.id == productId);
      expect(prod.availableToSell, 9);
      expect(prod.reservedQty, 6);
      expect(prod.currentQty, 15);

      // Release entire remaining reservation
      await inventoryRepo.releaseReservation(resId);

      prods = await productRepo.listActiveProductsWithInventory();
      prod = prods.firstWhere((p) => p.id == productId);
      expect(prod.availableToSell, 15);
      expect(prod.reservedQty, 0);
      expect(prod.currentQty, 15);
    });

    test('6. Event order cancellation releases active reservations automatically without deducting inventory', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Sunflower Large',
        'category': 'Flowers',
        'selling_price_paise': 6000,
        'purchase_price_paise': 3000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 30,
        'min_qty': 5,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Festival Committee',
        'phone': '9876500099',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-CANCEL-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'subtotal_paise': 120000,
        'grand_total_paise': 120000,
        'is_paid': 0,
        'occasion': 'Harvest Festival',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final inventoryRepo = InventoryRepository();
      await inventoryRepo.reserveStock(
        orderId: orderId,
        productId: productId,
        quantity: 20,
        eventDate: '2026-10-31',
        eventName: 'Harvest Festival',
      );

      final productRepo = ProductRepository();
      var prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.availableToSell, 10);
      expect(prod.reservedQty, 20);

      // Cancel the event order
      final orderRepo = OrderRepository();
      await orderRepo.updateOrderStatus(
        orderId: orderId,
        newStatus: 'cancelled',
        createdBy: 'manager',
        notes: 'Client cancelled event',
      );

      // Assertions: Reservations released, availableToSell back to 30, physical stock unchanged at 30
      final activeReservations = await inventoryRepo.getActiveReservationsForProduct(productId);
      expect(activeReservations.isEmpty, isTrue);

      prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.availableToSell, 30);
      expect(prod.reservedQty, 0);
      expect(prod.currentQty, 30);
    });

    test('7. Event order fulfillment (delivered status) marks reservations consumed and deducts physical inventory', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Pink Tulip Stem',
        'category': 'Exotic',
        'selling_price_paise': 9000,
        'purchase_price_paise': 4500,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 50,
        'min_qty': 5,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Spring Wedding',
        'phone': '9876500088',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-DELIVER-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'subtotal_paise': 270000,
        'grand_total_paise': 270000,
        'is_paid': 1,
        'occasion': 'Spring Wedding',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final lineId = await db.insert('order_lines', {
        'order_id': orderId,
        'product_id': productId,
        'description': 'Pink Tulip Stem',
        'qty': 30,
        'unit_price_paise': 9000,
        'gst_percent': 0,
        'line_subtotal_paise': 270000,
        'line_gst_paise': 0,
        'line_total_paise': 270000,
        'source': 'product',
      });

      final inventoryRepo = InventoryRepository();
      await inventoryRepo.reserveStock(
        orderId: orderId,
        orderLineId: lineId,
        productId: productId,
        quantity: 30,
        eventDate: '2026-11-05',
        eventName: 'Spring Wedding',
      );

      final productRepo = ProductRepository();
      var prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.currentQty, 50);
      expect(prod.reservedQty, 30);
      expect(prod.availableToSell, 20);

      // Deliver/Fulfill the event order
      final orderRepo = OrderRepository();
      await orderRepo.updateOrderStatus(
        orderId: orderId,
        newStatus: 'delivered',
        createdBy: 'delivery_staff',
      );

      // Assertions:
      // 1. Active reservations consumed
      final activeReservations = await inventoryRepo.getActiveReservationsForProduct(productId);
      expect(activeReservations.isEmpty, isTrue);

      final orderReservations = await inventoryRepo.getReservationsForOrder(orderId: orderId);
      expect(orderReservations.length, 1);
      expect(orderReservations.first.status, 'consumed');
      expect(orderReservations.first.consumedAt, isNotNull);

      // 2. Physical stock deducted: 50 - 30 = 20
      prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.currentQty, 20, reason: 'Physical stock must be deducted upon delivery');
      expect(prod.reservedQty, 0);
      expect(prod.availableToSell, 20);

      // 3. Inventory transaction recorded
      final txns = await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [orderId]);
      expect(txns.isNotEmpty, isTrue);
      expect(txns.first['txn_type'], 'sale');
      expect(txns.first['qty'], 30);
    });

    test('8. Event Sale requiring 3 while physical stock is 1 -> booking succeeds and physical stock remains 1', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Rare Blue Orchid',
        'category': 'Exotic',
        'selling_price_paise': 20000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 1,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Luxury Event Planner',
        'phone': '9876540001',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-SHORT-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 60000,
        'is_paid': 0,
        'occasion': 'Gala Dinner',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Rare Blue Orchid',
        'qty': 3,
        'unit_price_paise': 20000,
        'gst_percent': 0,
        'line_subtotal_paise': 60000,
        'line_gst_paise': 0,
        'line_total_paise': 60000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      final confirmed = await orderRepo.confirmDraft(orderId: draftId);
      expect(confirmed.orderId, draftId);

      // Core Rule: Booking succeeds without error, and physical stock remains 1 (not deducted or constrained)
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 1);

      final productRepo = ProductRepository();
      final prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.currentQty, 1);
      expect(prod.reservedQty, 0);
      expect(prod.availableToSell, 1);
    });

    test('9. Event Sale without reservation -> physical stock unchanged and availableToSell equals physical stock', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'White Rose Bloom',
        'category': 'Roses',
        'selling_price_paise': 5000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 15,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Wedding Decor Client',
        'phone': '9876540002',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-NORES-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 25000,
        'is_paid': 0,
        'occasion': 'Wedding',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'White Rose Bloom',
        'qty': 5,
        'unit_price_paise': 5000,
        'gst_percent': 0,
        'line_subtotal_paise': 25000,
        'line_gst_paise': 0,
        'line_total_paise': 25000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      await orderRepo.confirmDraft(orderId: draftId);

      final productRepo = ProductRepository();
      final prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.currentQty, 15);
      expect(prod.reservedQty, 0);
      expect(prod.availableToSell, 15);
    });

    test('10. Event Sale with reservation -> physical stock unchanged and reservation created', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Pink Lily Stem',
        'category': 'Lilies',
        'selling_price_paise': 7000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 10,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Anniversary Booking',
        'phone': '9876540003',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-RES-002',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 28000,
        'is_paid': 0,
        'occasion': 'Silver Jubilee',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final lineId = await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Pink Lily Stem',
        'qty': 4,
        'unit_price_paise': 7000,
        'gst_percent': 0,
        'line_subtotal_paise': 28000,
        'line_gst_paise': 0,
        'line_total_paise': 28000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      await orderRepo.confirmDraft(orderId: draftId);

      // Explicitly hold 3 stems for this event
      final inventoryRepo = InventoryRepository();
      await inventoryRepo.reserveStock(
        orderId: draftId,
        orderLineId: lineId,
        productId: productId,
        quantity: 3,
        eventDate: '2026-10-30',
        eventName: 'Silver Jubilee',
      );

      final productRepo = ProductRepository();
      final prod = (await productRepo.listActiveProductsWithInventory()).firstWhere((p) => p.id == productId);
      expect(prod.currentQty, 10, reason: 'Physical stock must remain 10');
      expect(prod.reservedQty, 3, reason: 'Reserved quantity must be 3');
      expect(prod.availableToSell, 7, reason: 'Available to sell must be 10 - 3 = 7');

      final orderReservations = await inventoryRepo.getReservationsForOrder(orderId: draftId);
      expect(orderReservations.length, 1);
      expect(orderReservations.first.quantity, 3);
      expect(orderReservations.first.status, 'active');
    });

    test('11. Normal Walk-in (take_away) requiring 3 while physical stock is 1 -> existing stock validation remains unchanged (guards against negative stock)', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Sunflower Single',
        'category': 'Flowers',
        'selling_price_paise': 3000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 1,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Walk-in Retail Buyer',
        'phone': '9876540004',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'WALK-001',
        'fulfilment_type': 'take_away',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 9000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Sunflower Single',
        'qty': 3,
        'unit_price_paise': 3000,
        'gst_percent': 0,
        'line_subtotal_paise': 9000,
        'line_gst_paise': 0,
        'line_total_paise': 9000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      // Existing stock validation for normal walk-in throws StateError('Stock cannot go negative')
      expect(
        () => orderRepo.confirmDraft(orderId: draftId),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Stock cannot go negative'))),
      );

      // Verify physical stock remains 1
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 1);
    });

    test('12. Cloud Event Sale with advance payment -> buildCloudPosSalePayload sends empty inventoryTransactions and payment is preserved', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Red Rose Bundle',
        'category': 'Flowers',
        'selling_price_paise': 10000,
        'default_unit': 'Bundle',
        'track_inventory': 1,
        'cloud_product_id': '00000000-0000-0000-0000-000000000001',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 20,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Cloud Event Client',
        'phone': '9876540005',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-CLOUD-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'subtotal_paise': 50000,
        'grand_total_paise': 50000,
        'is_paid': 0,
        'occasion': 'Birthday Banquet',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'cloud_product_id': '00000000-0000-0000-0000-000000000001',
        'description': 'Red Rose Bundle',
        'qty': 5,
        'unit_price_paise': 10000,
        'gst_percent': 0,
        'line_subtotal_paise': 50000,
        'line_gst_paise': 0,
        'line_total_paise': 50000,
        'source': 'product',
      });

      // Partial advance payment ₹200 (20000 paise) via UPI
      await db.insert('order_payments', {
        'order_id': draftId,
        'method': 'upi',
        'amount_paise': 20000,
        'reference': 'UPI-ADV-12345',
        'created_at': nowStr,
      });

      final orderRepo = OrderRepository();
      final payload = await orderRepo.buildCloudPosSalePayload(
        orderId: draftId,
        clientSyncId: 'sync-evt-001',
        orderNo: 'EVT-CLOUD-001',
      );

      // Verify serialization:
      // 1. Order fulfilment_type is event_sale
      expect(payload['order']['fulfilment_type'], 'event_sale');
      // 2. Inventory transactions must be EMPTY for Event Sale
      final invTransactions = payload['inventoryTransactions'] as List;
      expect(invTransactions.isEmpty, isTrue, reason: 'Cloud payload for event_sale must have empty inventoryTransactions');
      // 3. Payment is serialized
      final payments = payload['payments'] as List;
      expect(payments.length, 1);
      expect(payments.first['amount_paise'], 20000);
      expect(payments.first['method'], 'upi');
    });

    test('13. Cloud Event Sale with no advance -> booking still succeeds with zero advance and empty inventoryTransactions', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Yellow Marigold Bag',
        'category': 'Flowers',
        'selling_price_paise': 8000,
        'default_unit': 'Bag',
        'track_inventory': 1,
        'cloud_product_id': '00000000-0000-0000-0000-000000000002',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 10,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Puja Committee',
        'phone': '9876540006',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-NOADV-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'subtotal_paise': 32000,
        'grand_total_paise': 32000,
        'is_paid': 0,
        'occasion': 'Temple Festival',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'cloud_product_id': '00000000-0000-0000-0000-000000000002',
        'description': 'Yellow Marigold Bag',
        'qty': 4,
        'unit_price_paise': 8000,
        'gst_percent': 0,
        'line_subtotal_paise': 32000,
        'line_gst_paise': 0,
        'line_total_paise': 32000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      final payload = await orderRepo.buildCloudPosSalePayload(
        orderId: draftId,
        clientSyncId: 'sync-evt-002',
        orderNo: 'EVT-NOADV-001',
      );

      expect(payload['order']['fulfilment_type'], 'event_sale');
      expect((payload['inventoryTransactions'] as List).isEmpty, isTrue);
      expect((payload['payments'] as List).isEmpty, isTrue);
      expect(payload['order']['is_paid'], 0);
    });

    test('14. finalizeCloudConfirmedDraft() does not create an inventory deduction for event_sale', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Carnation Pink',
        'category': 'Flowers',
        'selling_price_paise': 6000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 25,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Banquet Hall',
        'phone': '9876540007',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-FINALIZE-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 48000,
        'is_paid': 0,
        'occasion': 'Banquet',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Carnation Pink',
        'qty': 8,
        'unit_price_paise': 6000,
        'gst_percent': 0,
        'line_subtotal_paise': 48000,
        'line_gst_paise': 0,
        'line_total_paise': 48000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      final confirmed = await orderRepo.finalizeCloudConfirmedDraft(
        orderId: draftId,
        orderNo: 'EVT-FINALIZE-001',
        cloudOrderId: 'cloud-order-12345',
      );
      expect(confirmed.orderId, draftId);

      // Verify physical stock is UNCHANGED (25) and no inventory transaction was recorded
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 25, reason: 'finalizeCloudConfirmedDraft must NOT deduct physical stock for event_sale');

      final txns = await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [draftId]);
      expect(txns.isEmpty, isTrue, reason: 'finalizeCloudConfirmedDraft must NOT create inventory_transactions for event_sale');
    });

    test('15. Existing normal POS (take_away) buildCloudPosSalePayload and finalizeCloudConfirmedDraft create inventory transactions', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Standard Red Rose',
        'category': 'Roses',
        'selling_price_paise': 5000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'cloud_product_id': '00000000-0000-0000-0000-000000000003',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 30,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Retail POS Customer',
        'phone': '9876540008',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'POS-RETAIL-001',
        'fulfilment_type': 'take_away',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 25000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'cloud_product_id': '00000000-0000-0000-0000-000000000003',
        'description': 'Standard Red Rose',
        'qty': 5,
        'unit_price_paise': 5000,
        'gst_percent': 0,
        'line_subtotal_paise': 25000,
        'line_gst_paise': 0,
        'line_total_paise': 25000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();

      // 1. buildCloudPosSalePayload for take_away DOES include inventoryTransactions
      final payload = await orderRepo.buildCloudPosSalePayload(
        orderId: draftId,
        clientSyncId: 'sync-pos-001',
        orderNo: 'POS-RETAIL-001',
      );
      final invTransactions = payload['inventoryTransactions'] as List;
      expect(invTransactions.isNotEmpty, isTrue, reason: 'take_away must generate inventoryTransactions for cloud sync');
      expect(invTransactions.first['qty'], 5);
      expect(invTransactions.first['txn_type'], 'sale');

      // 2. finalizeCloudConfirmedDraft for unmapped take_away items does deduct inventory
      final unmappedProdId = await db.insert('products', {
        'name': 'Unmapped Rose Stem',
        'category': 'Roses',
        'selling_price_paise': 4000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('inventory_items', {
        'product_id': unmappedProdId,
        'current_qty': 20,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final unmappedDraftId = await db.insert('orders', {
        'order_no': 'POS-UNMAPPED-001',
        'fulfilment_type': 'take_away',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 8000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });
      await db.insert('order_lines', {
        'order_id': unmappedDraftId,
        'product_id': unmappedProdId,
        'description': 'Unmapped Rose Stem',
        'qty': 2,
        'unit_price_paise': 4000,
        'gst_percent': 0,
        'line_subtotal_paise': 8000,
        'line_gst_paise': 0,
        'line_total_paise': 8000,
        'source': 'product',
      });

      await orderRepo.finalizeCloudConfirmedDraft(
        orderId: unmappedDraftId,
        orderNo: 'POS-UNMAPPED-001',
        cloudOrderId: 'cloud-order-99999',
      );

      final unmappedInv = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [unmappedProdId]);
      expect(unmappedInv.first['current_qty'], 18, reason: 'take_away must deduct local inventory for unmapped products in finalizeCloudConfirmedDraft');
    });

    test('16. Web POS buildWebPosPayload sends empty inventoryTransactions for event_sale but populates them for take_away, delivery, and pickup_later', () {
      const eventSession = WalkInSession(
        fulfilmentType: FulfilmentType.eventSale,
        customerName: 'Web Event Client',
        customerPhone: '9876540010',
        lines: [
          WalkInLineItem(
            cloudProductId: '00000000-0000-0000-0000-000000000010',
            description: 'Grand Rose Basket',
            quantity: 3,
            unitPricePaise: 50000,
            source: 'product',
          ),
        ],
      );

      final eventPayload = WalkInManager.buildWebPosPayload(
        session: eventSession,
        totals: const OrderTotals(
          subtotalPaise: 150000,
          gstTotalPaise: 0,
          discountTotalPaise: 0,
          roundOffPaise: 0,
          grandTotalPaise: 150000,
        ),
        ensuredCustomer: null,
        clientSyncId: 'web_sync_event_01',
        now: DateTime.utc(2026, 9, 30, 12, 0, 0),
      );

      expect(eventPayload['order']['fulfilment_type'], 'event_sale');
      final eventInv = eventPayload['inventoryTransactions'] as List;
      expect(eventInv.isEmpty, isTrue, reason: 'Web Event Sale must send empty inventoryTransactions');

      const takeAwaySession = WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Web Takeaway Client',
        customerPhone: '9876540011',
        lines: [
          WalkInLineItem(
            cloudProductId: '00000000-0000-0000-0000-000000000011',
            description: 'Red Rose Single',
            quantity: 2,
            unitPricePaise: 10000,
            source: 'product',
          ),
        ],
      );

      final takeAwayPayload = WalkInManager.buildWebPosPayload(
        session: takeAwaySession,
        totals: const OrderTotals(
          subtotalPaise: 20000,
          gstTotalPaise: 0,
          discountTotalPaise: 0,
          roundOffPaise: 0,
          grandTotalPaise: 20000,
        ),
        ensuredCustomer: null,
        clientSyncId: 'web_sync_takeaway_01',
        now: DateTime.utc(2026, 9, 30, 12, 0, 0),
      );

      expect(takeAwayPayload['order']['fulfilment_type'], 'takeAway');
      final takeAwayInv = takeAwayPayload['inventoryTransactions'] as List;
      expect(takeAwayInv, hasLength(1));
      expect(takeAwayInv.first['cloudProductId'], '00000000-0000-0000-0000-000000000011');
      expect(takeAwayInv.first['qty'], 2);
    });
  });

  group('Phase 2B: Event Fulfillment / Preparation / Ready for Event Lifecycle Tests', () {
    test('1. OrderStatus transitions for event_sale: confirmed -> preparing -> ready -> delivered', () {
      // Confirmed -> preparing / sent_to_designer
      final fromConfirmed = OrderStatus.nextStatuses(OrderStatus.confirmed, fulfilmentType: 'event_sale');
      expect(fromConfirmed, contains(OrderStatus.preparing));
      expect(fromConfirmed, contains(OrderStatus.sentToDesigner));
      expect(OrderStatus.canTransition(OrderStatus.confirmed, OrderStatus.preparing, fulfilmentType: 'event_sale'), isTrue);

      // Preparing -> ready
      final fromPreparing = OrderStatus.nextStatuses(OrderStatus.preparing, fulfilmentType: 'event_sale');
      expect(fromPreparing, contains(OrderStatus.ready));
      expect(OrderStatus.canTransition(OrderStatus.preparing, OrderStatus.ready, fulfilmentType: 'event_sale'), isTrue);

      // Ready -> delivered (bypasses out_for_delivery)
      final fromReady = OrderStatus.nextStatuses(OrderStatus.ready, fulfilmentType: 'event_sale');
      expect(fromReady, contains(OrderStatus.delivered));
      expect(fromReady, isNot(contains(OrderStatus.outForDelivery)));
      expect(OrderStatus.canTransition(OrderStatus.ready, OrderStatus.delivered, fulfilmentType: 'event_sale'), isTrue);
      expect(OrderStatus.canTransition(OrderStatus.ready, OrderStatus.outForDelivery, fulfilmentType: 'event_sale'), isFalse);

      // Action labels
      expect(OrderStatus.actionLabel(OrderStatus.ready, fulfilmentType: 'event_sale'), 'Mark Ready for Event');
      expect(OrderStatus.actionLabel(OrderStatus.delivered, fulfilmentType: 'event_sale'), 'Fulfill Event');

      // Standard delivery flow is preserved unchanged
      final deliveryFromReady = OrderStatus.nextStatuses(OrderStatus.ready, fulfilmentType: 'delivery');
      expect(deliveryFromReady, contains(OrderStatus.outForDelivery));
      expect(deliveryFromReady, isNot(contains(OrderStatus.delivered)));
      expect(OrderStatus.canTransition(OrderStatus.ready, OrderStatus.outForDelivery, fulfilmentType: 'delivery'), isTrue);
    });

    test('2. Event fulfillment with active reservation consumes hold and creates single physical deduction', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Premium Blue Orchid',
        'category': 'Exotic',
        'selling_price_paise': 10000,
        'purchase_price_paise': 5000,
        'default_unit': 'Stem',
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 10,
        'min_qty': 2,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Hotel Taj Grand',
        'phone': '9876543220',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-FULFILL-001',
        'fulfilment_type': 'event_sale',
        'status': 'draft',
        'customer_id': customerId,
        'grand_total_paise': 60000,
        'is_paid': 0,
        'occasion': 'Corporate Gala',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final lineId = await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Premium Blue Orchid',
        'qty': 6,
        'unit_price_paise': 10000,
        'gst_percent': 0,
        'line_subtotal_paise': 60000,
        'line_gst_paise': 0,
        'line_total_paise': 60000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      final inventoryRepo = InventoryRepository();
      final productRepo = ProductRepository();

      // Confirm booking
      await orderRepo.confirmDraft(orderId: draftId);

      // Reserve 6 stems
      await inventoryRepo.reserveStock(
        orderId: draftId,
        orderLineId: lineId,
        productId: productId,
        quantity: 6,
        eventName: 'Corporate Gala (#EVT-FULFILL-001)',
      );

      // Before fulfillment: physical = 10, reserved = 6, ATS = 4
      var prods = await productRepo.listActiveProductsWithInventory();
      expect(prods.firstWhere((p) => p.id == productId).currentQty, 10);
      expect(prods.firstWhere((p) => p.id == productId).reservedQty, 6);
      expect(prods.firstWhere((p) => p.id == productId).availableToSell, 4);

      // Progress status: confirmed -> preparing -> ready -> delivered
      await orderRepo.updateOrderStatus(orderId: draftId, newStatus: 'preparing', createdBy: 'florist');
      await orderRepo.updateOrderStatus(orderId: draftId, newStatus: 'ready', createdBy: 'florist');
      await orderRepo.updateOrderStatus(orderId: draftId, newStatus: 'delivered', createdBy: 'florist');

      // After fulfillment:
      // 1. Physical stock is deducted: 10 - 6 = 4
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 4, reason: 'Physical inventory must be deducted upon event delivery/fulfillment');

      // 2. Reservation is consumed
      final resRows = await db.query('inventory_reservations', where: 'order_id = ?', whereArgs: [draftId]);
      expect(resRows.first['status'], 'consumed');
      expect(resRows.first['consumed_at'], isNotNull);

      // 3. Exactly one sale transaction created
      final txns = await db.query('inventory_transactions', where: 'order_id = ? AND txn_type = ?', whereArgs: [draftId, 'sale']);
      expect(txns.length, 1);
      expect(txns.first['qty'], 6);

      // 4. ATS after fulfillment = physical 4 - reserved 0 = 4
      prods = await productRepo.listActiveProductsWithInventory();
      expect(prods.firstWhere((p) => p.id == productId).currentQty, 4);
      expect(prods.firstWhere((p) => p.id == productId).reservedQty, 0);
      expect(prods.firstWhere((p) => p.id == productId).availableToSell, 4);
    });

    test('3. checkEventFulfillmentStock detects physical inventory shortage before fulfillment', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': '20 Red Roses Basket',
        'category': 'Bouquets',
        'selling_price_paise': 250000,
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Stock is only 1
      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 1,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final customerId = await db.insert('customers', {
        'name': 'Wedding Client',
        'phone': '9876543221',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // Order requires 3 baskets
      final draftId = await db.insert('orders', {
        'order_no': 'EVT-SHORTAGE-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 750000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': '20 Red Roses Basket',
        'qty': 3,
        'unit_price_paise': 250000,
        'gst_percent': 0,
        'line_subtotal_paise': 750000,
        'line_gst_paise': 0,
        'line_total_paise': 750000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();
      final shortages = await orderRepo.checkEventFulfillmentStock(draftId);

      expect(shortages, hasLength(1));
      expect(shortages.first.productName, '20 Red Roses Basket');
      expect(shortages.first.requiredQty, 3);
      expect(shortages.first.availableQty, 1);
      expect(shortages.first.shortageQty, 2);
    });

    test('4. Event fulfillment with zero reservation deducts physical stock directly without error', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Yellow Marigold Garland',
        'category': 'Garlands',
        'selling_price_paise': 30000,
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 15,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-NORESERVE-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'grand_total_paise': 300000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': draftId,
        'product_id': productId,
        'description': 'Yellow Marigold Garland',
        'qty': 10,
        'unit_price_paise': 30000,
        'gst_percent': 0,
        'line_subtotal_paise': 300000,
        'line_gst_paise': 0,
        'line_total_paise': 300000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();

      // No reservation made during booking. Fulfill directly:
      await orderRepo.updateOrderStatus(orderId: draftId, newStatus: 'delivered', createdBy: 'florist');

      // Stock should be 15 - 10 = 5
      final invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 5);

      final txns = await db.query('inventory_transactions', where: 'order_id = ? AND txn_type = ?', whereArgs: [draftId, 'sale']);
      expect(txns.length, 1);
      expect(txns.first['qty'], 10);
    });

    test('5. Event cancellation releases active reservations back to Available-to-Sell', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'White Tulip Stem',
        'category': 'Exotic',
        'selling_price_paise': 15000,
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 20,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final draftId = await db.insert('orders', {
        'order_no': 'EVT-CANCEL-001',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'grand_total_paise': 150000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final inventoryRepo = InventoryRepository();
      final productRepo = ProductRepository();

      await inventoryRepo.reserveStock(
        orderId: draftId,
        productId: productId,
        quantity: 10,
        eventName: 'Cancelled Event (#EVT-CANCEL-001)',
      );

      var prods = await productRepo.listActiveProductsWithInventory();
      expect(prods.firstWhere((p) => p.id == productId).availableToSell, 10);

      // Cancel order
      final orderRepo = OrderRepository();
      await orderRepo.updateOrderStatus(orderId: draftId, newStatus: 'cancelled', createdBy: 'admin');

      // Reservations should be released
      final resRows = await db.query('inventory_reservations', where: 'order_id = ?', whereArgs: [draftId]);
      expect(resRows.first['status'], 'released');
      expect(resRows.first['released_at'], isNotNull);

      // Physical stock remains 20, ATS restored to 20
      prods = await productRepo.listActiveProductsWithInventory();
      expect(prods.firstWhere((p) => p.id == productId).currentQty, 20);
      expect(prods.firstWhere((p) => p.id == productId).reservedQty, 0);
      expect(prods.firstWhere((p) => p.id == productId).availableToSell, 20);
    });

    test('6. Event fulfillment is idempotent: repeated status update does not double-deduct', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final productId = await db.insert('products', {
        'name': 'Pink Lily Stem',
        'category': 'Flowers',
        'selling_price_paise': 9000,
        'track_inventory': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('inventory_items', {
        'product_id': productId,
        'current_qty': 20,
        'min_qty': 0,
        'updated_at': nowStr,
      });

      final orderId = await db.insert('orders', {
        'order_no': 'EVT-IDEMPOTENT-001',
        'fulfilment_type': 'event_sale',
        'status': 'ready',
        'grand_total_paise': 45000,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      await db.insert('order_lines', {
        'order_id': orderId,
        'product_id': productId,
        'description': 'Pink Lily Stem',
        'qty': 5,
        'unit_price_paise': 9000,
        'gst_percent': 0,
        'line_subtotal_paise': 45000,
        'line_gst_paise': 0,
        'line_total_paise': 45000,
        'source': 'product',
      });

      final orderRepo = OrderRepository();

      // First fulfillment
      await orderRepo.updateOrderStatus(orderId: orderId, newStatus: 'delivered', createdBy: 'florist');
      var invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 15);

      // Second fulfillment call (e.g. retry / webhook)
      await orderRepo.updateOrderStatus(orderId: orderId, newStatus: 'delivered', createdBy: 'florist');
      invRow = await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId]);
      expect(invRow.first['current_qty'], 15, reason: 'Repeated fulfillment must not double-deduct physical stock');
    });
  });

  group('Phase 2C: Workspace Event Sales Filters & Cloud Query Tests', () {
    test('1. OrderWorkspaceFilters serialization, copyWith, and defaults for eventSale', () {
      const defaultFilters = OrderWorkspaceFilters();
      expect(defaultFilters.eventSale, isFalse);

      final eventFilters = defaultFilters.copyWith(eventSale: true);
      expect(eventFilters.eventSale, isTrue);
      expect(eventFilters.delivery, isFalse);
      expect(eventFilters.pickup, isFalse);
      expect(eventFilters.takeAway, isFalse);

      // toJson & fromJson
      final json = eventFilters.toJson();
      expect(json['eventSale'], isTrue);

      final deserialized = OrderWorkspaceFilters.fromJson(json);
      expect(deserialized.eventSale, isTrue);
      expect(deserialized.delivery, isFalse);

      // Alternate snake_case json key support
      final snakeJson = {'event_sale': true};
      final fromSnake = OrderWorkspaceFilters.fromJson(snakeJson);
      expect(fromSnake.eventSale, isTrue);
    });

    test('2. Solo SQLite OrderRepository.getOrdersForWorkspace with eventSale: true returns only event sales', () async {
      final db = await AppDatabase.instance.database;
      final nowStr = DateTime.now().toIso8601String();

      final customerId = await db.insert('customers', {
        'name': 'Wedding Client',
        'phone': '9876543210',
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // 1. Create Event Sale order
      await db.insert('orders', {
        'order_no': 'EVT-FILTER-101',
        'fulfilment_type': 'event_sale',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 5000000,
        'is_paid': 0,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // 2. Create Normal Delivery order
      await db.insert('orders', {
        'order_no': 'DEL-FILTER-101',
        'fulfilment_type': 'delivery',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 100000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      // 3. Create Normal TakeAway order
      await db.insert('orders', {
        'order_no': 'TAKE-FILTER-101',
        'fulfilment_type': 'take_away',
        'status': 'confirmed',
        'customer_id': customerId,
        'grand_total_paise': 50000,
        'is_paid': 1,
        'created_at': nowStr,
        'updated_at': nowStr,
      });

      final repo = OrderRepository();

      // Query without filter -> returns all 3
      final allOrders = await repo.getOrdersForWorkspace(tab: 'all', searchQuery: '', filters: const OrderWorkspaceFilters());
      expect(allOrders.length, 3);

      // Query with eventSale: true -> returns ONLY EVT-FILTER-101
      final eventOnly = await repo.getOrdersForWorkspace(tab: 'all', searchQuery: '', filters: const OrderWorkspaceFilters(eventSale: true));
      expect(eventOnly.length, 1);
      expect(eventOnly.first.orderNo, 'EVT-FILTER-101');
      expect(eventOnly.first.fulfilmentType, 'event_sale');

      // Query with delivery: true -> returns ONLY DEL-FILTER-101
      final deliveryOnly = await repo.getOrdersForWorkspace(tab: 'all', searchQuery: '', filters: const OrderWorkspaceFilters(delivery: true));
      expect(deliveryOnly.length, 1);
      expect(deliveryOnly.first.orderNo, 'DEL-FILTER-101');

      // Query with takeAway: true -> returns ONLY TAKE-FILTER-101
      final takeAwayOnly = await repo.getOrdersForWorkspace(tab: 'all', searchQuery: '', filters: const OrderWorkspaceFilters(takeAway: true));
      expect(takeAwayOnly.length, 1);
      expect(takeAwayOnly.first.orderNo, 'TAKE-FILTER-101');
    });

    test('3. CloudOrderRepository.getWorkspace with eventSale: true sends fulfilmentType=event_sale parameter', () async {
      Uri? capturedUri;
      final cloudRepo = CloudOrderRepository(
        sender: (method, uri, {body, headers}) async {
          capturedUri = uri;
          return {
            'items': [
              {
                'id': '11111111-1111-1111-1111-111111111111',
                'orderNumber': 'EVT-CLOUD-101',
                'customerName': 'Wedding Client',
                'customerPhone': '9876543210',
                'fulfilmentType': 'event_sale',
                'status': 'confirmed',
                'paymentStatus': 'Unpaid',
                'totalAmount': 50000.0,
                'paidAmount': 10000.0,
                'balanceDue': 40000.0,
                'orderDate': '2026-10-15T00:00:00.000Z',
                'deliveryDate': '2026-10-15T00:00:00.000Z',
              }
            ],
            'totalCount': 1,
            'page': 1,
            'pageSize': 20,
          };
        },
      );

      final items = await cloudRepo.getWorkspace(
        tab: 'all',
        searchQuery: '',
        filters: const OrderWorkspaceFilters(eventSale: true),
      );

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['fulfilmentType'], 'event_sale');
      expect(items.length, 1);
      expect(items.first.orderNo, 'EVT-CLOUD-101');
      expect(items.first.fulfilmentType, 'event_sale');
    });
  });
}
