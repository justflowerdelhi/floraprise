import '../database/app_database.dart';

enum AssociateType {
  florist,
  supplier,
  corporate,
  ecommerce,
  weddingPlanner,
  hotel,
  eventCompany,
  marketplace,
  other,
}

extension AssociateTypeExtension on AssociateType {
  String get displayName {
    switch (this) {
      case AssociateType.florist:
        return 'Florist';
      case AssociateType.supplier:
        return 'Supplier';
      case AssociateType.corporate:
        return 'Corporate';
      case AssociateType.ecommerce:
        return 'E-commerce';
      case AssociateType.weddingPlanner:
        return 'Wedding Planner';
      case AssociateType.hotel:
        return 'Hotel';
      case AssociateType.eventCompany:
        return 'Event Company';
      case AssociateType.marketplace:
        return 'Marketplace';
      case AssociateType.other:
        return 'Other';
    }
  }

  String get storageValue {
    switch (this) {
      case AssociateType.florist:
        return 'Florist';
      case AssociateType.supplier:
        return 'Supplier';
      case AssociateType.corporate:
        return 'Corporate';
      case AssociateType.ecommerce:
        return 'E-commerce';
      case AssociateType.weddingPlanner:
        return 'Wedding Planner';
      case AssociateType.hotel:
        return 'Hotel';
      case AssociateType.eventCompany:
        return 'Event Company';
      case AssociateType.marketplace:
        return 'Marketplace';
      case AssociateType.other:
        return 'Other';
    }
  }

  static AssociateType fromStorageValue(String value) {
    switch (value) {
      case 'Florist':
        return AssociateType.florist;
      case 'Supplier':
        return AssociateType.supplier;
      case 'Corporate':
        return AssociateType.corporate;
      case 'E-commerce':
        return AssociateType.ecommerce;
      case 'Wedding Planner':
        return AssociateType.weddingPlanner;
      case 'Hotel':
        return AssociateType.hotel;
      case 'Event Company':
        return AssociateType.eventCompany;
      case 'Marketplace':
        return AssociateType.marketplace;
      default:
        return AssociateType.other;
    }
  }

  static List<AssociateType> get allTypes => AssociateType.values;
}

