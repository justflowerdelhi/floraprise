import 'dart:convert';

import 'package:floraprise/data/database/app_database.dart';
import 'package:floraprise/data/repositories/pos_sync_outbox_repository.dart';
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

  test('pending outbox uploads successfully and marks completed', () async {
    final outboxId = await _insertOutbox(localOrderId: 1);
    final sentPayloads = <String>[];
    final service = _service(sender: (uri, payloadJson, token) async {
      sentPayloads.add(payloadJson);
      expect(uri.path, '/api/v1/mobile/pos-sales/sync');
      expect(token, 'access-token');
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"cloud-order-1","cloudCustomerId":"cloud-customer-1"}',
      );
    });

    final result = await service.syncPending();

    expect(result.processedCount, 1);
    expect(result.completedCount, 1);
    expect(result.failedCount, 0);
    expect(sentPayloads.single, _payloadJson(localOrderId: 1));
    final row = await _outbox(outboxId);
    expect(row['state'], PosSyncOutboxRepository.stateCompleted);
    expect(row['cloud_order_id'], 'cloud-order-1');
    expect(row['cloud_customer_id'], 'cloud-customer-1');
    expect(row['client_sync_id'], 'client-sync-1');
  });

  test('network failure preserves pending state and payload', () async {
    final outboxId = await _insertOutbox(localOrderId: 1);
    final service = _service(sender: (uri, payloadJson, token) async {
      throw StateError('network unavailable');
    });

    final result = await service.syncPending();

    expect(result.failedCount, 1);
    final row = await _outbox(outboxId);
    expect(row['state'], PosSyncOutboxRepository.statePending);
    expect(row['attempt_count'], 1);
    expect(row['payload_json'], _payloadJson(localOrderId: 1));
    expect(row['last_error'].toString(), contains('network unavailable'));
    expect(row['next_attempt_at'], isNotNull);
  });

  test('401 refresh uses existing auth refresh path once', () async {
    await _insertOutbox(localOrderId: 1);
    final tokens = <String>[];
    var refreshCount = 0;
    final service = _service(
      refreshAccessToken: () async {
        refreshCount++;
        return 'refreshed-token';
      },
      sender: (uri, payloadJson, token) async {
        tokens.add(token);
        if (tokens.length == 1) {
          return const PosSaleSyncHttpResponse(statusCode: 401, body: '{}');
        }
        return const PosSaleSyncHttpResponse(
          statusCode: 200,
          body: '{"cloudOrderId":"cloud-order-1"}',
        );
      },
    );

    final result = await service.syncPending();

    expect(result.completedCount, 1);
    expect(refreshCount, 1);
    expect(tokens, ['access-token', 'refreshed-token']);
  });

  test('repeated same clientSyncId response is safe and idempotent locally', () async {
    await _insertOutbox(localOrderId: 1);
    var calls = 0;
    final service = _service(sender: (uri, payloadJson, token) async {
      calls++;
      return const PosSaleSyncHttpResponse(
        statusCode: 200,
        body: '{"cloudOrderId":"same-cloud-order"}',
      );
    });

    final first = await service.syncPending();
    final second = await service.syncPending();

    expect(first.completedCount, 1);
    expect(second.processedCount, 0);
    expect(calls, 1);
    final rows = await _allOutbox();
    expect(rows.single['state'], PosSyncOutboxRepository.stateCompleted);
    expect(rows.single['cloud_order_id'], 'same-cloud-order');
  });

  test('multiple pending records are processed independently', () async {
    await _insertOutbox(localOrderId: 1);
    await _insertOutbox(localOrderId: 2);
    final service = _service(sender: (uri, payloadJson, token) async {
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      if (payload['localOrderId'] == 1) {
        return const PosSaleSyncHttpResponse(
          statusCode: 200,
          body: '{"cloudOrderId":"cloud-order-1"}',
        );
      }
      return const PosSaleSyncHttpResponse(statusCode: 503, body: '{}');
    });

    final result = await service.syncPending();

    expect(result.processedCount, 2);
    expect(result.completedCount, 1);
    expect(result.failedCount, 1);
    final rows = await _allOutbox();
    expect(rows.firstWhere((row) => row['local_order_id'] == 1)['state'], 'completed');
    expect(rows.firstWhere((row) => row['local_order_id'] == 2)['state'], 'pending');
    expect(
      rows.firstWhere((row) => row['local_order_id'] == 2)['last_error'].toString(),
      contains('Body: {}'),
    );
  });

  test('malformed payload does not corrupt local sale or lose payload', () async {
    final db = await AppDatabase.instance.database;
    final orderId = await _insertOrder();
    final now = DateTime.now().toIso8601String();
    final outboxId = await db.insert('pos_sync_outbox', {
      'operation_type': PosSyncOutboxRepository.operationTypeCompletedSale,
      'client_sync_id': 'bad-payload',
      'local_order_id': orderId,
      'payload_json': '{bad json',
      'state': PosSyncOutboxRepository.statePending,
      'attempt_count': 0,
      'created_at': now,
      'updated_at': now,
    });
    final service = _service(sender: (uri, payloadJson, token) async {
      expect(payloadJson, '{bad json');
      return const PosSaleSyncHttpResponse(statusCode: 400, body: '{}');
    });

    final result = await service.syncPending();

    expect(result.failedCount, 1);
    final order = await db.query('orders', where: 'id = ?', whereArgs: [orderId]);
    final outbox = await _outbox(outboxId);
    expect(order.single['status'], 'confirmed');
    expect(outbox['state'], PosSyncOutboxRepository.statePending);
    expect(outbox['payload_json'], '{bad json');
    expect(outbox['attempt_count'], 1);
  });
}

