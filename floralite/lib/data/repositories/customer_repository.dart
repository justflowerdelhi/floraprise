import '../database/app_database.dart';

class CustomerRecord {
  final int id;
  final String phone;
  final String name;
  final String birthdayMd;
  final String anniversaryMd;
  final String company;
  final String department;
  final String notes;
  final String createdAt;
  final int totalOrders;
  final String? lastOrderAt;
  final int pendingPaymentPaise;
  final int rewardPoints;
  final int lifetimeRewardPoints;
  final int redeemedRewardPoints;
  final String? lastRewardActivity;

  const CustomerRecord({
    required this.id,
    required this.phone,
    required this.name,
    this.birthdayMd = '',
    this.anniversaryMd = '',
    this.company = '',
    this.department = '',
    this.notes = '',
    required this.createdAt,
    this.totalOrders = 0,
    this.lastOrderAt,
    this.pendingPaymentPaise = 0,
    this.rewardPoints = 0,
    this.lifetimeRewardPoints = 0,
    this.redeemedRewardPoints = 0,
    this.lastRewardActivity,
  });
}

class CustomerRepository {
  static String todayMonthDay() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  CustomerRecord _mapCustomerRow(Map<String, Object?> row) {
    return CustomerRecord(
      id: row['id'] as int,
      phone: (row['phone'] as String?) ?? '',
      name: row['name'] as String,
      birthdayMd: (row['birthday_md'] as String?) ?? '',
      anniversaryMd: (row['anniversary_md'] as String?) ?? '',
      company: (row['company'] as String?) ?? '',
      department: (row['department'] as String?) ?? '',
      notes: (row['notes'] as String?) ?? '',
      createdAt: row['created_at'] as String,
      totalOrders: (row['total_orders'] as int?) ?? 0,
      lastOrderAt: row['last_order_at'] as String?,
      pendingPaymentPaise: (row['pending_payment_paise'] as int?) ?? 0,
      rewardPoints: (row['reward_points'] as int?) ?? 0,
      lifetimeRewardPoints: (row['lifetime_reward_points'] as int?) ?? 0,
      redeemedRewardPoints: (row['redeemed_reward_points'] as int?) ?? 0,
      lastRewardActivity: row['last_reward_activity'] as String?,
    );
  }

  static const String _baseSelect = '''
    SELECT
      c.id,
      c.phone,
      c.name,
      c.birthday_md,
      c.anniversary_md,
      c.company,
      c.department,
      c.notes,
      c.created_at,
      c.reward_points,
      c.lifetime_reward_points,
      c.redeemed_reward_points,
      c.last_reward_activity,
      COALESCE(SUM(CASE
        WHEN o.status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered') THEN 1
        ELSE 0
      END), 0) AS total_orders,
      MAX(CASE
        WHEN o.status IN ('confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered') THEN o.created_at
        ELSE NULL
      END) AS last_order_at,
      COALESCE(SUM(CASE
        WHEN o.is_paid = 0 AND o.status NOT IN ('cancelled', 'draft')
          THEN o.grand_total_paise
        ELSE 0
      END), 0) AS pending_payment_paise
    FROM customers c
    LEFT JOIN orders o ON o.customer_id = c.id
  ''';

  Future<CustomerRecord?> findByPhone(String phone) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.phone = ? AND c.deleted_at IS NULL
      GROUP BY c.id
      LIMIT 1
      ''',
      [phone],
    );

    if (rows.isEmpty) return null;
    return _mapCustomerRow(rows.first);
  }

  Future<CustomerRecord> create({
    required String phone,
    required String name,
    String birthdayMd = '',
    String anniversaryMd = '',
    String company = '',
    String department = '',
    String notes = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('customers', {
      'phone': phone,
      'name': name,
      'birthday_md': birthdayMd.trim().isEmpty ? null : birthdayMd.trim(),
      'anniversary_md':
          anniversaryMd.trim().isEmpty ? null : anniversaryMd.trim(),
      'company': company.trim().isEmpty ? null : company.trim(),
      'department': department.trim().isEmpty ? null : department.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'created_at': now,
      'updated_at': now,
    });

    return CustomerRecord(
      id: id,
      phone: phone,
      name: name,
      birthdayMd: birthdayMd,
      anniversaryMd: anniversaryMd,
      company: company,
      department: department,
      notes: notes,
      createdAt: now,
    );
  }

  Future<List<CustomerRecord>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''');

    return rows.map(_mapCustomerRow).toList();
  }

  Future<List<CustomerRecord>> search(String query) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
        AND (c.name LIKE ? OR c.phone LIKE ?)
      GROUP BY c.id
      ORDER BY c.created_at DESC
      ''',
      ['%$query%', '%$query%'],
    );

    return rows.map(_mapCustomerRow).toList();
  }

  Future<int> getTodayBirthdayCount() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM customers
      WHERE deleted_at IS NULL
      AND birthday_md = ?
      ''',
      [todayMonthDay()],
    );

    return result.first['count'] as int;
  }

  Future<CustomerRecord?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.id = ? AND c.deleted_at IS NULL
      GROUP BY c.id
      LIMIT 1
      ''',
      [id],
    );

    if (rows.isEmpty) return null;
    return _mapCustomerRow(rows.first);
  }

  Future<CustomerRecord> update({
    required int id,
    required String phone,
    required String name,
    String birthdayMd = '',
    String anniversaryMd = '',
    String company = '',
    String department = '',
    String notes = '',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    final existingCustomer = await getById(id);
    if (existingCustomer != null && existingCustomer.phone != phone) {
      final phoneConflict = await findByPhone(phone);
      if (phoneConflict != null && phoneConflict.id != id) {
        throw ArgumentError('Phone number already exists for another customer');
      }
    }

    await db.update(
      'customers',
      {
        'phone': phone,
        'name': name,
        'birthday_md': birthdayMd.trim().isEmpty ? null : birthdayMd.trim(),
        'anniversary_md':
            anniversaryMd.trim().isEmpty ? null : anniversaryMd.trim(),
        'company': company.trim().isEmpty ? null : company.trim(),
        'department': department.trim().isEmpty ? null : department.trim(),
        'notes': notes.trim().isEmpty ? null : notes.trim(),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await getById(id);
    if (updated == null) {
      throw StateError('Customer not found after update');
    }
    return updated;
  }

  Future<void> softDelete(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'customers',
      {'deleted_at': now},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
  }

  Future<List<CustomerRecord>> listTodaysBirthdays() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      AND c.birthday_md = ?
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
      ''',
      [todayMonthDay()],
    );

    return rows.map(_mapCustomerRow).toList();
  }

  Future<List<CustomerRecord>> listTodaysAnniversaries() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      AND c.anniversary_md = ?
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
      ''',
      [todayMonthDay()],
    );

    return rows.map(_mapCustomerRow).toList();
  }
}
