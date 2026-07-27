import 'dart:ui';

import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../data/repositories/business_profile_repository.dart';
import '../managers/business_settings_manager.dart';
import '../models/share_branding.dart';

class ShareBrandingSettingsService {
  static const String _showPriceKey = 'share_branding.show_price';
  static const String _showShopNameKey = 'share_branding.show_shop_name';
  static const String _showPhoneKey = 'share_branding.show_phone_number';
  static const String _showLogoKey = 'share_branding.show_logo';
  static const String _showWatermarkKey = 'share_branding.show_watermark';
  static const String _showWatermarkBusinessNameKey =
      'share_branding.watermark.show_business_name';
  static const String _showWatermarkCityKey =
      'share_branding.watermark.show_city';
  static const String _watermarkOpacityKey = 'share_branding.watermark.opacity';
  static const String _watermarkSizeKey = 'share_branding.watermark.size';
  static const String _watermarkPositionKey =
      'share_branding.watermark.position';
  static const String _showWebsiteKey = 'share_branding.show_website';
  static const String _footerColorKey = 'share_branding.footer_color_argb';

  static const String _businessWebsiteKey = 'business.website';
  static const String _businessInstagramKey = 'business.instagram';
  static const String _businessFacebookKey = 'business.facebook';

  final BusinessProfileRepository _businessProfileRepository;
  final BusinessSettingsManager _businessSettingsManager;

  ShareBrandingSettingsService({
    BusinessProfileRepository? businessProfileRepository,
    BusinessSettingsManager? businessSettingsManager,
  })  : _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository(),
        _businessSettingsManager =
            businessSettingsManager ?? BusinessSettingsManager();

  Future<ShareBrandingSettings> loadSettings() async {
    final db = await AppDatabase.instance.database;
    return ShareBrandingSettings(
      showPrice: await _readBool(db, _showPriceKey, defaultValue: true),
      showShopName: await _readBool(db, _showShopNameKey, defaultValue: true),
      showPhoneNumber: await _readBool(db, _showPhoneKey, defaultValue: true),
      showLogo: await _readBool(db, _showLogoKey, defaultValue: true),
      showWatermark: await _readBool(db, _showWatermarkKey, defaultValue: true),
      showWatermarkBusinessName: await _readBool(
        db,
        _showWatermarkBusinessNameKey,
        defaultValue: true,
      ),
      showWatermarkCity:
          await _readBool(db, _showWatermarkCityKey, defaultValue: true),
      watermarkOpacity: await _readDouble(
        db,
        _watermarkOpacityKey,
        defaultValue: 0.72,
      ),
      watermarkSize: await _readEnum(
        db,
        _watermarkSizeKey,
        WatermarkSize.values,
        WatermarkSize.medium,
      ),
      watermarkPosition: await _readEnum(
        db,
        _watermarkPositionKey,
        WatermarkPosition.values,
        WatermarkPosition.bottomCenter,
      ),
      showWebsite: await _readBool(db, _showWebsiteKey, defaultValue: true),
      footerColor:
          await _readColor(db, _footerColorKey, defaultValue: 0xCC1B5E20),
    );
  }

  Future<void> saveSettings(ShareBrandingSettings settings) async {
    final db = await AppDatabase.instance.database;
    await _writeBool(db, _showPriceKey, settings.showPrice);
    await _writeBool(db, _showShopNameKey, settings.showShopName);
    await _writeBool(db, _showPhoneKey, settings.showPhoneNumber);
    await _writeBool(db, _showLogoKey, settings.showLogo);
    await _writeBool(db, _showWatermarkKey, settings.showWatermark);
    await _writeBool(
      db,
      _showWatermarkBusinessNameKey,
      settings.showWatermarkBusinessName,
    );
    await _writeBool(
      db,
      _showWatermarkCityKey,
      settings.showWatermarkCity,
    );
    await _writeValue(
      db,
      _watermarkOpacityKey,
      settings.watermarkOpacity.toString(),
    );
    await _writeValue(db, _watermarkSizeKey, settings.watermarkSize.name);
    await _writeValue(
      db,
      _watermarkPositionKey,
      settings.watermarkPosition.name,
    );
    await _writeBool(db, _showWebsiteKey, settings.showWebsite);
    await _writeValue(
        db, _footerColorKey, settings.footerColor.toARGB32().toString());
  }

  Future<ShareBrandingIdentity> loadBrandingIdentity() async {
    final profile = await _businessProfileRepository.getBusinessProfile();
    final db = await AppDatabase.instance.database;

    final shopName = _trim(profile?.shopName);
    final phoneNumber = _trim(profile?.mobileNumber);
    final logoPath = _trim(await _businessSettingsManager.getLogoPath());
    final website = _trim(await _readValue(db, _businessWebsiteKey));
    final instagram = _trim(await _readValue(db, _businessInstagramKey));
    final facebook = _trim(await _readValue(db, _businessFacebookKey));
    final address = _mergeAddress(profile);

    return ShareBrandingIdentity(
      shopName: shopName,
      phoneNumber: phoneNumber,
      logoPath: logoPath,
      website: website,
      instagram: instagram,
      facebook: facebook,
      address: address,
      city: _trim(profile?.city),
    );
  }

  String _mergeAddress(BusinessProfile? profile) {
    if (profile == null) return '';
    final parts = <String>[];
    final address = _trim(profile.address);
    final city = _trim(profile.city);
    final state = _trim(profile.state);
    final pinCode = _trim(profile.pinCode);
    if (address.isNotEmpty) parts.add(address);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pinCode.isNotEmpty) parts.add(pinCode);
    return parts.join(', ');
  }

  Future<bool> _readBool(
    Database db,
    String key, {
    required bool defaultValue,
  }) async {
    final raw = await _readValue(db, key);
    if (raw == null) return defaultValue;
    return raw == '1';
  }

  Future<void> _writeBool(Database db, String key, bool value) {
    return _writeValue(db, key, value ? '1' : '0');
  }

  Future<double> _readDouble(
    Database db,
    String key, {
    required double defaultValue,
  }) async {
    final value = double.tryParse(await _readValue(db, key) ?? '');
    return value ?? defaultValue;
  }

  Future<T> _readEnum<T extends Enum>(
    Database db,
    String key,
    List<T> values,
    T defaultValue,
  ) async {
    final raw = await _readValue(db, key);
    return values.where((value) => value.name == raw).firstOrNull ??
        defaultValue;
  }

  Future<Color> _readColor(
    Database db,
    String key, {
    required int defaultValue,
  }) async {
    final raw = await _readValue(db, key);
    final parsed = int.tryParse(raw ?? '');
    return Color(parsed ?? defaultValue);
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

  String _trim(String? value) {
    if (value == null) return '';
    return value.trim();
  }
}
