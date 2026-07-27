import '../database/app_database.dart';

enum StaffRole {
  designer,
  chef,
  delivery,
  sales,
  cashier,
  manager,
  owner,
  helper,
  other,
}

enum StaffSalaryType {
  monthly,
  daily,
  perDelivery,
  perOrder,
  commission,
}

extension StaffSalaryTypeExtension on StaffSalaryType {
  String get displayName => switch (this) {
        StaffSalaryType.monthly => 'Monthly',
        StaffSalaryType.daily => 'Daily',
        StaffSalaryType.perDelivery => 'Per Delivery',
        StaffSalaryType.perOrder => 'Per Order',
        StaffSalaryType.commission => 'Commission',
      };

  static StaffSalaryType? fromStorage(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final type in StaffSalaryType.values) {
      if (type.displayName.toLowerCase() == value.toLowerCase()) return type;
    }
    return null;
  }
}

extension StaffRoleExtension on StaffRole {
  String get displayName => switch (this) {
        StaffRole.designer => 'Designer',
        StaffRole.chef => 'Chef',
        StaffRole.delivery => 'Delivery',
        StaffRole.sales => 'Sales',
        StaffRole.cashier => 'Cashier',
        StaffRole.manager => 'Manager',
        StaffRole.owner => 'Owner',
        StaffRole.helper => 'Helper',
        StaffRole.other => 'Other',
      };

  static StaffRole fromStorage(String value) {
    return StaffRole.values.firstWhere(
      (role) => role.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => StaffRole.other,
    );
  }
}

