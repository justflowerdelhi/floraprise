import '../database/app_database.dart';
import 'order_repository.dart';

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
  final String? cloudCustomerId;
  final String? cloudCompanyId;

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
    this.cloudCustomerId,
    this.cloudCompanyId,
  });
}

class CustomerRepository {
  static String todayMonthDay() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '$mm-$dd';
  }

  static String _tenantWhereClause(
    String? companyId, {
    bool includeUnassigned = false,
    String tablePrefix = 'c.',
  }) {
    if (companyId == null || companyId.trim().isEmpty) {
      return '';
    }
    final col = '${tablePrefix}cloud_company_id';
    return includeUnassigned
        ? 'AND ($col = ? OR $col IS NULL)'
        : 'AND $col = ?';
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
      cloudCustomerId: row['cloud_customer_id'] as String?,
      cloudCompanyId: row['cloud_company_id'] as String?,
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
      c.cloud_customer_id,
      c.cloud_company_id,
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

  Future<CustomerRecord?> findByPhone(
    String phone, {
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(
      companyId,
      includeUnassigned: includeUnassigned,
    );
    final whereArgs = <Object>[phone];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.phone = ? AND c.deleted_at IS NULL
      $tenantClause
      GROUP BY c.id
      LIMIT 1
      ''',
      whereArgs,
    );

    if (rows.isEmpty) return null;
    return _mapCustomerRow(rows.first);
  }

  Future<CustomerRecord?> findByCloudId(
    String cloudCustomerId, {
    String? companyId,
  }) async {
    final trimmedId = cloudCustomerId.trim();
    if (trimmedId.isEmpty) return null;

    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(companyId);
    final whereArgs = <Object>[trimmedId];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.cloud_customer_id = ? AND c.deleted_at IS NULL
      $tenantClause
      GROUP BY c.id
      LIMIT 1
      ''',
      whereArgs,
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
    String? cloudCustomerId,
    String? cloudCompanyId,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final normalizedCloudId =
        cloudCustomerId?.trim().isEmpty ?? true ? null : cloudCustomerId!.trim();
    final normalizedCompanyId =
        cloudCompanyId?.trim().isEmpty ?? true ? null : cloudCompanyId!.trim();

    final id = await db.insert('customers', {
      'phone': phone,
      'name': name,
      'birthday_md': birthdayMd.trim().isEmpty ? null : birthdayMd.trim(),
      'anniversary_md':
          anniversaryMd.trim().isEmpty ? null : anniversaryMd.trim(),
      'company': company.trim().isEmpty ? null : company.trim(),
      'department': department.trim().isEmpty ? null : department.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'cloud_customer_id': normalizedCloudId,
      'cloud_company_id': normalizedCompanyId,
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
      cloudCustomerId: normalizedCloudId,
      cloudCompanyId: normalizedCompanyId,
      createdAt: now,
    );
  }

  Future<CustomerRecord> upsertFromCloud({
    required String cloudCustomerId,
    required String cloudCompanyId,
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
    final normalizedCloudId = cloudCustomerId.trim();
    final normalizedCompanyId = cloudCompanyId.trim();
    final normalizedPhone = phone.trim();
    final trimmedName = name.trim();

    if (normalizedCloudId.isEmpty) {
      throw ArgumentError('cloudCustomerId cannot be empty');
    }
    if (normalizedCompanyId.isEmpty) {
      throw ArgumentError('cloudCompanyId cannot be empty');
    }

    final existingByCloud = await findByCloudId(normalizedCloudId);
    if (existingByCloud != null) {
      final targetPhone =
          normalizedPhone.isNotEmpty ? normalizedPhone : existingByCloud.phone;
      if (targetPhone != existingByCloud.phone) {
        final conflict = await findByPhone(targetPhone);
        if (conflict != null && conflict.id != existingByCloud.id) {
          throw ArgumentError(
            'Phone number $targetPhone already belongs to customer ${conflict.id}',
          );
        }
      }

      await db.update(
        'customers',
        {
          'phone': targetPhone,
          'name': trimmedName.isNotEmpty ? trimmedName : existingByCloud.name,
          'cloud_customer_id': normalizedCloudId,
          'cloud_company_id': normalizedCompanyId,
          if (birthdayMd.trim().isNotEmpty) 'birthday_md': birthdayMd.trim(),
          if (anniversaryMd.trim().isNotEmpty)
            'anniversary_md': anniversaryMd.trim(),
          if (company.trim().isNotEmpty) 'company': company.trim(),
          if (department.trim().isNotEmpty) 'department': department.trim(),
          if (notes.trim().isNotEmpty) 'notes': notes.trim(),
          'deleted_at': null,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [existingByCloud.id],
      );

      final updated = await getById(existingByCloud.id);
      return updated!;
    }

    if (normalizedPhone.isNotEmpty) {
      // Only match a local customer that is unassigned or already belongs to
      // this same Cloud tenant; never re-link across companies by phone.
      final existingByPhone = await findByPhone(
        normalizedPhone,
        companyId: normalizedCompanyId,
        includeUnassigned: true,
      );
      if (existingByPhone != null) {
        await db.update(
          'customers',
          {
            'name': trimmedName.isNotEmpty ? trimmedName : existingByPhone.name,
            'cloud_customer_id': normalizedCloudId,
            'cloud_company_id': normalizedCompanyId,
            if (birthdayMd.trim().isNotEmpty) 'birthday_md': birthdayMd.trim(),
            if (anniversaryMd.trim().isNotEmpty)
              'anniversary_md': anniversaryMd.trim(),
            if (company.trim().isNotEmpty) 'company': company.trim(),
            if (department.trim().isNotEmpty) 'department': department.trim(),
            if (notes.trim().isNotEmpty) 'notes': notes.trim(),
            'deleted_at': null,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [existingByPhone.id],
        );

        final updated = await getById(existingByPhone.id);
        return updated!;
      }

      // Phone numbers are globally unique in this table; refuse to silently
      // reassign a phone that already belongs to a different company's customer.
      final crossTenantOwner = await findByPhone(normalizedPhone);
      if (crossTenantOwner != null) {
        throw ArgumentError(
          'Phone number $normalizedPhone already belongs to customer ${crossTenantOwner.id} in another company',
        );
      }
    }

    final id = await db.insert('customers', {
      'phone': normalizedPhone,
      'name': trimmedName,
      'cloud_customer_id': normalizedCloudId,
      'cloud_company_id': normalizedCompanyId,
      'birthday_md': birthdayMd.trim().isEmpty ? null : birthdayMd.trim(),
      'anniversary_md':
          anniversaryMd.trim().isEmpty ? null : anniversaryMd.trim(),
      'company': company.trim().isEmpty ? null : company.trim(),
      'department': department.trim().isEmpty ? null : department.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'created_at': now,
      'updated_at': now,
    });

    final created = await getById(id);
    return created!;
  }

  Future<void> setCloudCustomerId(
    int localCustomerId,
    String cloudCustomerId,
    String cloudCompanyId,
  ) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      'customers',
      {
        'cloud_customer_id': cloudCustomerId.trim(),
        'cloud_company_id': cloudCompanyId.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [localCustomerId],
    );
    if (count == 0) {
      throw StateError('Local customer was not found.');
    }
  }

  Future<List<CustomerRecord>> getAll({
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(
      companyId,
      includeUnassigned: includeUnassigned,
    );
    final whereArgs = <Object>[];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery('''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      $tenantClause
      GROUP BY c.id
      ORDER BY c.created_at DESC
    ''', whereArgs);

    return rows.map(_mapCustomerRow).toList();
  }

  Future<List<CustomerRecord>> search(
    String query, {
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(
      companyId,
      includeUnassigned: includeUnassigned,
    );
    final whereArgs = <Object>['%$query%', '%$query%'];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
        AND (c.name LIKE ? OR c.phone LIKE ?)
        $tenantClause
      GROUP BY c.id
      ORDER BY c.created_at DESC
      ''',
      whereArgs,
    );

    return rows.map(_mapCustomerRow).toList();
  }

  Future<int> getTodayBirthdayCount({
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final whereArgs = <Object>[todayMonthDay()];
    var tenantClause = '';
    if (companyId != null && companyId.trim().isNotEmpty) {
      tenantClause = includeUnassigned
          ? 'AND (cloud_company_id = ? OR cloud_company_id IS NULL)'
          : 'AND cloud_company_id = ?';
      whereArgs.add(companyId.trim());
    }

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM customers
      WHERE deleted_at IS NULL
      AND birthday_md = ?
      $tenantClause
      ''',
      whereArgs,
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
    String? cloudCustomerId,
    String? cloudCompanyId,
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

    final updateValues = <String, Object?>{
      'phone': phone,
      'name': name,
      'birthday_md': birthdayMd.trim().isEmpty ? null : birthdayMd.trim(),
      'anniversary_md':
          anniversaryMd.trim().isEmpty ? null : anniversaryMd.trim(),
      'company': company.trim().isEmpty ? null : company.trim(),
      'department': department.trim().isEmpty ? null : department.trim(),
      'notes': notes.trim().isEmpty ? null : notes.trim(),
      'updated_at': now,
    };

    if (cloudCustomerId != null) {
      updateValues['cloud_customer_id'] =
          cloudCustomerId.trim().isEmpty ? null : cloudCustomerId.trim();
    }
    if (cloudCompanyId != null) {
      updateValues['cloud_company_id'] =
          cloudCompanyId.trim().isEmpty ? null : cloudCompanyId.trim();
    }

    await db.update(
      'customers',
      updateValues,
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await getById(id);
    if (updated == null) {
      throw StateError('Customer not found after update');
    }
    return updated;
  }

  Future<Map<String, dynamic>?> getStatisticsByCustomer(
    CustomerRecord customer,
  ) {
    return OrderRepository().getCustomerStatistics(
      customer.id,
      customerPhone: customer.phone,
    );
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

  Future<List<CustomerRecord>> listTodaysBirthdays({
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(
      companyId,
      includeUnassigned: includeUnassigned,
    );
    final whereArgs = <Object>[todayMonthDay()];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      AND c.birthday_md = ?
      $tenantClause
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
      ''',
      whereArgs,
    );

    return rows.map(_mapCustomerRow).toList();
  }

  Future<List<CustomerRecord>> listTodaysAnniversaries({
    String? companyId,
    bool includeUnassigned = false,
  }) async {
    final db = await AppDatabase.instance.database;
    final tenantClause = _tenantWhereClause(
      companyId,
      includeUnassigned: includeUnassigned,
    );
    final whereArgs = <Object>[todayMonthDay()];
    if (companyId != null && companyId.trim().isNotEmpty) {
      whereArgs.add(companyId.trim());
    }

    final rows = await db.rawQuery(
      '''
      $_baseSelect
      WHERE c.deleted_at IS NULL
      AND c.anniversary_md = ?
      $tenantClause
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
      ''',
      whereArgs,
    );

    return rows.map(_mapCustomerRow).toList();
  }
}
