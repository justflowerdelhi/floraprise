import '../data/database/app_database.dart';
import '../data/repositories/business_profile_repository.dart';
import 'package:sqflite/sqflite.dart';

class BusinessSettings {
  const BusinessSettings({
    required this.gstRegistered,
    required this.shopName,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.defaultDeliveryChargePaise,
    required this.minimumPreparationBufferMinutes,
    required this.gstNumber,
  });

  final String shopName;
  final String ownerName;
  final String phone;
  final String address;
  final bool gstRegistered;
  final String gstNumber;
  final int defaultDeliveryChargePaise;
  final int minimumPreparationBufferMinutes;
}

class BusinessSettingsManager {
  final BusinessProfileRepository _businessProfileRepository = BusinessProfileRepository();
  
  static const String _shopNameKey = 'business.shop_name';
  static const String _ownerNameKey = 'business.owner_name';
  static const String _phoneKey = 'business.phone';
  static const String _addressKey = 'business.address';
  static const String _gstRegisteredKey = 'business.gst_registered';
  static const String _gstNumberKey = 'business.gst_number';
  static const String _deliveryChargeKey =
      'business.default_delivery_charge_paise';
  static const String _minimumPreparationBufferMinutesKey =
      'business.minimum_preparation_buffer_minutes';
  static const String _whatsappKey = 'business.whatsapp';
  static const String _logoPathKey = 'business.logo_path';
  static const String _samePhoneWhatsappKey = 'business.same_phone_whatsapp';

  Future<BusinessSettings> load() async {
    // Try to load from business_profile table first
    final profile = await _businessProfileRepository.getBusinessProfile();
    
    if (profile != null) {
      return BusinessSettings(
        shopName: profile.shopName,
        ownerName: profile.ownerName,
        phone: profile.mobileNumber,
        address: profile.address ?? '',
        gstRegistered: profile.gstRegistered,
        gstNumber: profile.gstNumber ?? '',
        defaultDeliveryChargePaise: await _loadDeliveryCharge(),
        minimumPreparationBufferMinutes: await _loadPreparationBuffer(),
      );
    }
    
    // Fallback to settings table for backward compatibility
    final db = await AppDatabase.instance.database;
    final shopName = await _readValue(db, _shopNameKey);
    final ownerName = await _readValue(db, _ownerNameKey);
    final phone = await _readValue(db, _phoneKey);
    final address = await _readValue(db, _addressKey);
    final gstRaw = await _readValue(db, _gstRegisteredKey);
    final gstNumber = await _readValue(db, _gstNumberKey);
    final deliveryRaw = await _readValue(db, _deliveryChargeKey);
    final preparationBufferRaw =
        await _readValue(db, _minimumPreparationBufferMinutesKey);

    final gstRegistered = gstRaw == null ? true : gstRaw == '1';
    final defaultDeliveryChargePaise = int.tryParse(deliveryRaw ?? '') ?? 0;
    final minimumPreparationBufferMinutes =
        _normalizePreparationBufferMinutes(preparationBufferRaw);

    return BusinessSettings(
      shopName: _fallback(shopName, 'My Flower Shop'),
      ownerName: _fallback(ownerName, ''),
      phone: _fallback(phone, ''),
      address: _fallback(address, ''),
      gstRegistered: gstRegistered,
      gstNumber: _fallback(gstNumber, ''),
      defaultDeliveryChargePaise: defaultDeliveryChargePaise,
      minimumPreparationBufferMinutes: minimumPreparationBufferMinutes,
    );
  }
  
  Future<int> _loadDeliveryCharge() async {
    final db = await AppDatabase.instance.database;
    final deliveryRaw = await _readValue(db, _deliveryChargeKey);
    return int.tryParse(deliveryRaw ?? '') ?? 0;
  }
  
  Future<int> _loadPreparationBuffer() async {
    final db = await AppDatabase.instance.database;
    final preparationBufferRaw =
        await _readValue(db, _minimumPreparationBufferMinutesKey);
    return _normalizePreparationBufferMinutes(preparationBufferRaw);
  }

  Future<void> setShopName(String value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _shopNameKey, value.trim());
  }

  Future<void> setOwnerName(String value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _ownerNameKey, value.trim());
  }

  Future<void> setPhone(String value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _phoneKey, value.trim());
  }

  Future<void> setAddress(String value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _addressKey, value.trim());
  }

  Future<void> setGstRegistered(bool value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _gstRegisteredKey, value ? '1' : '0');
  }

  Future<void> setGstNumber(String value) async {
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _gstNumberKey, value.trim());
  }
  
  Future<void> saveBusinessProfile({
    required String shopName,
    required String ownerName,
    required String mobileNumber,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    required bool gstRegistered,
    String? gstNumber,
  }) async {
    await _businessProfileRepository.saveBusinessProfile(
      shopName: shopName,
      ownerName: ownerName,
      mobileNumber: mobileNumber,
      email: email,
      address: address,
      city: city,
      state: state,
      pinCode: pinCode,
      gstRegistered: gstRegistered,
      gstNumber: gstNumber,
    );
  }
  
  Future<void> _saveToBusinessProfile() async {
    // This is a placeholder - actual save should be done explicitly
    // through saveBusinessProfile method
  }

  Future<void> setDefaultDeliveryChargePaise(int paise) async {
    final db = await AppDatabase.instance.database;
    final normalized = paise < 0 ? 0 : paise;
    await _writeValue(db, _deliveryChargeKey, normalized.toString());
  }

  Future<void> setMinimumPreparationBufferMinutes(int minutes) async {
    final db = await AppDatabase.instance.database;
    final normalized = minutes <= 0 ? 60 : minutes;
    await _writeValue(
      db,
      _minimumPreparationBufferMinutesKey,
      normalized.toString(),
    );
  }

  Future<void> setWhatsapp(String value) async {
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _whatsappKey, value.trim());
  }

  Future<String> getWhatsapp() async {
    final db = await AppDatabase.instance.database;
    return _fallback(await _readValue(db, _whatsappKey), '');
  }

  Future<void> setLogoPath(String value) async {
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _logoPathKey, value.trim());
  }

  Future<String> getLogoPath() async {
    final db = await AppDatabase.instance.database;
    return _fallback(await _readValue(db, _logoPathKey), '');
  }

  Future<void> setSamePhoneAsWhatsapp(bool value) async {
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _samePhoneWhatsappKey, value ? '1' : '0');
  }

  Future<bool> isSamePhoneAsWhatsapp() async {
    final db = await AppDatabase.instance.database;
    final raw = await _readValue(db, _samePhoneWhatsappKey);
    return raw == null ? true : raw == '1';
  }

  Future<String?> _readValue(Database db, String key) async {
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _writeValue(Database db, String key, String value) async {
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _fallback(String? value, String defaultValue) {
    if (value == null) return defaultValue;
    final trimmed = value.trim();
    return trimmed.isEmpty ? defaultValue : trimmed;
  }

  int _normalizePreparationBufferMinutes(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 60;
    return parsed;
  }
}
