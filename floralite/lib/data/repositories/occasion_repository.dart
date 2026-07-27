import '../database/app_database.dart';

class OccasionContactRecord {
  final int id;
  final int customerId;
  final String customerName;
  final String customerPhone;
  final String recipientName;
  final String relationship;
  final String occasion;
  final DateTime occasionDate;
  final String recipientPhone;
  final String company;
  final String notes;
  final bool reminderEnabled;
  final String source;
  final String createdAt;
  final String updatedAt;

  const OccasionContactRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.recipientName,
    required this.relationship,
    required this.occasion,
    required this.occasionDate,
    required this.recipientPhone,
    required this.company,
    required this.notes,
    required this.reminderEnabled,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });
}

class OccasionFollowUpRecord {
  final String sourceType;
  final int sourceId;
  final DateTime date;
  final String title;
  final String subtitle;
  final String category;
  final String customerPhone;
  final String recipientPhone;
  final int? customerId;
  final int? orderId;
  final bool isCompleted;
  final bool isManual;

  const OccasionFollowUpRecord({
    required this.sourceType,
    required this.sourceId,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.customerPhone,
    this.recipientPhone = '',
    required this.customerId,
    required this.orderId,
    required this.isCompleted,
    required this.isManual,
  });
}

class OccasionScreenData {
  final List<OccasionFollowUpRecord> today;
  final List<OccasionFollowUpRecord> upcoming;
  final List<OccasionFollowUpRecord> completed;
  final List<OccasionFollowUpRecord> festival;

  const OccasionScreenData({
    required this.today,
    required this.upcoming,
    required this.completed,
    required this.festival,
  });
}

class OccasionDashboardSummary {
  final int todayFollowUps;
  final int birthdayCount;
  final int festivalCount;
  final int pendingPayments;

  const OccasionDashboardSummary({
    required this.todayFollowUps,
    required this.birthdayCount,
    required this.festivalCount,
    required this.pendingPayments,
  });

  static const empty = OccasionDashboardSummary(
    todayFollowUps: 0,
    birthdayCount: 0,
    festivalCount: 0,
    pendingPayments: 0,
  );
}

