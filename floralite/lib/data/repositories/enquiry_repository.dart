import '../../models/crm_models.dart';
import '../database/app_database.dart';

class EnquiryRepository {
  EnquiryRepository();

  Future<CrmEnquiryItem> create(CrmEnquiryItem item) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final clientSyncId = item.clientSyncId.trim().isNotEmpty
        ? item.clientSyncId.trim()
        : generateClientSyncId();

    final row = {
      'cloud_id': item.cloudId,
      'client_sync_id': clientSyncId,
      'customer_id': item.customerId,
      'cloud_customer_id': item.cloudCustomerId,
      'customer_name': item.customerName.trim(),
      'customer_phone': item.customerPhone.trim(),
      'category': item.category.trim().isNotEmpty ? item.category.trim() : 'General',
      'requirement': item.requirement.trim(),
      'event_date': item.eventDate?.toIso8601String(),
      'budget_paise': item.budgetPaise,
      'location': item.location?.trim(),
      'notes': item.notes?.trim(),
      'status': item.status.trim().isNotEmpty ? item.status.trim() : 'new',
      'next_action': item.nextAction.trim().isNotEmpty ? item.nextAction.trim() : 'Follow-up with customer',
      'next_follow_up_at': item.nextFollowUpAt?.toIso8601String(),
      'quote_order_id': item.quoteOrderId,
      'converted_order_id': item.convertedOrderId,
      'lost_reason': item.lostReason?.trim(),
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': now.toIso8601String(),
      'deleted_at': null,
    };

    final id = await db.insert('crm_enquiries', row);
    return item.copyWith(
      localId: id,
      clientSyncId: clientSyncId,
      updatedAt: now,
    );
  }

  Future<List<CrmEnquiryItem>> listEnquiries({
    String? status,
    String? query,
    DateTime? eventDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await AppDatabase.instance.database;
    final whereClauses = <String>['deleted_at IS NULL'];
    final whereArgs = <Object>[];

    if (status != null && status.trim().isNotEmpty && status.trim().toLowerCase() != 'all') {
      whereClauses.add('LOWER(status) = ?');
      whereArgs.add(status.trim().toLowerCase());
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = '%${query.trim().toLowerCase()}%';
      whereClauses.add(
        '(LOWER(customer_name) LIKE ? OR LOWER(customer_phone) LIKE ? OR LOWER(requirement) LIKE ? OR LOWER(category) LIKE ? OR LOWER(COALESCE(location, \'\')) LIKE ?)',
      );
      whereArgs.addAll([q, q, q, q, q]);
    }

    if (eventDate != null) {
      final datePrefix = '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
      whereClauses.add('event_date LIKE ?');
      whereArgs.add('$datePrefix%');
    }

    final whereString = whereClauses.join(' AND ');

    final rows = await db.query(
      'crm_enquiries',
      where: whereString,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map((r) => CrmEnquiryItem.fromSqlite(r)).toList();
  }

  Future<CrmEnquiryItem?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'crm_enquiries',
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return CrmEnquiryItem.fromSqlite(rows.first);
  }

  Future<CrmEnquiryItem?> getByClientSyncId(String clientSyncId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'crm_enquiries',
      where: 'client_sync_id = ? AND deleted_at IS NULL',
      whereArgs: [clientSyncId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return CrmEnquiryItem.fromSqlite(rows.first);
  }

  Future<CrmEnquiryItem> update(CrmEnquiryItem item) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final row = {
      if (item.cloudId != null) 'cloud_id': item.cloudId,
      if (item.customerId != null) 'customer_id': item.customerId,
      if (item.cloudCustomerId != null) 'cloud_customer_id': item.cloudCustomerId,
      'customer_name': item.customerName.trim(),
      'customer_phone': item.customerPhone.trim(),
      'category': item.category.trim(),
      'requirement': item.requirement.trim(),
      'event_date': item.eventDate?.toIso8601String(),
      'budget_paise': item.budgetPaise,
      'location': item.location?.trim(),
      'notes': item.notes?.trim(),
      'status': item.status.trim(),
      'next_action': item.nextAction.trim(),
      'next_follow_up_at': item.nextFollowUpAt?.toIso8601String(),
      'quote_order_id': item.quoteOrderId,
      'converted_order_id': item.convertedOrderId,
      'lost_reason': item.lostReason?.trim(),
      'updated_at': now.toIso8601String(),
    };

    if (item.localId != null) {
      await db.update(
        'crm_enquiries',
        row,
        where: 'id = ?',
        whereArgs: [item.localId],
      );
    } else {
      await db.update(
        'crm_enquiries',
        row,
        where: 'client_sync_id = ?',
        whereArgs: [item.clientSyncId],
      );
    }

    return item.copyWith(updatedAt: now);
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'crm_enquiries',
      {
        'deleted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<CrmEnquiryItem>> getTodayNewEnquiries(DateTime today) async {
    final db = await AppDatabase.instance.database;
    final datePrefix = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final rows = await db.query(
      'crm_enquiries',
      where: 'deleted_at IS NULL AND (created_at LIKE ? OR status IN (\'new\', \'follow_up\'))',
      whereArgs: ['$datePrefix%'],
      orderBy: 'created_at DESC',
      limit: 50,
    );

    return rows.map((r) => CrmEnquiryItem.fromSqlite(r)).toList();
  }
}
