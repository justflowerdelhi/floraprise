import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/pos_sync_outbox_repository.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/services/product_cloud_syncability_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const currentCompanyId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const otherCompanyId = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const firstCloudId = '11111111-1111-4111-8111-111111111111';

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

  test('linked snapshots include cloudProductId and remain immutable', () async {
    final db = await AppDatabase.instance.database;
    final productId = await _insertProduct(
      cloudProductId: firstCloudId,
      cloudProductCompanyId: currentCompanyId,
    );
    await _insertInventory(productId, currentQty: 5);
    final orderId = await _insertDraft(productId: productId);

    await _orderRepository().confirmDraft(orderId: orderId);

    final pending = await PosSyncOutboxRepository().listPending(db);
    expect(pending, hasLength(1));
    final payloadBefore = jsonEncode(pending.single.payload);
    final line = (pending.single.payload['lines'] as List).single as Map;
    final inventory =
        (pending.single.payload['inventoryTransactions'] as List).single as Map;

    expect(line['localProductId'], productId);
    expect(line['cloudProductId'], firstCloudId);
    expect(inventory['localProductId'], productId);
    expect(inventory['cloudProductId'], firstCloudId);

    await db.update(
      'products',
      {'cloud_product_id': null, 'cloud_product_company_id': null},
      where: 'id = ?',
      whereArgs: [productId],
    );

    final payloadAfter = (await db.query('pos_sync_outbox')).single['payload_json'];
    expect(payloadAfter, payloadBefore);
  });

  test('missing mapping prevents confirmation and rolls back all side effects', () async {
    final productId = await _insertProduct();
    await _insertInventory(productId, currentQty: 5);
    final customer = await CustomerRepository().create(
      phone: '9876500001',
      name: 'Rollback Customer',
    );
    final orderId = await _insertDraft(productId: productId, customerId: customer.id);
    final before = await _rollbackSnapshot(orderId, productId, customer.id);

    await expectLater(
      () => _orderRepository().confirmDraft(orderId: orderId),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Product is not linked to Cloud inventory.',
        ),
      ),
    );

    await _expectRollbackUnchanged(orderId, productId, customer.id, before);
  });

  test('wrong-company mapping produces the same atomic rollback', () async {
    final productId = await _insertProduct(
      cloudProductId: firstCloudId,
      cloudProductCompanyId: otherCompanyId,
    );
    await _insertInventory(productId, currentQty: 5);
    final customer = await CustomerRepository().create(
      phone: '9876500002',
      name: 'Wrong Company',
    );
    final orderId = await _insertDraft(productId: productId, customerId: customer.id);
    final before = await _rollbackSnapshot(orderId, productId, customer.id);

    await expectLater(
      () => _orderRepository().confirmDraft(orderId: orderId),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Product is not linked to Cloud inventory.',
        ),
      ),
    );

    await _expectRollbackUnchanged(orderId, productId, customer.id, before);
  });

  test('manual service lines remain unaffected by cloud product mapping guard', () async {
    final orderId = await _insertDraft(productId: null);

    await OrderRepository().confirmDraft(orderId: orderId);

    final db = await AppDatabase.instance.database;
    final order = (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).single;
    final pending = await PosSyncOutboxRepository().listPending(db);
    final line = (pending.single.payload['lines'] as List).single as Map;

    expect(order['status'], 'confirmed');
    expect(line['product_id'], isNull);
    expect(line.containsKey('localProductId'), isFalse);
    expect(line.containsKey('cloudProductId'), isFalse);
  });
}

OrderRepository _orderRepository({String? companyId = currentCompanyId}) {
  return OrderRepository(
    productCloudSyncabilityService: ProductCloudSyncabilityService(
      currentCompanyId: () async => companyId,
    ),
  );
}

Future<int> _insertProduct({
  String? cloudProductId,
  String? cloudProductCompanyId,
}) async {
  final db = await AppDatabase.instance.database;
  final now = DateTime.now().toIso8601String();
  return db.insert('products', {
    'name': 'Cloud Rose',
    'category': 'Flowers',
    'default_unit': 'Stem',
    'selling_price_paise': 10000,
    'gst_percent': 0,
    'track_inventory': 1,
    'active': 1,
    'cloud_product_id': cloudProductId,
    'cloud_product_company_id': cloudProductCompanyId,
    'created_at': now,
    'updated_at': now,
  });
}

Future<void> _insertInventory(int productId, {required int currentQty}) async {
  final db = await AppDatabase.instance.database;
  await db.insert('inventory_items', {
    'product_id': productId,
    'current_qty': currentQty,
    'min_qty': 0,
    'updated_at': DateTime.now().toIso8601String(),
  });
}

Future<int> _insertDraft({required int? productId, int? customerId}) async {
  final session = WalkInSession(
    fulfilmentType: FulfilmentType.takeAway,
    customerName: 'POS Customer',
    customerPhone: '9876509999',
    lines: [
      WalkInLineItem(
        productId: productId,
        description: productId == null ? 'Delivery Service' : 'Cloud Rose',
        quantity: 1,
        unitPricePaise: 10000,
        gstPercent: 0,
        source: productId == null ? 'manual' : 'product',
      ),
    ],
    payments: const [
      PaymentSplit(
        method: PaymentMethod.cash,
        amountPaise: 10000,
        methodCode: 'cash',
      ),
    ],
  );
  return OrderRepository().upsertDraft(
    session: session,
    totals: const OrderTotals(
      subtotalPaise: 10000,
      gstTotalPaise: 0,
      discountTotalPaise: 0,
      roundOffPaise: 0,
      grandTotalPaise: 10000,
    ),
    customerId: customerId,
  );
}

Future<Map<String, Object?>> _rollbackSnapshot(
  int orderId,
  int productId,
  int customerId,
) async {
  final db = await AppDatabase.instance.database;
  return {
    'order': (await db.query('orders', where: 'id = ?', whereArgs: [orderId])).single,
    'customer': (await db.query('customers', where: 'id = ?', whereArgs: [customerId])).single,
    'inventory': (await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId])).single,
    'timeline': await db.query('order_timeline_events', where: 'order_id = ?', whereArgs: [orderId]),
    'transactions': await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [orderId]),
    'outbox': await db.query('pos_sync_outbox', where: 'local_order_id = ?', whereArgs: [orderId]),
  };
}

Future<void> _expectRollbackUnchanged(
  int orderId,
  int productId,
  int customerId,
  Map<String, Object?> before,
) async {
  final after = await _rollbackSnapshot(orderId, productId, customerId);
  final beforeOrder = before['order'] as Map;
  final afterOrder = after['order'] as Map;
  final beforeCustomer = before['customer'] as Map;
  final afterCustomer = after['customer'] as Map;
  final beforeInventory = before['inventory'] as Map;
  final afterInventory = after['inventory'] as Map;

  expect(afterOrder['status'], beforeOrder['status']);
  expect(afterOrder['confirmed_at'], beforeOrder['confirmed_at']);
  expect(afterOrder['reward_points_earned'], beforeOrder['reward_points_earned']);
  expect(afterOrder['reward_points_redeemed'], beforeOrder['reward_points_redeemed']);
  expect(afterCustomer['reward_points'], beforeCustomer['reward_points']);
  expect(afterCustomer['lifetime_reward_points'], beforeCustomer['lifetime_reward_points']);
  expect(afterCustomer['redeemed_reward_points'], beforeCustomer['redeemed_reward_points']);
  expect(afterInventory['current_qty'], beforeInventory['current_qty']);
  expect(after['timeline'], before['timeline']);
  expect(after['transactions'], isEmpty);
  expect(after['outbox'], isEmpty);
}
