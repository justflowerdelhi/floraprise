import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/customer_repository.dart';
import 'package:floraprise/data/repositories/inventory_repository.dart';
import 'package:floraprise/data/repositories/job_repository.dart';
import 'package:floraprise/data/repositories/order_repository.dart';
import 'package:floraprise/data/repositories/scheduler_repository.dart';
import 'package:floraprise/managers/customer_manager.dart';
import 'package:floraprise/managers/inventory_manager.dart';
import 'package:floraprise/managers/order_manager.dart';
import 'package:floraprise/managers/pricing_manager.dart';
import 'package:floraprise/managers/scheduler_manager.dart';
import 'package:floraprise/managers/walk_in_manager.dart';
import 'package:floraprise/models/payment_split.dart';
import 'package:floraprise/models/walk_in_enums.dart';
import 'package:floraprise/models/walk_in_line_item.dart';
import 'package:floraprise/models/walk_in_session.dart';
import 'package:floraprise/services/pos_sale_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  const authoritativeGuid1 = '11111111-1111-4111-8111-111111111111';
  const authoritativeGuid2 = '22222222-2222-4222-8222-222222222222';

  WalkInSession createTestSession({
    required List<WalkInLineItem> lines,
    List<PaymentSplit>? payments,
  }) {
    return WalkInSession(
      fulfilmentType: FulfilmentType.takeAway,
      customerPhone: '9876543210',
      customerName: 'Test Customer',
      lines: lines,
      payments: payments ??
          const [
            PaymentSplit(method: PaymentMethod.cash, amountPaise: 50000),
          ],
    );
  }

  group('Pro Web POS authoritative product ID', () {
    test('buildWebPosPayload includes authoritative product_id matching cloudProductId', () {
      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Red Roses Bouquet',
            quantity: 2,
            unitPricePaise: 25000,
            source: 'product',
          ),
        ],
      );

      final pricing = PricingManager();
      final totals = pricing.computeTotals(lines: session.lines);
      final now = DateTime.utc(2026, 9, 14, 12, 0, 0);

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_test_123',
        now: now,
      );

      final lines = payload['lines'] as List<Map<String, dynamic>>;
      expect(lines, hasLength(1));
      expect(lines[0]['product_id'], authoritativeGuid1);
      expect(lines[0]['cloudProductId'], authoritativeGuid1);
      expect(lines[0]['description'], 'Red Roses Bouquet');
      expect(lines[0]['qty'], 2);
      expect(lines[0]['unit_price_paise'], 25000);
      expect(lines[0]['source'], 'product');

      final inventory = payload['inventoryTransactions'] as List<Map<String, dynamic>>;
      expect(inventory, hasLength(1));
      expect(inventory[0]['product_id'], authoritativeGuid1);
      expect(inventory[0]['cloudProductId'], authoritativeGuid1);
      expect(inventory[0]['qty'], 2);
    });

    test('multiple cart lines retain distinct authoritative product IDs without collision or fabrication', () {
      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Rose Bunch',
            quantity: 1,
            unitPricePaise: 20000,
            source: 'product',
          ),
          WalkInLineItem(
            cloudProductId: authoritativeGuid2,
            description: 'Lily Bouquet',
            quantity: 3,
            unitPricePaise: 10000,
            source: 'product',
          ),
        ],
      );

      final pricing = PricingManager();
      final totals = pricing.computeTotals(lines: session.lines);
      final now = DateTime.utc(2026, 9, 14, 12, 0, 0);

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_test_distinct',
        now: now,
      );

      final lines = payload['lines'] as List<Map<String, dynamic>>;
      expect(lines, hasLength(2));
      expect(lines[0]['product_id'], authoritativeGuid1);
      expect(lines[0]['cloudProductId'], authoritativeGuid1);
      expect(lines[1]['product_id'], authoritativeGuid2);
      expect(lines[1]['cloudProductId'], authoritativeGuid2);
      expect(lines[0]['product_id'], isNot(equals(lines[1]['product_id'])));

      final inventory = payload['inventoryTransactions'] as List<Map<String, dynamic>>;
      expect(inventory, hasLength(2));
      expect(inventory[0]['product_id'], authoritativeGuid1);
      expect(inventory[0]['cloudProductId'], authoritativeGuid1);
      expect(inventory[1]['product_id'], authoritativeGuid2);
      expect(inventory[1]['cloudProductId'], authoritativeGuid2);
    });

    test('missing authoritative product ID fails before HTTP submission leaving cart intact', () async {
      final sessionWithMissingId = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: null, // missing authoritative ID
            description: 'Incomplete Product',
            quantity: 1,
            unitPricePaise: 50000,
            source: 'product',
          ),
        ],
      );

      final pricing = PricingManager();
      final totals = pricing.computeTotals(lines: sessionWithMissingId.lines);
      final now = DateTime.utc(2026, 9, 14, 12, 0, 0);

      expect(
        () => WalkInManager.buildWebPosPayload(
          session: sessionWithMissingId,
          totals: totals,
          ensuredCustomer: null,
          clientSyncId: 'web_test_fail',
          now: now,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Unable to complete sale because product information is incomplete.',
          ),
        ),
      );

      // Verify cart remains intact with all its lines
      expect(sessionWithMissingId.lines, hasLength(1));
      expect(sessionWithMissingId.lines[0].description, 'Incomplete Product');
    });

    test('custom non-catalog lines do not throw, do not fabricate product_id, and skip inventory deduction', () {
      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            description: 'Special Delivery & Greeting Card Service',
            quantity: 1,
            unitPricePaise: 50000,
            source: 'manual',
          ),
        ],
      );

      final pricing = PricingManager();
      final totals = pricing.computeTotals(lines: session.lines);
      final now = DateTime.utc(2026, 9, 14, 12, 0, 0);

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_test_custom',
        now: now,
      );

      final lines = payload['lines'] as List<Map<String, dynamic>>;
      expect(lines, hasLength(1));
      expect(lines[0].containsKey('product_id'), isFalse);
      expect(lines[0].containsKey('cloudProductId'), isFalse);
      expect(lines[0]['description'], 'Special Delivery & Greeting Card Service');

      final inventory = payload['inventoryTransactions'] as List<Map<String, dynamic>>;
      expect(inventory, isEmpty);
    });

    test('confirmOnlineOrder in web mode submits authoritative payload via PosSaleSyncService', () async {
      WalkInManager.debugForceWebMode = true;
      addTearDown(() => WalkInManager.debugForceWebMode = false);

      Map<String, dynamic>? submittedPayload;
      final fakeSyncService = PosSaleSyncService(
        readAccessToken: () async => 'test-token',
        sender: (uri, payloadJson, token) async {
          submittedPayload = jsonDecode(payloadJson) as Map<String, dynamic>;
          return const PosSaleSyncHttpResponse(
            statusCode: 200,
            body: '{"cloudOrderId":"cloud-order-1","cloudCustomerId":null}',
          );
        },
      );

      final manager = WalkInManager(
        customerManager: CustomerManager(CustomerRepository()),
        pricingManager: PricingManager(),
        orderManager: OrderManager(OrderRepository(), JobRepository()),
        inventoryManager: InventoryManager(InventoryRepository()),
        schedulerManager: SchedulerManager(SchedulerRepository()),
        posSaleSyncService: fakeSyncService,
      );

      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Red Roses',
            quantity: 1,
            unitPricePaise: 50000,
            source: 'product',
          ),
        ],
      );

      final result = await manager.confirmOnlineOrder(session);
      expect(result.grandTotalPaise, 50000);
      expect(submittedPayload, isNotNull);

      final lines = submittedPayload!['lines'] as List;
      expect(lines, hasLength(1));
      expect(lines[0]['product_id'], authoritativeGuid1);
      expect(lines[0]['cloudProductId'], authoritativeGuid1);

      final inventory = submittedPayload!['inventoryTransactions'] as List;
      expect(inventory, hasLength(1));
      expect(inventory[0]['product_id'], authoritativeGuid1);
      expect(inventory[0]['cloudProductId'], authoritativeGuid1);
    });
  });

  group('Pro Web POS numeric serialization, round-off, and paise integer contract', () {
    test('round_off_paise = 0 serializes as JSON integer 0, not 0.0 or -0.0', () {
      final pricing = PricingManager();
      // Total 500.00 -> 50000 paise (exact multiple of 100)
      final totals = pricing.computeTotals(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 2,
            unitPricePaise: 25000,
            source: 'product',
          ),
        ],
      );
      expect(totals.roundOffPaise, 0);

      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 2,
            unitPricePaise: 25000,
            source: 'product',
          ),
        ],
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_round_0',
        now: DateTime.utc(2026, 9, 14, 12, 0, 0),
      );

      final orderMap = payload['order'] as Map<String, dynamic>;
      expect(orderMap['round_off_paise'], 0);
      expect(orderMap['round_off_paise'], isA<int>());

      final serializedJson = jsonEncode(payload);
      // Verify integer 0 and not float 0.0 or -0.0
      expect(serializedJson, contains('"round_off_paise":0'));
      expect(serializedJson, isNot(contains('"round_off_paise":0.0')));
      expect(serializedJson, isNot(contains('"round_off_paise":-0.0')));
    });

    test('positive round-off serializes correctly as JSON integer', () {
      final pricing = PricingManager();
      // 49960 paise -> paise % 100 = 60 >= 50 -> round-off is +(100 - 60) = +40
      final totals = pricing.computeTotals(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 1,
            unitPricePaise: 49960,
            source: 'product',
          ),
        ],
      );
      expect(totals.roundOffPaise, 40);

      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 1,
            unitPricePaise: 49960,
            source: 'product',
          ),
        ],
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_round_pos',
        now: DateTime.utc(2026, 9, 14, 12, 0, 0),
      );

      final orderMap = payload['order'] as Map<String, dynamic>;
      expect(orderMap['round_off_paise'], 40);
      expect(orderMap['round_off_paise'], isA<int>());

      final serializedJson = jsonEncode(payload);
      expect(serializedJson, contains('"round_off_paise":40'));
      expect(serializedJson, isNot(contains('"round_off_paise":40.0')));
    });

    test('negative round-off serializes correctly as JSON integer', () {
      final pricing = PricingManager();
      // 50020 paise -> paise % 100 = 20 < 50 -> round-off is -20
      final totals = pricing.computeTotals(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 1,
            unitPricePaise: 50020,
            source: 'product',
          ),
        ],
      );
      expect(totals.roundOffPaise, -20);

      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 1,
            unitPricePaise: 50020,
            source: 'product',
          ),
        ],
      );
      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_round_neg',
        now: DateTime.utc(2026, 9, 14, 12, 0, 0),
      );

      final orderMap = payload['order'] as Map<String, dynamic>;
      expect(orderMap['round_off_paise'], -20);
      expect(orderMap['round_off_paise'], isA<int>());

      final serializedJson = jsonEncode(payload);
      expect(serializedJson, contains('"round_off_paise":-20'));
      expect(serializedJson, isNot(contains('"round_off_paise":-20.0')));
    });

    test('all numeric POS fields serialize strictly as integer tokens without floating point decimals', () {
      final pricing = PricingManager();
      final totals = pricing.computeTotals(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 3,
            unitPricePaise: 15000,
            source: 'product',
          ),
        ],
      );

      final session = createTestSession(
        lines: const [
          WalkInLineItem(
            cloudProductId: authoritativeGuid1,
            description: 'Roses',
            quantity: 3,
            unitPricePaise: 15000,
            source: 'product',
          ),
        ],
        payments: const [
          PaymentSplit(method: PaymentMethod.cash, amountPaise: 45000),
        ],
      );

      final payload = WalkInManager.buildWebPosPayload(
        session: session,
        totals: totals,
        ensuredCustomer: null,
        clientSyncId: 'web_numeric_all',
        now: DateTime.utc(2026, 9, 14, 12, 0, 0),
      );

      final order = payload['order'] as Map<String, dynamic>;
      expect(order['subtotal_paise'], isA<int>());
      expect(order['gst_total_paise'], isA<int>());
      expect(order['discount_total_paise'], isA<int>());
      expect(order['grand_total_paise'], isA<int>());
      expect(order['round_off_paise'], isA<int>());
      expect(order['reward_discount_amount_paise'], isA<int>());
      expect(order['reward_points_earned'], isA<int>());
      expect(order['reward_points_redeemed'], isA<int>());
      expect(order['is_paid'], isA<int>());

      final line = (payload['lines'] as List).first as Map<String, dynamic>;
      expect(line['id'], isA<int>());
      expect(line['qty'], isA<int>());
      expect(line['unit_price_paise'], isA<int>());
      expect(line['gst_percent'], isA<int>());
      expect(line['discount_paise'], isA<int>());
      expect(line['line_subtotal_paise'], isA<int>());
      expect(line['line_gst_paise'], isA<int>());
      expect(line['line_total_paise'], isA<int>());

      final payment = (payload['payments'] as List).first as Map<String, dynamic>;
      expect(payment['id'], isA<int>());
      expect(payment['amount_paise'], isA<int>());

      final inventory = (payload['inventoryTransactions'] as List).first as Map<String, dynamic>;
      expect(inventory['id'], isA<int>());
      expect(inventory['qty'], isA<int>());

      final serializedJson = jsonEncode(payload);
      final floatNumberPattern = RegExp(r'"(subtotal_paise|gst_total_paise|discount_total_paise|grand_total_paise|round_off_paise|reward_discount_amount_paise|qty|unit_price_paise|amount_paise)":\s*-?\d+\.\d+');
      expect(floatNumberPattern.hasMatch(serializedJson), isFalse);
    });
  });
}

