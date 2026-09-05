import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

class PosSyncOutboxRecord {
  const PosSyncOutboxRecord({
    required this.id,
    required this.clientSyncId,
    required this.localOrderId,
    required this.payload,
    required this.payloadJson,
    required this.state,
    required this.attemptCount,
  });

  final int id;
  final String clientSyncId;
  final int localOrderId;
  final Map<String, dynamic> payload;
  final String payloadJson;
  final String state;
  final int attemptCount;
}

class PosSyncOutboxRepository {
  static const operationTypeCompletedSale = 'completed_pos_sale';
  static const statePending = 'pending';
  static const stateCompleted = 'completed';

  String newClientSyncId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  Future<int> enqueueInTransaction({
    required Transaction transaction,
    required String clientSyncId,
    required int localOrderId,
    required Map<String, dynamic> payload,
    required String completedAt,
  }) {
    return transaction.insert('pos_sync_outbox', {
      'operation_type': operationTypeCompletedSale,
      'client_sync_id': clientSyncId,
      'local_order_id': localOrderId,
      'payload_json': jsonEncode(payload),
      'state': statePending,
      'attempt_count': 0,
      'completed_at': completedAt,
      'created_at': completedAt,
      'updated_at': completedAt,
    });
  }

  Future<List<PosSyncOutboxRecord>> listPending(DatabaseExecutor db) async {
    final rows = await db.query('pos_sync_outbox', where: 'state = ?', whereArgs: [statePending]);
    return rows.map(_recordFromRow).toList();
  }

  Future<List<PosSyncOutboxRecord>> listRetryable(DatabaseExecutor db) async {
    final now = DateTime.now().toIso8601String();
    final rows = await db.query(
      'pos_sync_outbox',
      where: "state = ? AND (next_attempt_at IS NULL OR next_attempt_at <= ?)",
      whereArgs: [statePending, now],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(_recordFromRow).toList();
  }

  Future<void> markCompleted({
    required int id,
    required String cloudOrderId,
    String? cloudCustomerId,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'pos_sync_outbox',
      {
        'state': stateCompleted,
        'cloud_order_id': cloudOrderId,
        'cloud_customer_id': cloudCustomerId,
        'completed_at': now,
        'last_attempt_at': now,
        'last_error': null,
        'next_attempt_at': null,
        'updated_at': now,
      },
      where: 'id = ? AND state <> ?',
      whereArgs: [id, stateCompleted],
    );
  }

  Future<void> markRetryableFailure({
    required int id,
    required int previousAttemptCount,
    required Object error,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final attemptCount = previousAttemptCount + 1;
    final delayMinutes = attemptCount.clamp(1, 30);
    await db.update(
      'pos_sync_outbox',
      {
        'state': statePending,
        'attempt_count': attemptCount,
        'last_attempt_at': now,
        'next_attempt_at': DateTime.now()
            .add(Duration(minutes: delayMinutes))
            .toIso8601String(),
        'last_error': error.toString(),
        'updated_at': now,
      },
      where: 'id = ? AND state = ?',
      whereArgs: [id, statePending],
    );
  }

  PosSyncOutboxRecord _recordFromRow(Map<String, Object?> row) {
    final payloadJson = row['payload_json'] as String;
    Map<String, dynamic> payload;
    try {
      payload = (jsonDecode(payloadJson) as Map).cast<String, dynamic>();
    } catch (_) {
      payload = const {};
    }
    return PosSyncOutboxRecord(
      id: row['id'] as int,
      clientSyncId: row['client_sync_id'] as String,
      localOrderId: row['local_order_id'] as int,
      payload: payload,
      payloadJson: payloadJson,
      state: row['state'] as String,
      attemptCount: row['attempt_count'] as int? ?? 0,
    );
  }
}
