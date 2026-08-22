import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Repository for workflow-specific persistence that extends the
/// existing order infrastructure without changing the `orders` table.
///
/// Workflow assignments are stored in a dedicated `order_workflow_assignments`
/// table so the core order schema remains untouched.
class OrderWorkflowRepository {
  const OrderWorkflowRepository();

  Future<Database> get _db async => AppDatabase.instance.database;

  /// Records or replaces an assignment of an associate for a given workflow role.
  Future<void> assign({
    required int orderId,
    required String assignmentType,
    required int associateId,
    String? notes,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final existing = assignmentType == 'delivery'
        ? await db.query(
            'order_workflow_assignments',
            columns: ['backend_order_id', 'backend_delivery_id'],
            where: 'order_id = ? AND assignment_type = ?',
            whereArgs: [orderId, assignmentType],
            limit: 1,
          )
        : const <Map<String, Object?>>[];
    await db.insert(
      'order_workflow_assignments',
      {
        'order_id': orderId,
        'assignment_type': assignmentType,
        'associate_id': associateId,
        'notes': notes,
        'assigned_at': now,
        if (assignmentType == 'delivery') ...{
          'backend_order_id':
              existing.isEmpty ? null : existing.first['backend_order_id'],
          'backend_delivery_id':
              existing.isEmpty ? null : existing.first['backend_delivery_id'],
          'delivery_sync_status': 'pending',
          'delivery_sync_error': null,
          'delivery_sync_updated_at': now,
        },
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markDeliverySyncPending(int orderId) async {
    final db = await _db;
    await db.update(
      'order_workflow_assignments',
      {
        'delivery_sync_status': 'pending',
        'delivery_sync_error': null,
        'delivery_sync_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'order_id = ? AND assignment_type = ?',
      whereArgs: [orderId, 'delivery'],
    );
  }

  Future<void> markDeliverySyncFailed(int orderId, String error) async {
    final db = await _db;
    await db.update(
      'order_workflow_assignments',
      {
        'delivery_sync_status': 'failed',
        'delivery_sync_error': error,
        'delivery_sync_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'order_id = ? AND assignment_type = ?',
      whereArgs: [orderId, 'delivery'],
    );
  }

  Future<void> markDeliverySyncComplete({
    required int orderId,
    required String backendOrderId,
    required String backendDeliveryId,
  }) async {
    final db = await _db;
    await db.update(
      'order_workflow_assignments',
      {
        'backend_order_id': backendOrderId,
        'backend_delivery_id': backendDeliveryId,
        'delivery_sync_status': 'synced',
        'delivery_sync_error': null,
        'delivery_sync_updated_at': DateTime.now().toIso8601String(),
      },
      where: 'order_id = ? AND assignment_type = ?',
      whereArgs: [orderId, 'delivery'],
    );
  }

  /// Removes an assignment for a given order and type.
  Future<void> removeAssignment({
    required int orderId,
    required String assignmentType,
  }) async {
    final db = await _db;
    await db.delete(
      'order_workflow_assignments',
      where: 'order_id = ? AND assignment_type = ?',
      whereArgs: [orderId, assignmentType],
    );
  }

  /// Returns the current assignments for an order keyed by assignment_type.
  Future<Map<String, AssignmentRow>> getAssignments(int orderId) async {
    final db = await _db;
    final rows = await db.query(
      'order_workflow_assignments',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'assigned_at DESC',
    );
    final result = <String, AssignmentRow>{};
    for (final row in rows) {
      final type = row['assignment_type'] as String?;
      if (type == null || result.containsKey(type)) continue;
      result[type] = AssignmentRow(
        orderId: row['order_id'] as int? ?? orderId,
        assignmentType: type,
        associateId: row['associate_id'] as int? ?? 0,
        notes: row['notes'] as String?,
        assignedAt: row['assigned_at'] as String?,
        backendOrderId: row['backend_order_id'] as String?,
        backendDeliveryId: row['backend_delivery_id'] as String?,
        deliverySyncStatus:
            (row['delivery_sync_status'] as String?) ?? 'pending',
        deliverySyncError: row['delivery_sync_error'] as String?,
      );
    }
    return result;
  }

  /// Persists a workflow note without changing the status.
  Future<void> addWorkflowNote({
    required int orderId,
    required String note,
    required String createdBy,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    await db.insert('order_timeline_events', {
      'order_id': orderId,
      'status': 'workflow_note',
      'notes': note,
      'created_at': now,
      'created_by': createdBy,
    });
  }

  /// Returns the full timeline for an order including workflow notes.
  Future<List<Map<String, dynamic>>> getTimeline(int orderId) async {
    final db = await _db;
    return db.query(
      'order_timeline_events',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
  }
}

class AssignmentRow {
  final int orderId;
  final String assignmentType;
  final int associateId;
  final String? notes;
  final String? assignedAt;
  final String? backendOrderId;
  final String? backendDeliveryId;
  final String deliverySyncStatus;
  final String? deliverySyncError;

  const AssignmentRow({
    required this.orderId,
    required this.assignmentType,
    required this.associateId,
    this.notes,
    this.assignedAt,
    this.backendOrderId,
    this.backendDeliveryId,
    this.deliverySyncStatus = 'pending',
    this.deliverySyncError,
  });
}
