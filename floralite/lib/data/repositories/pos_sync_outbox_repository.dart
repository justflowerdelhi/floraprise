import 'dart:convert';
import 'dart:math';

import 'package:sqflite/sqflite.dart';

class PosSyncOutboxRecord {
  const PosSyncOutboxRecord({
    required this.id,
    required this.clientSyncId,
    required this.localOrderId,
    required this.payload,
    required this.state,
  });

  final int id;
  final String clientSyncId;
  final int localOrderId;
  final Map<String, dynamic> payload;
  final String state;
}

class PosSyncOutboxRepository {
  static const operationTypeCompletedSale = 'completed_pos_sale';
  static const statePending = 'pending';

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
    return rows.map((row) => PosSyncOutboxRecord(
      id: row['id'] as int,
      clientSyncId: row['client_sync_id'] as String,
      localOrderId: row['local_order_id'] as int,
      payload: (jsonDecode(row['payload_json'] as String) as Map).cast<String, dynamic>(),
      state: row['state'] as String,
    )).toList();
  }
}
