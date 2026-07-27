import '../database/app_database.dart';

class ThirdPartyDelivery {
  final int id;
  final int orderId;
  final String deliveryPartner;
  final String? bookingReference;
  final String? driverName;
  final String? driverMobile;
  final int deliveryChargesPaise;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  const ThirdPartyDelivery({
    required this.id,
    required this.orderId,
    required this.deliveryPartner,
    this.bookingReference,
    this.driverName,
    this.driverMobile,
    required this.deliveryChargesPaise,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ThirdPartyDeliveryInput {
  final int orderId;
  final String deliveryPartner;
  final String? bookingReference;
  final String? driverName;
  final String? driverMobile;
  final int deliveryChargesPaise;
  final String? notes;

  const ThirdPartyDeliveryInput({
    required this.orderId,
    required this.deliveryPartner,
    this.bookingReference,
    this.driverName,
    this.driverMobile,
    this.deliveryChargesPaise = 0,
    this.notes,
  });
}

class ThirdPartyDeliveryRepository {
  ThirdPartyDelivery _fromRow(Map<String, Object?> row) {
    return ThirdPartyDelivery(
      id: row['id'] as int,
      orderId: row['order_id'] as int,
      deliveryPartner: row['delivery_partner'] as String,
      bookingReference: row['booking_reference'] as String?,
      driverName: row['driver_name'] as String?,
      driverMobile: row['driver_mobile'] as String?,
      deliveryChargesPaise: row['delivery_charges_paise'] as int,
      notes: row['notes'] as String?,
      createdAt: row['created_at'] as String,
      updatedAt: row['updated_at'] as String,
    );
  }

  Future<ThirdPartyDelivery?> getByOrderId(int orderId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'third_party_deliveries',
      where: 'order_id = ?',
      whereArgs: [orderId],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Future<ThirdPartyDelivery> create(ThirdPartyDeliveryInput input) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    final id = await db.insert('third_party_deliveries', {
      'order_id': input.orderId,
      'delivery_partner': input.deliveryPartner.trim(),
      'booking_reference': input.bookingReference?.trim(),
      'driver_name': input.driverName?.trim(),
      'driver_mobile': input.driverMobile?.trim(),
      'delivery_charges_paise': input.deliveryChargesPaise,
      'notes': input.notes?.trim(),
      'created_at': now,
      'updated_at': now,
    });
    final created = await _getById(id);
    if (created == null) throw StateError('Could not create third-party delivery.');
    return created;
  }

  Future<ThirdPartyDelivery> update(int id, ThirdPartyDeliveryInput input) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'third_party_deliveries',
      {
        'delivery_partner': input.deliveryPartner.trim(),
        'booking_reference': input.bookingReference?.trim(),
        'driver_name': input.driverName?.trim(),
        'driver_mobile': input.driverMobile?.trim(),
        'delivery_charges_paise': input.deliveryChargesPaise,
        'notes': input.notes?.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await _getById(id);
    if (updated == null) throw StateError('Could not update third-party delivery.');
    return updated;
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'third_party_deliveries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteByOrderId(int orderId) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'third_party_deliveries',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
  }

  Future<ThirdPartyDelivery?> _getById(int id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'third_party_deliveries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }
}
