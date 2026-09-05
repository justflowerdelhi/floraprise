import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/data/repositories/pos_sync_outbox_repository.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/services/product_cloud_syncability_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const currentCompanyId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const firstCloudId = '11111111-1111-4111-8111-111111111111';
const secondCloudId = '22222222-2222-4222-8222-222222222222';

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

  test('opening POS starts blank even when a draft exists', () async {
    final orderRepository = OrderRepository();
    final orderManager = OrderManager(orderRepository, JobRepository());
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: orderManager,
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    await walkInManager.saveDraft(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Rahul Sharma',
        customerPhone: '9876543210',
        lines: [
          WalkInLineItem(
            description: 'Rose Bouquet',
            quantity: 2,
            unitPricePaise: 50000,
            source: 'manual',
          ),
        ],
      ),
    );

    final freshSession =
        await walkInManager.startOrResume(FulfilmentType.takeAway);
    final drafts = await orderRepository.listDraftOrders();
    final restoredDraft = await orderRepository.getDraftById(drafts.single.id);

    expect(freshSession.draftOrderId, isNull);
    expect(freshSession.lines, isEmpty);
    expect(freshSession.customerName, isEmpty);
    expect(drafts, hasLength(1));
    expect(drafts.single.customerName, 'Rahul Sharma');
    expect(restoredDraft, isNotNull);
    expect(restoredDraft!.lines, isA<List<WalkInLineItem>>());
    expect(restoredDraft.lines.single.description, 'Rose Bouquet');
  });

  test('deleteDraft removes only draft orders', () async {
    final orderRepository = OrderRepository();
    final orderManager = OrderManager(orderRepository, JobRepository());
    final walkInManager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: orderManager,
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    final draftResult = await walkInManager.saveDraft(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Draft Customer',
        lines: [
          WalkInLineItem(
            description: 'Draft Line',
            quantity: 1,
            unitPricePaise: 10000,
            source: 'manual',
          ),
        ],
      ),
    );
    final completed = await walkInManager.confirmOrder(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Completed Customer',
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 10000,
            methodCode: 'cash',
          ),
        ],
        lines: [
          WalkInLineItem(
            description: 'Completed Line',
            quantity: 1,
            unitPricePaise: 10000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
      ),
    );

    await orderRepository.deleteDraft(completed.orderId);
    await orderRepository.deleteDraft(draftResult.session.draftOrderId!);

    final drafts = await orderRepository.listDraftOrders();
    final completedSummary =
        await orderRepository.getOrderSummary(completed.orderId);

    expect(drafts, isEmpty);
    expect(completedSummary['status'], 'confirmed');
  });

  test('confirmed sale atomically stores one immutable outbox snapshot', () async {
    final db = await AppDatabase.instance.database;
    final firstProductId = await db.insert('products', {
      'name': 'Rose', 'selling_price_paise': 10000, 'track_inventory': 1,
      'cloud_product_id': firstCloudId, 'cloud_product_company_id': currentCompanyId,
      'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(),
    });
    final secondProductId = await db.insert('products', {
      'name': 'Lily', 'selling_price_paise': 20000, 'track_inventory': 1,
      'cloud_product_id': secondCloudId, 'cloud_product_company_id': currentCompanyId,
      'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('inventory_items', {
      'product_id': firstProductId, 'current_qty': 2, 'min_qty': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('inventory_items', {
      'product_id': secondProductId, 'current_qty': 2, 'min_qty': 0,
      'updated_at': DateTime.now().toIso8601String(),
    });
    final orders = _mappedOrderRepository();
    final manager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(orders, JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );
    final confirmed = await manager.confirmOrder(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Outbox Customer', customerPhone: '9876543210',
      lines: [
        WalkInLineItem(productId: firstProductId, description: 'Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
        WalkInLineItem(productId: secondProductId, description: 'Lily', quantity: 1, unitPricePaise: 20000, gstPercent: 0, source: 'product'),
      ],
      payments: const [
        PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash'),
        PaymentSplit(method: PaymentMethod.upi, amountPaise: 20000, methodCode: 'upi'),
      ],
    ));

    final outbox = PosSyncOutboxRepository();
    final pending = await outbox.listPending(db);
    expect(pending, hasLength(1));
    expect(pending.single.localOrderId, confirmed.orderId);
    expect(pending.single.clientSyncId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(pending.single.state, 'pending');
    expect(pending.single.payload['lines'], hasLength(2));
    expect(pending.single.payload['payments'], hasLength(2));
    expect(pending.single.payload['inventoryTransactions'], hasLength(2));
    expect((pending.single.payload['lines'] as List).first['localProductId'], firstProductId);
    expect((pending.single.payload['lines'] as List).first['cloudProductId'], firstCloudId);
    expect((pending.single.payload['inventoryTransactions'] as List).first['localProductId'], firstProductId);
    expect((pending.single.payload['inventoryTransactions'] as List).first['cloudProductId'], firstCloudId);
    expect((pending.single.payload['order'] as Map)['grand_total_paise'], 30000);
    expect(await outbox.listPending(db), hasLength(1));
    expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [firstProductId])).single['current_qty'], 1);
    expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [secondProductId])).single['current_qty'], 1);
    await expectLater(
      () => db.insert('pos_sync_outbox', {
        'operation_type': 'completed_pos_sale', 'client_sync_id': pending.single.clientSyncId,
        'local_order_id': confirmed.orderId, 'payload_json': jsonEncode({}), 'state': 'pending',
        'attempt_count': 0, 'created_at': DateTime.now().toIso8601String(), 'updated_at': DateTime.now().toIso8601String(),
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('failed sale does not create a completed-sale outbox record', () async {
    final customers = CustomerRepository();
    final customer = await customers.create(
      phone: '9876500000',
      name: 'Failed Sale',
    );
    final manager = WalkInManager(
      customerManager: CustomerManager(customers),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );
    const session = WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Failed Sale',
      customerPhone: '9876500000',
      lines: [WalkInLineItem(productId: 999, description: 'Missing', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product')],
      payments: [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    );
    final draft = await manager.saveDraft(session);
    final db = await AppDatabase.instance.database;
    final beforeOrder = (await db.query('orders', where: 'id = ?', whereArgs: [draft.session.draftOrderId])).single;
    final beforeCustomer = (await db.query('customers', where: 'id = ?', whereArgs: [customer.id])).single;

    await expectLater(
      () => _mappedOrderRepository().confirmDraft(orderId: draft.session.draftOrderId!),
      throwsA(isA<StateError>()),
    );

    final afterOrder = (await db.query('orders', where: 'id = ?', whereArgs: [draft.session.draftOrderId])).single;
    final afterCustomer = (await db.query('customers', where: 'id = ?', whereArgs: [customer.id])).single;
    expect(afterOrder['status'], beforeOrder['status']);
    expect(afterOrder['confirmed_at'], beforeOrder['confirmed_at']);
    expect(afterOrder['reward_points_earned'], beforeOrder['reward_points_earned']);
    expect(afterOrder['reward_points_redeemed'], beforeOrder['reward_points_redeemed']);
    expect(afterCustomer['reward_points'], beforeCustomer['reward_points']);
    expect(afterCustomer['lifetime_reward_points'], beforeCustomer['lifetime_reward_points']);
    expect(afterCustomer['redeemed_reward_points'], beforeCustomer['redeemed_reward_points']);
    final timeline = await db.query(
      'order_timeline_events',
      where: 'order_id = ?',
      whereArgs: [draft.session.draftOrderId],
    );
    expect(timeline.where((event) => event['status'] == 'confirmed'), isEmpty);
    expect(timeline.where((event) => event['status'] == 'created'), hasLength(1));
    expect(await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [draft.session.draftOrderId]), isEmpty);
    expect(await db.query('inventory_items', where: 'product_id = ?', whereArgs: [999]), isEmpty);
    expect(await db.query('order_lines', where: 'order_id = ?', whereArgs: [draft.session.draftOrderId]), hasLength(1));
    expect(await db.query('order_payments', where: 'order_id = ?', whereArgs: [draft.session.draftOrderId]), hasLength(1));
    expect(await PosSyncOutboxRepository().listPending(db), isEmpty);
  });

}

OrderRepository _mappedOrderRepository({String? companyId = currentCompanyId}) {
  return OrderRepository(
    productCloudSyncabilityService: ProductCloudSyncabilityService(
      currentCompanyId: () async => companyId,
    ),
  );
}
