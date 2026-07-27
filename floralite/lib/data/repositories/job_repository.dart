import 'dart:convert';

import '../database/app_database.dart';

class JobRepository {
  Future<void> enqueueReceiptJob(
      int orderId, Map<String, dynamic> payload) async {
    final db = await AppDatabase.instance.database;
    await db.insert('receipt_jobs', {
      'order_id': orderId,
      'payload_json': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> enqueueWhatsappJob(
      int orderId, Map<String, dynamic> payload) async {
    final db = await AppDatabase.instance.database;
    await db.insert('whatsapp_share_jobs', {
      'order_id': orderId,
      'payload_json': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> enqueueBarcodePrintJob({
    required int productId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await AppDatabase.instance.database;
    await db.insert('barcode_print_jobs', {
      'product_id': productId,
      'payload_json': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