class OccasionRepository {
  Future<List<String>> listRelationshipMaster() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'relationship_master',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((r) => (r['name'] as String?) ?? '').toList();
  }

  Future<List<String>> listOccasionMaster() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'occasion_master',
      where: 'deleted_at IS NULL AND is_active = 1',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((r) => (r['name'] as String?) ?? '').toList();
  }

  Future<int?> findCustomerIdByNameOrPhone({
    required String customerName,
    required String mobile,
  }) async {
    final db = await AppDatabase.instance.database;
    final normalizedMobile = _normalizePhone(mobile);

    if (normalizedMobile.length == 10) {
      final byPhone = await db.query(
        'customers',
        columns: ['id'],
        where: 'phone = ? AND deleted_at IS NULL',
        whereArgs: [normalizedMobile],
        limit: 1,
      );
      if (byPhone.isNotEmpty) {
        return byPhone.first['id'] as int;
      }
    }

    final trimmedName = customerName.trim().toLowerCase();
    if (trimmedName.isEmpty) {
      return null;
    }

    final byName = await db.query(
      'customers',
      columns: ['id'],
      where: 'LOWER(name) = ? AND deleted_at IS NULL',
      whereArgs: [trimmedName],
      limit: 1,
    );
    if (byName.isNotEmpty) {
      return byName.first['id'] as int;
    }

    return null;
  }

  Future<OccasionContactRecord?> createContact({
    required int customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String recipientPhone = '',
    String company = '',
    String notes = '',
    bool reminderEnabled = true,
    String source = 'Manual',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final id = await db.insert('occasion_contacts', {
      'customer_id': customerId == 0 ? null : customerId,
      'recipient_name': recipientName.trim(),
      'normalized_recipient_name': recipientName.trim().toLowerCase(),
      'relationship': relationship.trim(),
      'occasion': occasion.trim(),
      'normalized_occasion': occasion.trim().toLowerCase(),
      'occasion_date': occasionDate.toIso8601String(),
      'recipient_phone': recipientPhone.trim().isEmpty
          ? null
          : _normalizePhone(recipientPhone),
      'company': company.trim().isEmpty ? null : company.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'source': source,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
    });

    return getContactById(id);
  }

  Future<OccasionContactRecord?> updateContact({
    required int id,
    required int customerId,
    required String recipientName,
    required String relationship,
    required String occasion,
    required DateTime occasionDate,
    String recipientPhone = '',
    String company = '',
    String notes = '',
    bool reminderEnabled = true,
    String source = 'Manual',
  }) async {
    final db = await AppDatabase.instance.database;

    // Get current record to compare
    final current = await getContactById(id);
    if (current == null) {
      throw Exception('Reminder not found.');
    }

    // Only check for duplicates if the key fields are changing
    final recipientChanged = current.recipientName.trim().toLowerCase() !=
        recipientName.trim().toLowerCase();
    final occasionChanged =
        current.occasion.trim().toLowerCase() != occasion.trim().toLowerCase();
    final customerChanged = current.customerId != customerId;

    if (recipientChanged || occasionChanged || customerChanged) {
      // Check if the new combination already exists (excluding current record)
      final existing = await db.rawQuery(
        '''
        SELECT id FROM occasion_contacts
        WHERE customer_id = ?
          AND normalized_recipient_name = ?
          AND normalized_occasion = ?
          AND id != ?
          AND deleted_at IS NULL
        LIMIT 1
        ''',
        [
          customerId,
          recipientName.trim().toLowerCase(),
          occasion.trim().toLowerCase(),
          id,
        ],
      );

      if (existing.isNotEmpty) {
        // Delete the existing duplicate record since user wants to replace it
        final existingId = existing.first['id'] as int;
        await softDeleteContact(existingId);
      }
    }

    await db.update(
      'occasion_contacts',
      {
        'customer_id': customerId,
        'recipient_name': recipientName.trim(),
        'normalized_recipient_name': recipientName.trim().toLowerCase(),
        'relationship': relationship.trim(),
        'occasion': occasion.trim(),
        'normalized_occasion': occasion.trim().toLowerCase(),
        'occasion_date': occasionDate.toIso8601String(),
        'recipient_phone': recipientPhone.trim().isEmpty
            ? null
            : _normalizePhone(recipientPhone),
        'company': company.trim().isEmpty ? null : company.trim(),
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'reminder_enabled': reminderEnabled ? 1 : 0,
        'source': source,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );

    return getContactById(id);
  }

  Future<void> softDeleteContact(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'occasion_contacts',
      {'deleted_at': now, 'updated_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<OccasionContactRecord?> getDuplicateContact({
    required int customerId,
    required String recipientName,
    required String occasion,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT oc.id
      FROM occasion_contacts oc
      WHERE oc.customer_id = ?
        AND oc.normalized_recipient_name = ?
        AND oc.normalized_occasion = ?
        AND oc.deleted_at IS NULL
      LIMIT 1
      ''',
      [
        customerId,
        recipientName.trim().toLowerCase(),
        occasion.trim().toLowerCase(),
      ],
    );
    if (rows.isEmpty) {
      return null;
    }
    return getContactById(rows.first['id'] as int);
  }

  Future<List<OccasionContactRecord>> listContacts({
    String search = '',
    String filter = 'All',
    DateTime? specificDate,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>['oc.deleted_at IS NULL'];
    final args = <Object?>[];

    // Handle specific date filter from calendar picker
    if (specificDate != null) {
      final specificDateOnly =
          DateTime(specificDate.year, specificDate.month, specificDate.day);
      where.add('DATE(oc.occasion_date) = DATE(?)');
      args.add(specificDateOnly.toIso8601String());
    } else {
      // Handle date-based filters
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final tomorrow = todayDate.add(const Duration(days: 1));
      final next3Days = todayDate.add(const Duration(days: 3));
      final next7Days = todayDate.add(const Duration(days: 7));

      if (filter == 'Today') {
        where.add('DATE(oc.occasion_date) = DATE(?)');
        args.add(todayDate.toIso8601String());
      } else if (filter == 'Tomorrow') {
        where.add('DATE(oc.occasion_date) = DATE(?)');
        args.add(tomorrow.toIso8601String());
      } else if (filter == 'Next 3 Days') {
        where.add(
            'DATE(oc.occasion_date) >= DATE(?) AND DATE(oc.occasion_date) <= DATE(?)');
        args.add(todayDate.toIso8601String());
        args.add(next3Days.toIso8601String());
      } else if (filter == 'Next 7 Days') {
        where.add(
            'DATE(oc.occasion_date) >= DATE(?) AND DATE(oc.occasion_date) <= DATE(?)');
        args.add(todayDate.toIso8601String());
        args.add(next7Days.toIso8601String());
      } else if (filter != 'All' &&
          filter != 'Festival' &&
          filter != 'Payment' &&
          filter != 'Delivery' &&
          filter != 'General') {
        // Handle occasion-based filters (Birthday, Anniversary, etc.)
        where.add('oc.occasion = ?');
        args.add(filter);
      }
    }

    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      where.add('''(
        LOWER(COALESCE(c.name, '')) LIKE ?
        OR LOWER(COALESCE(c.phone, '')) LIKE ?
        OR LOWER(oc.recipient_name) LIKE ?
        OR LOWER(COALESCE(oc.recipient_phone, '')) LIKE ?
        OR LOWER(oc.occasion) LIKE ?
        OR LOWER(oc.relationship) LIKE ?
        OR LOWER(COALESCE(oc.notes, '')) LIKE ?
      )''');
      final pattern = '%$q%';
      args
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern)
        ..add(pattern);
    }

    final rows = await db.rawQuery(
      '''
      SELECT
        oc.id,
        oc.customer_id,
        c.name AS customer_name,
        c.phone AS customer_phone,
        oc.recipient_name,
        oc.relationship,
        oc.occasion,
        oc.occasion_date,
        oc.recipient_phone,
        oc.company,
        oc.notes,
        oc.reminder_enabled,
        oc.source,
        oc.created_at,
        oc.updated_at
      FROM occasion_contacts oc
      LEFT JOIN customers c ON c.id = oc.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY oc.occasion_date ASC
      ''',
      args,
    );

    return rows.map(_mapContact).toList();
  }

  Future<OccasionContactRecord?> getContactById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT
        oc.id,
        oc.customer_id,
        c.name AS customer_name,
        c.phone AS customer_phone,
        oc.recipient_name,
        oc.relationship,
        oc.occasion,
        oc.occasion_date,
        oc.recipient_phone,
        oc.company,
        oc.notes,
        oc.reminder_enabled,
        oc.source,
        oc.created_at,
        oc.updated_at
      FROM occasion_contacts oc
      LEFT JOIN customers c ON c.id = oc.customer_id
      WHERE oc.id = ? AND oc.deleted_at IS NULL
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) {
      return null;
    }
    return _mapContact(rows.first);
  }

  Future<List<DateTime>> getReminderDatesInMonth(DateTime month) async {
    final db = await AppDatabase.instance.database;
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT DATE(occasion_date) as date
      FROM occasion_contacts
      WHERE deleted_at IS NULL
        AND reminder_enabled = 1
        AND DATE(occasion_date) >= DATE(?)
        AND DATE(occasion_date) <= DATE(?)
      ORDER BY date ASC
      ''',
      [firstDay.toIso8601String(), lastDay.toIso8601String()],
    );

    return rows.map((row) {
      final dateStr = row['date'] as String;
      return DateTime.parse(dateStr);
    }).toList();
  }

  Future<OccasionScreenData> buildScreenData({
    required DateTime today,
    String search = '',
    String filter = 'All',
    DateTime? specificDate,
  }) async {
    final contacts = await listContacts(
        search: search, filter: filter, specificDate: specificDate);
    final payments = await _pendingPaymentFollowUps(today: today);
    final deliveries = await _pendingDeliveryFollowUps(today: today);
    final festivals = await _festivalFollowUps(today: today);

    final all = <OccasionFollowUpRecord>[];
    all.addAll(contacts.map(_contactToFollowUp));
    all.addAll(payments);
    all.addAll(deliveries);
    all.addAll(festivals);

    final resolved = <OccasionFollowUpRecord>[];
    for (final item in all) {
      final adjusted = await _applyFollowUpAction(item);
      if (adjusted != null) {
        resolved.add(adjusted);
      }
    }

    final todayDate = DateTime(today.year, today.month, today.day);
    final todayItems = <OccasionFollowUpRecord>[];
    final upcomingItems = <OccasionFollowUpRecord>[];
    final completedItems = <OccasionFollowUpRecord>[];
    final festivalItems = <OccasionFollowUpRecord>[];

    for (final item in resolved) {
      final itemDate = DateTime(item.date.year, item.date.month, item.date.day);

      if (item.isCompleted) {
        completedItems.add(item);
        continue;
      }

      if (item.sourceType == 'festival') {
        festivalItems.add(item);
      }

      if (itemDate.isAtSameMomentAs(todayDate)) {
        todayItems.add(item);
      } else if (itemDate.isAfter(todayDate)) {
        upcomingItems.add(item);
      }
    }

    return OccasionScreenData(
      today: todayItems,
      upcoming: upcomingItems,
      completed: completedItems,
      festival: festivalItems,
    );
  }

  Future<OccasionDashboardSummary> getDashboardSummary(DateTime today) async {
    final data = await buildScreenData(today: today);
    final birthdayCount = data.today
        .where((item) => item.category.toLowerCase() == 'birthday')
        .length;
    final pendingPayments =
        data.today.where((item) => item.sourceType == 'payment').length;
    final festivalCount =
        data.today.where((item) => item.sourceType == 'festival').length;

    return OccasionDashboardSummary(
      todayFollowUps: data.today.length,
      birthdayCount: birthdayCount,
      festivalCount: festivalCount,
      pendingPayments: pendingPayments,
    );
  }

  Future<void> markDone({
    required String sourceType,
    required int sourceId,
    required DateTime occurrenceDate,
  }) async {
    await _upsertAction(
      sourceType: sourceType,
      sourceId: sourceId,
      occurrenceDate: occurrenceDate,
      status: 'done',
      snoozedTo: null,
    );
  }

  Future<void> snoozeTomorrow({
    required String sourceType,
    required int sourceId,
    required DateTime occurrenceDate,
  }) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await _upsertAction(
      sourceType: sourceType,
      sourceId: sourceId,
      occurrenceDate: occurrenceDate,
      status: 'snoozed',
      snoozedTo: DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      ),
    );
  }

  Future<void> deleteManualReminder({
    required int contactId,
    required DateTime occurrenceDate,
  }) async {
    await _upsertAction(
      sourceType: 'occasion',
      sourceId: contactId,
      occurrenceDate: occurrenceDate,
      status: 'deleted',
      snoozedTo: null,
    );
  }

  Future<void> _upsertAction({
    required String sourceType,
    required int sourceId,
    required DateTime occurrenceDate,
    required String status,
    required DateTime? snoozedTo,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final dateKey = _dateKey(occurrenceDate);

    final existing = await db.query(
      'occasion_followup_actions',
      where: 'source_type = ? AND source_id = ? AND occurrence_date = ?',
      whereArgs: [sourceType, sourceId, dateKey],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert('occasion_followup_actions', {
        'source_type': sourceType,
        'source_id': sourceId,
        'occurrence_date': dateKey,
        'status': status,
        'snoozed_to': snoozedTo == null ? null : _dateKey(snoozedTo),
        'created_at': now,
        'updated_at': now,
      });
      return;
    }

    await db.update(
      'occasion_followup_actions',
      {
        'status': status,
        'snoozed_to': snoozedTo == null ? null : _dateKey(snoozedTo),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [existing.first['id'] as int],
    );
  }

  Future<Map<String, Object?>?> _getAction(
    String sourceType,
    int sourceId,
    DateTime occurrenceDate,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'occasion_followup_actions',
      where: 'source_type = ? AND source_id = ? AND occurrence_date = ?',
      whereArgs: [sourceType, sourceId, _dateKey(occurrenceDate)],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first;
  }

  Future<OccasionFollowUpRecord?> _applyFollowUpAction(
    OccasionFollowUpRecord input,
  ) async {
    final action =
        await _getAction(input.sourceType, input.sourceId, input.date);
    if (action == null) {
      return input;
    }

    final status = (action['status'] as String?) ?? '';
    if (status == 'deleted') {
      return null;
    }

    final snoozedTo = action['snoozed_to'] as String?;
    DateTime date = input.date;
    if (status == 'snoozed' && snoozedTo != null) {
      date = DateTime.tryParse(snoozedTo) ?? date;
    }

    return OccasionFollowUpRecord(
      sourceType: input.sourceType,
      sourceId: input.sourceId,
      date: date,
      title: input.title,
      subtitle: input.subtitle,
      category: input.category,
      customerPhone: input.customerPhone,
      recipientPhone: input.recipientPhone,
      customerId: input.customerId,
      orderId: input.orderId,
      isCompleted: status == 'done',
      isManual: input.isManual,
    );
  }

  OccasionFollowUpRecord _contactToFollowUp(OccasionContactRecord contact) {
    final customerName =
        contact.customerName.isNotEmpty ? contact.customerName : 'No Customer';
    return OccasionFollowUpRecord(
      sourceType: 'occasion',
      sourceId: contact.id,
      date: contact.occasionDate,
      title: contact.recipientName,
      subtitle: '${contact.occasion} • ${contact.relationship} • $customerName',
      category: contact.occasion,
      customerPhone: contact.customerPhone,
      recipientPhone: contact.recipientPhone,
      customerId: contact.customerId,
      orderId: null,
      isCompleted: false,
      isManual: true,
    );
  }

  Future<List<OccasionFollowUpRecord>> _pendingPaymentFollowUps({
    required DateTime today,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT id, customer_id, customer_name, customer_phone, grand_total_paise, created_at
      FROM orders
      WHERE is_paid = 0
        AND status NOT IN ('cancelled', 'draft')
      ORDER BY created_at ASC
      LIMIT 100
    ''');

    return rows.map((row) {
      final date =
          DateTime.tryParse((row['created_at'] as String?) ?? '') ?? today;
      final amount = ((row['grand_total_paise'] as int?) ?? 0) / 100;
      return OccasionFollowUpRecord(
        sourceType: 'payment',
        sourceId: row['id'] as int,
        date: DateTime(date.year, date.month, date.day),
        title: (row['customer_name'] as String?) ?? 'Pending Payment',
        subtitle: 'Pending payment • ₹${amount.toStringAsFixed(0)}',
        category: 'Payment',
        customerPhone: (row['customer_phone'] as String?) ?? '',
        customerId: row['customer_id'] as int?,
        orderId: row['id'] as int,
        isCompleted: false,
        isManual: false,
      );
    }).toList();
  }

  Future<List<OccasionFollowUpRecord>> _pendingDeliveryFollowUps({
    required DateTime today,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT id, customer_id, customer_name, customer_phone, recipient_name, scheduled_at
      FROM orders
      WHERE status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery')
      ORDER BY COALESCE(scheduled_at, created_at) ASC
      LIMIT 100
    ''');

    return rows.map((row) {
      final raw = row['scheduled_at'] as String?;
      final date = DateTime.tryParse(raw ?? '') ?? today;
      final name = (row['recipient_name'] as String?)?.trim().isNotEmpty == true
          ? (row['recipient_name'] as String)
          : ((row['customer_name'] as String?) ?? 'Pending Delivery');
      return OccasionFollowUpRecord(
        sourceType: 'delivery',
        sourceId: row['id'] as int,
        date: DateTime(date.year, date.month, date.day),
        title: name,
        subtitle: 'Pending delivery',
        category: 'Delivery',
        customerPhone: (row['customer_phone'] as String?) ?? '',
        customerId: row['customer_id'] as int?,
        orderId: row['id'] as int,
        isCompleted: false,
        isManual: false,
      );
    }).toList();
  }

  Future<List<OccasionFollowUpRecord>> _festivalFollowUps({
    required DateTime today,
  }) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'festival_master',
      where: 'deleted_at IS NULL',
      orderBy: 'month ASC, day ASC',
    );

    final result = <OccasionFollowUpRecord>[];

    for (final row in rows) {
      final month = (row['month'] as int?) ?? today.month;
      final day = (row['day'] as int?) ?? today.day;

      // Validate month and day before creating DateTime
      if (!_isValidMonthDay(month, day)) {
        continue;
      }

      try {
        var date = DateTime(today.year, month, day);
        if (date.isBefore(DateTime(today.year, today.month, today.day))) {
          date = DateTime(today.year + 1, month, day);
        }

        result.add(OccasionFollowUpRecord(
          sourceType: 'festival',
          sourceId: row['id'] as int,
          date: date,
          title: (row['name'] as String?) ?? 'Festival',
          subtitle: 'Festival greeting reminder',
          category: 'Festival',
          customerPhone: '',
          customerId: null,
          orderId: null,
          isCompleted: false,
          isManual: false,
        ));
      } catch (_) {
        // Skip festivals with invalid date values
        continue;
      }
    }

    return result;
  }

  OccasionContactRecord _mapContact(Map<String, Object?> row) {
    return OccasionContactRecord(
      id: row['id'] as int,
      customerId: row['customer_id'] as int,
      customerName: (row['customer_name'] as String?) ?? '',
      customerPhone: (row['customer_phone'] as String?) ?? '',
      recipientName: (row['recipient_name'] as String?) ?? '',
      relationship: (row['relationship'] as String?) ?? 'Other',
      occasion: (row['occasion'] as String?) ?? 'General Reminder',
      occasionDate:
          DateTime.tryParse((row['occasion_date'] as String?) ?? '') ??
              DateTime.now(),
      recipientPhone: (row['recipient_phone'] as String?) ?? '',
      company: (row['company'] as String?) ?? '',
      notes: (row['notes'] as String?) ?? '',
      reminderEnabled: (row['reminder_enabled'] as int? ?? 1) == 1,
      source: (row['source'] as String?) ?? 'Manual',
      createdAt: (row['created_at'] as String?) ?? '',
      updatedAt: (row['updated_at'] as String?) ?? '',
    );
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  String _dateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.toIso8601String();
  }

  bool _isValidMonthDay(int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return false;
    }
    // Additional validation for months with fewer days
    if (month == 2 && day > 29) {
      return false;
    }
    if ([4, 6, 9, 11].contains(month) && day > 30) {
      return false;
    }
    return true;
  }
}