class Staff {
  final int id;
  final String staffCode;
  final String name;
  final String phone;
  final String? whatsapp;
  final bool sameAsPhone;
  final String? email;
  final StaffRole role;
  final String? city;
  final String? address;
  final DateTime? joiningDate;
  final StaffSalaryType? salaryType;
  final double? salaryAmount;
  final bool canDesign;
  final bool canDeliver;
  final bool canManageOrders;
  final bool active;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Staff({
    required this.id,
    required this.staffCode,
    required this.name,
    required this.phone,
    this.whatsapp,
    required this.sameAsPhone,
    this.email,
    required this.role,
    this.city,
    this.address,
    this.joiningDate,
    this.salaryType,
    this.salaryAmount,
    this.canDesign = false,
    this.canDeliver = false,
    this.canManageOrders = false,
    required this.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

class StaffUpsertInput {
  final String name;
  final String phone;
  final String? whatsapp;
  final bool sameAsPhone;
  final String? email;
  final StaffRole role;
  final String? city;
  final String? address;
  final DateTime? joiningDate;
  final StaffSalaryType? salaryType;
  final double? salaryAmount;
  final bool canDesign;
  final bool canDeliver;
  final bool canManageOrders;
  final bool active;
  final String? notes;

  const StaffUpsertInput({
    required this.name,
    required this.phone,
    this.whatsapp,
    this.sameAsPhone = true,
    this.email,
    required this.role,
    this.city,
    this.address,
    this.joiningDate,
    this.salaryType,
    this.salaryAmount,
    this.canDesign = false,
    this.canDeliver = false,
    this.canManageOrders = false,
    this.active = true,
    this.notes,
  });
}

class StaffRepository {
  Staff _fromRow(Map<String, Object?> row) {
    return Staff(
      id: row['id'] as int,
      staffCode: row['staff_code'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      whatsapp: row['whatsapp'] as String?,
      sameAsPhone: (row['same_as_phone'] as int? ?? 1) == 1,
      email: row['email'] as String?,
      role: StaffRoleExtension.fromStorage(row['role'] as String),
      city: row['city'] as String?,
      address: row['address'] as String?,
      joiningDate: DateTime.tryParse((row['joining_date'] as String?) ?? ''),
      salaryType:
          StaffSalaryTypeExtension.fromStorage(row['salary_type'] as String?),
      salaryAmount: (row['salary_amount'] as num?)?.toDouble(),
      canDesign: (row['can_design'] as int? ?? 0) == 1,
      canDeliver: (row['can_deliver'] as int? ?? 0) == 1,
      canManageOrders: (row['can_manage_orders'] as int? ?? 0) == 1,
      active: (row['active'] as int? ?? 1) == 1,
      notes: row['notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Future<String> _nextCode() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT MAX(CAST(SUBSTR(staff_code, 4) AS INTEGER)) AS max_number
      FROM staff
    ''');
    final next = (result.first['max_number'] as int? ?? 0) + 1;
    return 'STF${next.toString().padLeft(6, '0')}';
  }

  Future<List<Staff>> searchStaff({
    String? query,
    List<StaffRole>? roles,
    bool activeOnly = true,
  }) async {
    final db = await AppDatabase.instance.database;
    final where = <String>[];
    final args = <Object?>[];

    if (activeOnly) {
      where.add('active = 1');
    }
    if (query != null && query.trim().isNotEmpty) {
      final pattern = '%${query.trim()}%';
      where.add('(name LIKE ? OR phone LIKE ? OR role LIKE ?)');
      args.addAll([pattern, pattern, pattern]);
    }
    if (roles != null && roles.isNotEmpty) {
      where.add('role IN (${List.filled(roles.length, '?').join(', ')})');
      args.addAll(roles.map((role) => role.displayName));
    }

    final rows = await db.query(
      'staff',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<Staff>> getAll() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'staff',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<Staff?> findById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'staff',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<Staff> create(StaffUpsertInput input) async {
    _validate(input);
    final db = await AppDatabase.instance.database;
    await _ensureUniquePhone(input.phone);
    final now = DateTime.now().toIso8601String();
    final code = await _nextCode();
    final phone = input.phone.trim();
    final id = await db.insert('staff', {
      'staff_code': code,
      'name': input.name.trim(),
      'phone': phone,
      'whatsapp': input.sameAsPhone ? phone : _nullable(input.whatsapp),
      'same_as_phone': input.sameAsPhone ? 1 : 0,
      'email': _nullable(input.email),
      'role': input.role.displayName,
      'city': _nullable(input.city),
      'address': _nullable(input.address),
      'joining_date': input.joiningDate?.toIso8601String(),
      'salary_type': input.salaryType?.displayName,
      'salary_amount': input.salaryAmount,
      'can_design': input.canDesign ? 1 : 0,
      'can_deliver': input.canDeliver ? 1 : 0,
      'can_manage_orders': input.canManageOrders ? 1 : 0,
      'active': input.active ? 1 : 0,
      'notes': _nullable(input.notes),
      'created_at': now,
      'updated_at': now,
    });
    final created = await findById(id);
    if (created == null) throw StateError('Could not create staff member.');
    return created;
  }

  Future<Staff> update(int id, StaffUpsertInput input) async {
    _validate(input);
    final db = await AppDatabase.instance.database;
    await _ensureUniquePhone(input.phone, excludingId: id);
    final phone = input.phone.trim();
    await db.update(
      'staff',
      {
        'name': input.name.trim(),
        'phone': phone,
        'whatsapp': input.sameAsPhone ? phone : _nullable(input.whatsapp),
        'same_as_phone': input.sameAsPhone ? 1 : 0,
        'email': _nullable(input.email),
        'role': input.role.displayName,
        'city': _nullable(input.city),
        'address': _nullable(input.address),
        'joining_date': input.joiningDate?.toIso8601String(),
        'salary_type': input.salaryType?.displayName,
        'salary_amount': input.salaryAmount,
        'can_design': input.canDesign ? 1 : 0,
        'can_deliver': input.canDeliver ? 1 : 0,
        'can_manage_orders': input.canManageOrders ? 1 : 0,
        'active': input.active ? 1 : 0,
        'notes': _nullable(input.notes),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await findById(id);
    if (updated == null) throw StateError('Could not update staff member.');
    return updated;
  }

  Future<void> setActive(int id, bool active) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'staff',
      {
        'active': active ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> canDelete(int id) async {
    final db = await AppDatabase.instance.database;
    final columns = await db.rawQuery('PRAGMA table_info(orders)');
    final available = columns.map((row) => row['name'] as String).toSet();
    const possibleColumns = {
      'staff_id',
      'assigned_staff_id',
      'designer_staff_id',
      'delivery_staff_id',
    };
    for (final column in possibleColumns.where(available.contains)) {
      final count = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM orders WHERE $column = ?',
        [id],
      );
      if ((count.first['count'] as int? ?? 0) > 0) return false;
    }
    return true;
  }

  Future<void> delete(int id) async {
    if (!await canDelete(id)) {
      throw StateError(
          'This staff member is referenced by an order and cannot be deleted.');
    }
    final db = await AppDatabase.instance.database;
    await db.delete('staff', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getActiveCount() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM staff WHERE active = 1',
    );
    return rows.first['count'] as int? ?? 0;
  }

  Future<void> _ensureUniquePhone(String phone, {int? excludingId}) async {
    final db = await AppDatabase.instance.database;
    final normalized = _normalizePhone(phone);
    final rows = await db.query('staff', columns: ['id', 'phone']);
    final duplicate = rows.any((row) {
      if (excludingId != null && row['id'] == excludingId) return false;
      return _normalizePhone(row['phone'] as String) == normalized;
    });
    if (duplicate) {
      throw StateError('A staff member with this phone number already exists.');
    }
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? value.trim().toLowerCase() : digits;
  }

  void _validate(StaffUpsertInput input) {
    if (input.name.trim().isEmpty) throw ArgumentError('Name is required.');
    if (input.phone.trim().isEmpty) throw ArgumentError('Phone is required.');
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
