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
    await db.insert(
      'order_workflow_assignments',
      {
        'order_id': orderId,
        'assignment_type': assignmentType,
        'associate_id': associateId,
        'notes': notes,
        'assigned_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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

  const AssignmentRow({
    required this.orderId,
    required this.assignmentType,
    required this.associateId,
    this.notes,
    this.assignedAt,
  });
}
