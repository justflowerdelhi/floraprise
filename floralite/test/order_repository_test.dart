import 'package:flutter_test/flutter_test.dart';
import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final path = await getDatabasesPath();
    await deleteDatabase('$path/floraprise.db');
  });

  test('today summary returns sales total in paise', () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('orders', {
      'order_no': 'TEST-001',
      'fulfilment_type': 'pickup_now',
      'status': 'confirmed',
      'grand_total_paise': 12345,
      'created_at': now,
      'updated_at': now,
    });

    final summary = await OrderRepository().getTodaySummary();

    expect(summary['todaySalesAmount'], 12345);
    expect(summary['todayOrderCount'], 1);
  });

  test('customer card stats match top customer report stats', () async {
    final db = await AppDatabase.instance.database;
    final now = DateTime(2026, 7, 19, 10).toIso8601String();
    final later = DateTime(2026, 7, 20, 10).toIso8601String();
    final customerId = await db.insert('customers', {
      'phone': '9876543210',
      'name': 'Anjula',
      'created_at': now,
      'updated_at': now,
    });
    final productId = await db.insert('products', {
      'name': 'Rose Bouquet',
      'category': 'Finished Products',
      'selling_price_paise': 200000,
      'gst_percent': 0,
      'created_at': now,
      'updated_at': now,
    });

    final firstOrderId = await db.insert('orders', {
      'order_no': 'CUST-001',
      'fulfilment_type': 'take_away',
      'status': 'confirmed',
      'customer_id': customerId,
      'customer_phone': '9876543210',
      'customer_name': 'Anjula',
      'grand_total_paise': 200000,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('order_lines', {
      'order_id': firstOrderId,
      'product_id': productId,
      'description': 'Rose Bouquet',
      'qty': 1,
      'unit_price_paise': 200000,
      'gst_percent': 0,
      'discount_paise': 0,
      'line_subtotal_paise': 200000,
      'line_gst_paise': 0,
      'line_total_paise': 200000,
      'source': 'product',
    });

    await db.insert('orders', {
      'order_no': 'CUST-002',
      'fulfilment_type': 'take_away',
      'status': 'delivered',
      'customer_id': null,
      'customer_phone': '9876543210',
      'customer_name': 'Anjula',
      'grand_total_paise': 200000,
      'created_at': later,
      'updated_at': later,
    });
    await db.insert('orders', {
      'order_no': 'CUST-DRAFT',
      'fulfilment_type': 'take_away',
      'status': 'draft',
      'customer_id': customerId,
      'customer_phone': '9876543210',
      'customer_name': 'Anjula',
      'grand_total_paise': 999999,
      'created_at': later,
      'updated_at': later,
    });

    final repository = OrderRepository();
    final cardStats = await repository.getCustomerOrderStatistics(
      customerId: customerId,
      customerPhone: '9876543210',
    );
    final topCustomer = (await repository.getTopCustomerStatistics(
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2026, 7, 31),
    ))
        .single;

    expect(cardStats.previousOrders, 2);
    expect(cardStats.lifetimePurchasePaise, 400000);
    expect(cardStats.lastOrderDate, later);
    expect(cardStats.favouriteDesign, 'Rose Bouquet');
    expect(topCustomer.customerId, customerId);
    expect(topCustomer.previousOrders, cardStats.previousOrders);
    expect(topCustomer.lifetimePurchasePaise, cardStats.lifetimePurchasePaise);
  });
}