class AssociateRecord {
  final int id;
  final String associateCode;
  final String businessName;
  final String? contactPerson;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String city;
  final String? state;
  final String pincode;
  final String? address;
  final String? gstNumber;
  final String? website;
  final String? notes;
  final List<AssociateType> types;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  const AssociateRecord({
    required this.id,
    required this.associateCode,
    required this.businessName,
    this.contactPerson,
    required this.phone,
    this.whatsapp,
    this.email,
    required this.city,
    this.state,
    required this.pincode,
    this.address,
    this.gstNumber,
    this.website,
    this.notes,
    this.types = const [AssociateType.other],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get typesDisplay {
    return types.map((t) => t.displayName).join(', ');
  }

  String get typesStorage {
    return types.map((t) => t.storageValue).join(',');
  }

  static List<AssociateType> parseTypes(String storageValue) {
    if (storageValue.isEmpty) return [AssociateType.other];
    final parts = storageValue.split(',');
    return parts
        .map((p) => AssociateTypeExtension.fromStorageValue(p.trim()))
        .where((t) => t != AssociateType.other || parts.length == 1)
        .toList();
  }
}

class AssociateUpsertInput {
  final String businessName;
  final String? contactPerson;
  final String phone;
  final String? whatsapp;
  final String? email;
  final String city;
  final String? state;
  final String pincode;
  final String? address;
  final String? gstNumber;
  final String? website;
  final String? notes;
  final List<AssociateType> types;
  final bool isActive;

  const AssociateUpsertInput({
    required this.businessName,
    this.contactPerson,
    required this.phone,
    this.whatsapp,
    this.email,
    required this.city,
    this.state,
    required this.pincode,
    this.address,
    this.gstNumber,
    this.website,
    this.notes,
    this.types = const [AssociateType.other],
    this.isActive = true,
  });
}

class AssociateRepository {
  AssociateRecord _mapAssociateRow(Map<String, Object?> row) {
    return AssociateRecord(
      id: row['id'] as int,
      associateCode: row['associate_code'] as String,
      businessName: row['business_name'] as String,
      contactPerson: row['contact_person'] as String?,
      phone: row['phone'] as String,
      whatsapp: row['whatsapp'] as String?,
      email: row['email'] as String?,
      city: row['city'] as String,
      state: row['state'] as String?,
      pincode: row['pincode'] as String,
      address: row['address'] as String?,
      gstNumber: row['gst_number'] as String?,
      website: row['website'] as String?,
      notes: row['notes'] as String?,
      types: AssociateRecord.parseTypes(row['types'] as String? ?? 'Other'),
      isActive: (row['is_active'] as int) == 1,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
      deletedAt: row['deleted_at'] as String?,
    );
  }

  Future<String> _generateNextCode() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT MAX(CAST(SUBSTR(associate_code, 4) AS INTEGER)) as max_num
      FROM associates
    ''');
    
    final maxNum = result.first['max_num'] as int? ?? 0;
    final nextNum = maxNum + 1;
    return 'ASC${nextNum.toString().padLeft(6, '0')}';
  }

  Future<List<AssociateRecord>> searchAssociates({
    String? query,
    List<AssociateType>? types,
    bool activeOnly = true,
  }) async {
    final db = await AppDatabase.instance.database;
    
    final whereClauses = <String>[];
    final whereArgs = <Object?>[];

    if (activeOnly) {
      whereClauses.add('a.deleted_at IS NULL');
      whereClauses.add('a.is_active = 1');
    } else {
      whereClauses.add('a.deleted_at IS NULL');
    }

    if (query != null && query.trim().isNotEmpty) {
      final searchPattern = '%${query.trim()}%';
      whereClauses.add('''
        (a.business_name LIKE ? OR
         a.contact_person LIKE ? OR
         a.phone LIKE ? OR
         a.city LIKE ?)
      ''');
      whereArgs.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    if (types != null && types.isNotEmpty) {
      final typeConditions = types.map((t) => "a.types LIKE '%${t.storageValue}%'").join(' OR ');
      whereClauses.add('($typeConditions)');
    }

    final whereClause = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';

    final rows = await db.rawQuery('''
      SELECT
        a.id,
        a.associate_code,
        a.business_name,
        a.contact_person,
        a.phone,
        a.whatsapp,
        a.email,
        a.city,
        a.state,
        a.pincode,
        a.address,
        a.gst_number,
        a.website,
        a.notes,
        a.types,
        a.is_active,
        a.created_at,
        a.updated_at,
        a.deleted_at
      FROM associates a
      $whereClause
      ORDER BY a.business_name ASC
    ''', whereArgs);

    return rows.map(_mapAssociateRow).toList();
  }

  Future<List<AssociateRecord>> getAll({
    bool includeDeleted = false,
    bool activeOnly = false,
  }) async {
    final db = await AppDatabase.instance.database;
    
    final whereClauses = <String>[];
    if (!includeDeleted) {
      whereClauses.add('deleted_at IS NULL');
    }
    if (activeOnly) {
      whereClauses.add('is_active = 1');
    }

    final whereClause = whereClauses.isNotEmpty 
        ? 'WHERE ${whereClauses.join(' AND ')}' 
        : '';

    final rows = await db.rawQuery('''
      SELECT
        id,
        associate_code,
        business_name,
        contact_person,
        phone,
        whatsapp,
        email,
        city,
        state,
        pincode,
        address,
        gst_number,
        website,
        notes,
        types,
        is_active,
        created_at,
        updated_at,
        deleted_at
      FROM associates
      $whereClause
      ORDER BY business_name ASC
    ''');

    return rows.map(_mapAssociateRow).toList();
  }

  Future<AssociateRecord?> findById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        id,
        associate_code,
        business_name,
        contact_person,
        phone,
        whatsapp,
        email,
        city,
        state,
        pincode,
        address,
        gst_number,
        website,
        notes,
        types,
        is_active,
        created_at,
        updated_at,
        deleted_at
      FROM associates
      WHERE id = ?
      LIMIT 1
    ''', [id]);

    if (rows.isEmpty) return null;
    return _mapAssociateRow(rows.first);
  }