PosSaleSyncService _service({
  required PosSaleSyncSender sender,
  PosSaleAccessTokenRefresher? refreshAccessToken,
}) {
  return PosSaleSyncService(
    readAccessToken: () async => 'access-token',
    refreshAccessToken: refreshAccessToken,
    sender: sender,
  );
}

Future<int> _insertOrder() async {
  final db = await AppDatabase.instance.database;
  final now = DateTime.now().toIso8601String();
  return db.insert('orders', {
    'order_no': 'ORD-${DateTime.now().microsecondsSinceEpoch}',
    'fulfilment_type': 'take_away',
    'status': 'confirmed',
    'grand_total_paise': 60000,
    'created_at': now,
    'updated_at': now,
    'confirmed_at': now,
  });
}

Future<int> _insertOutbox({required int localOrderId}) async {
  final db = await AppDatabase.instance.database;
  final orderId = await _insertOrder();
  final now = DateTime.now().toIso8601String();
  return db.insert('pos_sync_outbox', {
    'operation_type': PosSyncOutboxRepository.operationTypeCompletedSale,
    'client_sync_id': 'client-sync-$localOrderId',
    'local_order_id': orderId,
    'payload_json': _payloadJson(localOrderId: localOrderId),
    'state': PosSyncOutboxRepository.statePending,
    'attempt_count': 0,
    'created_at': now,
    'updated_at': now,
  });
}

String _payloadJson({required int localOrderId}) => jsonEncode({
      'clientSyncId': 'client-sync-$localOrderId',
      'localOrderId': localOrderId,
      'order': {
        'order_no': 'ORD-$localOrderId',
        'subtotal_paise': 60000,
        'gst_total_paise': 0,
        'discount_total_paise': 0,
        'grand_total_paise': 60000,
        'round_off_paise': 0,
        'reward_discount_amount_paise': 0,
        'is_paid': 1,
      },
      'lines': [
        {
          'id': 10 + localOrderId,
          'product_id': 1,
          'localProductId': 1,
          'cloudProductId': '0952579a-dc73-4b94-ae56-dc7d6b0ecfcf',
          'description': 'Red Roses',
          'qty': 20,
          'unit_price_paise': 3000,
          'gst_percent': 0,
          'discount_paise': 0,
          'line_subtotal_paise': 60000,
          'line_gst_paise': 0,
          'line_total_paise': 60000,
          'source': 'product',
        }
      ],
      'payments': [
        {'id': 1, 'method': 'cash', 'amount_paise': 60000}
      ],
      'inventoryTransactions': [
        {
          'id': 100 + localOrderId,
          'product_id': 1,
          'localProductId': 1,
          'cloudProductId': '0952579a-dc73-4b94-ae56-dc7d6b0ecfcf',
          'qty': 20,
          'txn_type': 'sale',
        }
      ],
    });

Future<Map<String, Object?>> _outbox(int id) async {
  final db = await AppDatabase.instance.database;
  final rows = await db.query('pos_sync_outbox', where: 'id = ?', whereArgs: [id]);
  return rows.single;
}

Future<List<Map<String, Object?>>> _allOutbox() async {
  final db = await AppDatabase.instance.database;
  return db.query('pos_sync_outbox', orderBy: 'local_order_id ASC');
}
