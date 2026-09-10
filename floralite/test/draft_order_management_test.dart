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
import 'package:floraprise/models/storage_mode.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/screens/delivery_screen.dart';
import 'package:floraprise/screens/pickup_later_screen.dart';
import 'package:floraprise/screens/take_away_screen.dart';
import 'package:floraprise/services/pos_sale_sync_service.dart';
import 'package:floraprise/services/product_cloud_syncability_service.dart';
import 'package:floraprise/services/storage_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const currentCompanyId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const firstCloudId = '11111111-1111-4111-8111-111111111111';
const secondCloudId = '22222222-2222-4222-8222-222222222222';
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

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
    await StorageModeService().setMode(StorageMode.cloud);
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

  test('local storage Take Away sale succeeds without cloud product mapping', () async {
    await StorageModeService().setMode(StorageMode.local);
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final productId = await db.insert('products', {
      'name': 'Local Rose',
      'selling_price_paise': 10000,
      'track_inventory': 1,
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('inventory_items', {
      'product_id': productId,
      'current_qty': 3,
      'min_qty': 0,
      'updated_at': now,
    });
    final manager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    final confirmed = await manager.confirmOrder(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Local Storage Customer',
      lines: [
        WalkInLineItem(
          productId: productId,
          description: 'Local Rose',
          quantity: 1,
          unitPricePaise: 10000,
          gstPercent: 0,
          source: 'product',
        ),
      ],
      payments: const [
        PaymentSplit(
          method: PaymentMethod.cash,
          amountPaise: 10000,
          methodCode: 'cash',
        ),
      ],
    ));

    final order = (await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [confirmed.orderId],
    ))
        .single;
    final inventory = (await db.query(
      'inventory_items',
      where: 'product_id = ?',
      whereArgs: [productId],
    ))
        .single;

    expect(order['status'], 'confirmed');
    expect(order['fulfilment_type'], 'take_away');
    expect(inventory['current_qty'], 2);
    expect(await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [confirmed.orderId]), hasLength(1));
    expect(await PosSyncOutboxRepository().listPending(db), isEmpty);
  });

  test('local storage cash sale creates one local cash book cash-in entry', () async {
    final db = await AppDatabase.instance.database;
    final manager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    await manager.confirmOrder(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Cash Book Customer',
        lines: [
          WalkInLineItem(
            description: 'Cash Book Sale',
            quantity: 1,
            unitPricePaise: 60000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 60000,
            methodCode: 'cash',
          ),
        ],
      ),
    );

    final cashBookRows = await db.query('cash_book');
    expect(cashBookRows, hasLength(1));
    expect(cashBookRows.single['transaction_type'], 'cashSale');
    expect(cashBookRows.single['amount'], 60000);
    expect(cashBookRows.single['cash_in'], 60000);
    expect(cashBookRows.single['cash_out'], 0);
    expect(cashBookRows.single['running_balance'], 60000);
  });

  test('local storage non-cash sale creates no local cash book entry', () async {
    final db = await AppDatabase.instance.database;
    final manager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    await manager.confirmOrder(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'UPI Customer',
        lines: [
          WalkInLineItem(
            description: 'UPI Sale',
            quantity: 1,
            unitPricePaise: 60000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.upi,
            amountPaise: 60000,
            methodCode: 'upi',
          ),
        ],
      ),
    );

    expect(await db.query('cash_book'), isEmpty);
  });

  test('local storage split payment posts only cash portion to local cash book', () async {
    final db = await AppDatabase.instance.database;
    final manager = WalkInManager(
      customerManager: CustomerManager(CustomerRepository()),
      pricingManager: PricingManager(),
      orderManager: OrderManager(OrderRepository(), JobRepository()),
      inventoryManager: InventoryManager(InventoryRepository()),
      schedulerManager: SchedulerManager(SchedulerRepository()),
    );

    await manager.confirmOrder(
      const WalkInSession(
        fulfilmentType: FulfilmentType.takeAway,
        customerName: 'Split Customer',
        lines: [
          WalkInLineItem(
            description: 'Split Sale',
            quantity: 1,
            unitPricePaise: 60000,
            gstPercent: 0,
            source: 'manual',
          ),
        ],
        payments: [
          PaymentSplit(
            method: PaymentMethod.cash,
            amountPaise: 20000,
            methodCode: 'cash',
          ),
          PaymentSplit(
            method: PaymentMethod.upi,
            amountPaise: 40000,
            methodCode: 'upi',
          ),
        ],
      ),
    );

    final cashBookRows = await db.query('cash_book');
    expect(cashBookRows, hasLength(1));
    expect(cashBookRows.single['amount'], 20000);
    expect(cashBookRows.single['cash_in'], 20000);
    expect(cashBookRows.single['cash_out'], 0);
  });

  test('online sale submits cloud payload before local inventory mutation and does not enqueue outbox', () async {
    final db = await AppDatabase.instance.database;
    final productId = await _insertLinkedInventoryProduct(
      name: 'Cloud Rose',
      cloudProductId: firstCloudId,
      currentQty: 5,
    );
    final sentPayloads = <Map<String, dynamic>>[];
    final manager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      sentPayloads.add(payload);
      expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId])).single['current_qty'], 5);
      expect(await db.query('inventory_transactions'), isEmpty);
      expect(await PosSyncOutboxRepository().listPending(db), isEmpty);
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-online"}',
      );
    });

    final confirmed = await manager.confirmOnlineOrder(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Online Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'Cloud Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));

    expect(sentPayloads, hasLength(1));
    expect(sentPayloads.single['clientSyncId'], matches(_uuidPattern));
    expect((sentPayloads.single['inventoryTransactions'] as List).single['id'], isA<int>());
    expect(await PosSyncOutboxRepository().listPending(db), isEmpty);
    expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId])).single['current_qty'], 4);
    expect(await db.query('inventory_transactions', where: 'order_id = ?', whereArgs: [confirmed.orderId]), hasLength(1));
    final order = (await db.query('orders', where: 'id = ?', whereArgs: [confirmed.orderId])).single;
    expect(order['status'], 'confirmed');
    expect(order['marketplace_order_id'], 'cloud-order-online');
  });

  test('online new sale after completion gets a new ClientSyncId', () async {
    final productId = await _insertLinkedInventoryProduct(
      name: 'New Sale Rose',
      cloudProductId: firstCloudId,
      currentQty: 5,
    );
    final clientSyncIds = <Object?>[];
    final orderNumbers = <Object?>[];
    var cloudOrderSequence = 0;
    final manager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      clientSyncIds.add(payload['clientSyncId']);
      orderNumbers.add((payload['order'] as Map<String, dynamic>)['order_no']);
      cloudOrderSequence++;
      return PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-new-sale-$cloudOrderSequence"}',
      );
    });

    final first = await manager.confirmOnlineOrder(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'First Online Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'New Sale Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));
    final nextDraftOrderId = takeAwayDraftOrderIdForSessionSync(
      currentDraftOrderId: first.orderId,
      isOrderSaved: true,
    );
    final second = await manager.confirmOnlineOrder(WalkInSession(
      draftOrderId: nextDraftOrderId,
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Second Online Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'New Sale Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));

    expect(nextDraftOrderId, isNull);
    expect(first.orderId, isNot(second.orderId));
    expect(clientSyncIds.singleWhere((id) => id == clientSyncIds.first), matches(_uuidPattern));
    expect(clientSyncIds[1], matches(_uuidPattern));
    expect(clientSyncIds.first, isNot(clientSyncIds[1]));
    expect(orderNumbers[0], 'ORD-POS-${clientSyncIds[0]}');
    expect(orderNumbers[1], 'ORD-POS-${clientSyncIds[1]}');
    expect(orderNumbers.first, isNot(orderNumbers[1]));
  });

  test('Cloud POS order numbers cannot collide across reinstalls or devices', () {
    const firstInstallationSyncId = '11111111-1111-4111-8111-111111111111';
    const secondInstallationSyncId = '22222222-2222-4222-8222-222222222222';

    final firstOrderNumber = cloudPosOrderNumber(firstInstallationSyncId);
    final secondOrderNumber = cloudPosOrderNumber(secondInstallationSyncId);

    expect(firstOrderNumber, 'ORD-POS-$firstInstallationSyncId');
    expect(secondOrderNumber, 'ORD-POS-$secondInstallationSyncId');
    expect(firstOrderNumber, isNot(secondOrderNumber));
  });

  test('pickup later session sync clears completed sale ids and preserves unfinished retry ids', () {
    expect(
      pickupLaterSessionValueForSync<int>(
        currentValue: 42,
        isOrderSaved: true,
      ),
      isNull,
    );
    expect(
      pickupLaterSessionValueForSync<String>(
        currentValue: 'client-sync-42',
        isOrderSaved: true,
      ),
      isNull,
    );
    expect(
      pickupLaterSessionValueForSync<int>(
        currentValue: 42,
        isOrderSaved: false,
      ),
      42,
    );
    expect(
      pickupLaterSessionValueForSync<String>(
        currentValue: 'client-sync-42',
        isOrderSaved: false,
      ),
      'client-sync-42',
    );
  });

  test('delivery session sync clears completed sale ids and preserves unfinished retry ids', () {
    expect(
      deliverySessionValueForSync<int>(
        currentValue: 77,
        isOrderSaved: true,
      ),
      isNull,
    );
    expect(
      deliverySessionValueForSync<String>(
        currentValue: 'client-sync-77',
        isOrderSaved: true,
      ),
      isNull,
    );
    expect(
      deliverySessionValueForSync<int>(
        currentValue: 77,
        isOrderSaved: false,
      ),
      77,
    );
    expect(
      deliverySessionValueForSync<String>(
        currentValue: 'client-sync-77',
        isOrderSaved: false,
      ),
      'client-sync-77',
    );
  });

  test('online ClientSyncId is not reused when local order id is reused', () async {
    final db = await AppDatabase.instance.database;
    final manager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-reused-local-id"}',
      );
    });
    final productId = await _insertLinkedInventoryProduct(
      name: 'Reusable Id Rose',
      cloudProductId: firstCloudId,
      currentQty: 5,
    );
    final firstDraft = await manager.saveDraft(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'First Reused Id Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'Reusable Id Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));
    final firstSyncId = firstDraft.session.posClientSyncId;
    await db.delete('order_payments', where: 'order_id = ?', whereArgs: [firstDraft.session.draftOrderId]);
    await db.delete('order_lines', where: 'order_id = ?', whereArgs: [firstDraft.session.draftOrderId]);
    await db.delete('order_timeline_events', where: 'order_id = ?', whereArgs: [firstDraft.session.draftOrderId]);
    await db.delete('orders', where: 'id = ?', whereArgs: [firstDraft.session.draftOrderId]);
    await db.rawUpdate("UPDATE sqlite_sequence SET seq = ? WHERE name = 'orders'", [firstDraft.session.draftOrderId! - 1]);

    final secondDraft = await manager.saveDraft(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Second Reused Id Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'Reusable Id Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));

    expect(secondDraft.session.draftOrderId, firstDraft.session.draftOrderId);
    expect(firstSyncId, matches(_uuidPattern));
    expect(secondDraft.session.posClientSyncId, matches(_uuidPattern));
    expect(secondDraft.session.posClientSyncId, isNot(firstSyncId));
  });

  test('unfinished online sale preserves ClientSyncId across app session restart', () async {
    final manager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-restart"}',
      );
    });
    final productId = await _insertLinkedInventoryProduct(
      name: 'Restart Rose',
      cloudProductId: firstCloudId,
      currentQty: 5,
    );
    final draft = await manager.saveDraft(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Restart Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'Restart Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));
    final beforeRestart = draft.session.posClientSyncId;

    final restored = await _mappedOrderRepository().getDraftById(draft.session.draftOrderId!);
    final restartedManager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      expect(payload['clientSyncId'], beforeRestart);
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-restart"}',
      );
    });

    expect(restored, isNotNull);
    expect(beforeRestart, matches(_uuidPattern));
    expect(restored!.posClientSyncId, beforeRestart);
    await restartedManager.confirmOnlineOrder(restored);
  });

  test('online sale failure keeps draft and reuses ClientSyncId on retry', () async {
    final db = await AppDatabase.instance.database;
    final productId = await _insertLinkedInventoryProduct(
      name: 'Retry Rose',
      cloudProductId: firstCloudId,
      currentQty: 5,
    );
    final clientSyncIds = <Object?>[];
    var calls = 0;
    final manager = _onlineWalkInManager(sender: (uri, payloadJson, token) async {
      calls++;
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      clientSyncIds.add(payload['clientSyncId']);
      if (calls == 1) {
        return const PosSaleSyncHttpResponse(statusCode: 503, body: '{"error":"offline"}');
      }
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-retry"}',
      );
    });
    final draft = await manager.saveDraft(WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerName: 'Retry Customer',
      lines: [
        WalkInLineItem(productId: productId, description: 'Retry Rose', quantity: 1, unitPricePaise: 10000, gstPercent: 0, source: 'product'),
      ],
      payments: const [PaymentSplit(method: PaymentMethod.cash, amountPaise: 10000, methodCode: 'cash')],
    ));

    await expectLater(
      () => manager.confirmOnlineOrder(draft.session),
      throwsA(isA<StateError>()),
    );
    expect((await db.query('orders', where: 'id = ?', whereArgs: [draft.session.draftOrderId])).single['status'], 'draft');
    expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId])).single['current_qty'], 5);
    expect(await db.query('inventory_transactions'), isEmpty);
    expect(await PosSyncOutboxRepository().listPending(db), isEmpty);

    final confirmed = await manager.confirmOnlineOrder(draft.session);

    expect(clientSyncIds, [draft.session.posClientSyncId, draft.session.posClientSyncId]);
    expect(draft.session.posClientSyncId, matches(_uuidPattern));
    expect(confirmed.orderId, draft.session.draftOrderId);
    expect((await db.query('inventory_items', where: 'product_id = ?', whereArgs: [productId])).single['current_qty'], 4);
    expect(await PosSyncOutboxRepository().listPending(db), isEmpty);
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

WalkInManager _onlineWalkInManager({required PosSaleSyncSender sender}) {
  final orders = _mappedOrderRepository();
  return WalkInManager(
    customerManager: CustomerManager(CustomerRepository()),
    pricingManager: PricingManager(),
    orderManager: OrderManager(orders, JobRepository()),
    inventoryManager: InventoryManager(InventoryRepository()),
    schedulerManager: SchedulerManager(SchedulerRepository()),
    posSaleSyncService: PosSaleSyncService(
      readAccessToken: () async => 'access-token',
      sender: sender,
    ),
  );
}

Future<int> _insertLinkedInventoryProduct({
  required String name,
  required String cloudProductId,
  required int currentQty,
}) async {
  final db = await AppDatabase.instance.database;
  final now = DateTime.now().toIso8601String();
  final productId = await db.insert('products', {
    'name': name,
    'selling_price_paise': 10000,
    'track_inventory': 1,
    'cloud_product_id': cloudProductId,
    'cloud_product_company_id': currentCompanyId,
    'created_at': now,
    'updated_at': now,
  });
  await db.insert('inventory_items', {
    'product_id': productId,
    'current_qty': currentQty,
    'min_qty': 0,
    'updated_at': now,
  });
  return productId;
}