  Future<AssociateRecord?> findByBusinessNameAndPhone(
    String businessName,
    String phone,
  ) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.rawQuery('''
      SELECT
        id,
        associate_code,
        business_name,
        contact_person,
        phone,
        whatsapp,
        email,
        city,
        state,
        pincode,
        address,
        gst_number,
        website,
        notes,
        types,
        is_active,
        created_at,
        updated_at,
        deleted_at
      FROM associates
      WHERE business_name = ? AND phone = ? AND deleted_at IS NULL
      LIMIT 1
    ''', [businessName, phone]);

    if (rows.isEmpty) return null;
    return _mapAssociateRow(rows.first);
  }

  Future<AssociateRecord> create(AssociateUpsertInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final code = await _generateNextCode();

    // Check for duplicate
    final existing = await findByBusinessNameAndPhone(input.businessName, input.phone);
    if (existing != null) {
      throw Exception('An associate with this business name and phone already exists.');
    }

    final id = await db.insert('associates', {
      'associate_code': code,
      'business_name': input.businessName.trim(),
      'contact_person': input.contactPerson?.trim(),
      'phone': input.phone.trim(),
      'whatsapp': input.whatsapp?.trim(),
      'email': input.email?.trim(),
      'city': input.city.trim(),
      'state': input.state?.trim(),
      'pincode': input.pincode.trim(),
      'address': input.address?.trim(),
      'gst_number': input.gstNumber?.trim(),
      'website': input.website?.trim(),
      'notes': input.notes?.trim(),
      'types': input.types.map((t) => t.storageValue).join(','),
      'is_active': input.isActive ? 1 : 0,
      'created_at': now,
      'updated_at': now,
    });

    final created = await findById(id);
    if (created == null) {
      throw Exception('Failed to create associate');
    }
    return created;
  }

  Future<AssociateRecord> update(int id, AssociateUpsertInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Check for duplicate (excluding current record)
    final existing = await db.rawQuery('''
      SELECT id FROM associates
      WHERE business_name = ? AND phone = ? AND id != ? AND deleted_at IS NULL
      LIMIT 1
    ''', [input.businessName.trim(), input.phone.trim(), id]);

    if (existing.isNotEmpty) {
      throw Exception('An associate with this business name and phone already exists.');
    }

    await db.update(
      'associates',
      {
        'business_name': input.businessName.trim(),
        'contact_person': input.contactPerson?.trim(),
        'phone': input.phone.trim(),
        'whatsapp': input.whatsapp?.trim(),
        'email': input.email?.trim(),
        'city': input.city.trim(),
        'state': input.state?.trim(),
        'pincode': input.pincode.trim(),
        'address': input.address?.trim(),
        'gst_number': input.gstNumber?.trim(),
        'website': input.website?.trim(),
        'notes': input.notes?.trim(),
        'types': input.types.map((t) => t.storageValue).join(','),
        'is_active': input.isActive ? 1 : 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('Failed to update associate');
    }
    return updated;
  }

  Future<void> deactivate(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'associates',
      {
        'is_active': 0,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> reactivate(int id) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'associates',
      {
        'is_active': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> canDelete(int id) async {
    // For now, always return true since no other modules reference associates yet
    // This method is prepared for future integration
    return true;
  }

  Future<void> delete(int id) async {
    final canDeleteAssociate = await canDelete(id);
    if (!canDeleteAssociate) {
      throw Exception('This Associate is being used and cannot be deleted.');
    }

    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.update(
      'associates',
      {
        'deleted_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getActiveCount() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM associates
      WHERE deleted_at IS NULL AND is_active = 1
    ''');

    return result.first['count'] as int? ?? 0;
  }
}
