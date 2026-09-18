import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../data/repositories/business_profile_repository.dart';
import '../data/repositories/cloud_company_profile_repository.dart';
import '../models/fiscal_profile.dart';
import '../services/storage_mode_service.dart';

class SettingsChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class BusinessSettings {
  const BusinessSettings({
    required this.gstRegistered,
    required this.shopName,
    required this.ownerName,
    this.subtitle = '',
    this.logoPath = '',
    required this.phone,
    required this.address,
    required this.defaultDeliveryChargePaise,
    required this.minimumPreparationBufferMinutes,
    required this.gstNumber,
    this.fiscalProfile,
  });

  final String shopName;
  final String ownerName;
  final String subtitle;
  final String logoPath;
  final String phone;
  final String address;
  final bool gstRegistered;
  final String gstNumber;
  final int defaultDeliveryChargePaise;
  final int minimumPreparationBufferMinutes;
  final FiscalProfile? fiscalProfile;

  FiscalProfile get resolvedFiscalProfile =>
      fiscalProfile ??
      CountryPresets.india().copyWith(
        taxIdentifier: gstNumber.isEmpty ? null : gstNumber,
        taxEnabled: gstRegistered,
      );
}


class BusinessSettingsManager {
  final BusinessProfileRepository _businessProfileRepository;
  final CloudCompanyProfileRepository _cloudCompanyProfileRepository;
  final StorageModeService _storageModeService;

  BusinessSettingsManager({
    BusinessProfileRepository? businessProfileRepository,
    CloudCompanyProfileRepository? cloudCompanyProfileRepository,
    StorageModeService? storageModeService,
  })  : _businessProfileRepository =
            businessProfileRepository ?? BusinessProfileRepository(),
        _cloudCompanyProfileRepository =
            cloudCompanyProfileRepository ?? CloudCompanyProfileRepository(),
        _storageModeService = storageModeService ?? StorageModeService();

  static final SettingsChangeNotifier changeNotifier =
      SettingsChangeNotifier();

  static FiscalProfile activeFiscalProfile = CountryPresets.india();

  static void notifySettingsChanged() {
    changeNotifier.notify();
  }

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

  static const String _countryCodeKey = 'business.country_code';
  static const String _currencyCodeKey = 'business.currency_code';
  static const String _currencySymbolKey = 'business.currency_symbol';
  static const String _taxEnabledKey = 'business.tax_enabled';
  static const String _taxLabelKey = 'business.tax_label';
  static const String _taxRatePercentKey = 'business.tax_rate_percent';
  static const String _taxInclusiveKey = 'business.tax_inclusive';
  static const String _taxIdentifierKey = 'business.tax_identifier';
  static const String _localeKey = 'business.locale';
  static const String _timeZoneKey = 'business.time_zone';

  Future<BusinessSettings> load() async {
    final fiscal = await getFiscalProfile();

    if (kIsWeb) {
      try {
        final cloudProfile =
            await _cloudCompanyProfileRepository.getCachedProfile();
        if (cloudProfile != null && cloudProfile.name.trim().isNotEmpty) {
          final taxId = cloudProfile.taxIdentifier?.trim() ?? '';
          return BusinessSettings(
            shopName: cloudProfile.name.trim(),
            ownerName: '',
            subtitle: cloudProfile.shortDescription?.trim() ?? '',
            logoPath: '',
            phone: cloudProfile.phone?.trim() ?? '',
            address: cloudProfile.address?.trim() ?? '',
            gstRegistered: taxId.isNotEmpty,
            gstNumber: taxId,
            defaultDeliveryChargePaise: 0,
            minimumPreparationBufferMinutes: 60,
            fiscalProfile: fiscal,
          );
        }
      } catch (_) {}
      return BusinessSettings(
        shopName: 'Floraprise',
        ownerName: '',
        subtitle: '',
        logoPath: '',
        phone: '',
        address: '',
        gstRegistered: false,
        gstNumber: '',
        defaultDeliveryChargePaise: 0,
        minimumPreparationBufferMinutes: 60,
        fiscalProfile: fiscal,
      );
    }

    // In Cloud mode, resolve from the authenticated Cloud company profile.
    if (await _storageModeService.isCloud()) {
      final cloudProfile =
          await _cloudCompanyProfileRepository.getCachedProfile();
      if (cloudProfile != null && cloudProfile.name.trim().isNotEmpty) {
        final taxId = cloudProfile.taxIdentifier?.trim() ?? '';
        return BusinessSettings(
          shopName: cloudProfile.name.trim(),
          ownerName: '',
          subtitle: cloudProfile.shortDescription?.trim() ?? '',
          logoPath: '',
          phone: cloudProfile.phone?.trim() ?? '',
          address: cloudProfile.address?.trim() ?? '',
          gstRegistered: taxId.isNotEmpty,
          gstNumber: taxId,
          defaultDeliveryChargePaise: await _loadDeliveryCharge(),
          minimumPreparationBufferMinutes: await _loadPreparationBuffer(),
          fiscalProfile: fiscal,
        );
      }
    }

    // Try to load from business_profile table first (Local mode)
    final profile = await _businessProfileRepository.getBusinessProfile();

    if (profile != null) {
      return BusinessSettings(
        shopName: profile.shopName,
        ownerName: profile.ownerName,
        subtitle: '',
        logoPath: await getLogoPath(),
        phone: profile.mobileNumber,
        address: profile.address ?? '',
        gstRegistered: profile.gstRegistered,
        gstNumber: profile.gstNumber ?? '',
        defaultDeliveryChargePaise: await _loadDeliveryCharge(),
        minimumPreparationBufferMinutes: await _loadPreparationBuffer(),
        fiscalProfile: fiscal,
      );
    }

    // Fallback to settings table for backward compatibility (Local mode)
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
      subtitle: '',
      logoPath: await getLogoPath(),
      phone: _fallback(phone, ''),
      address: _fallback(address, ''),
      gstRegistered: gstRegistered,
      gstNumber: _fallback(gstNumber, ''),
      defaultDeliveryChargePaise: defaultDeliveryChargePaise,
      minimumPreparationBufferMinutes: minimumPreparationBufferMinutes,
      fiscalProfile: fiscal,
    );
  }

  
  Future<int> _loadDeliveryCharge() async {
    if (kIsWeb) return 0;
    final db = await AppDatabase.instance.database;
    final deliveryRaw = await _readValue(db, _deliveryChargeKey);
    return int.tryParse(deliveryRaw ?? '') ?? 0;
  }
  
  Future<int> _loadPreparationBuffer() async {
    if (kIsWeb) return 60;
    final db = await AppDatabase.instance.database;
    final preparationBufferRaw =
        await _readValue(db, _minimumPreparationBufferMinutesKey);
    return _normalizePreparationBufferMinutes(preparationBufferRaw);
  }

  Future<void> setShopName(String value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _shopNameKey, value.trim());
    notifySettingsChanged();
  }

  Future<void> setOwnerName(String value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _ownerNameKey, value.trim());
    notifySettingsChanged();
  }

  Future<void> setPhone(String value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _phoneKey, value.trim());
    notifySettingsChanged();
  }

  Future<void> setAddress(String value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _addressKey, value.trim());
    notifySettingsChanged();
  }

  Future<void> setGstRegistered(bool value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _gstRegisteredKey, value ? '1' : '0');
    notifySettingsChanged();
  }

  Future<void> setGstNumber(String value) async {
    if (kIsWeb) return;
    await _saveToBusinessProfile();
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _gstNumberKey, value.trim());
    notifySettingsChanged();
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
    if (kIsWeb) return;
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
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _shopNameKey, shopName.trim());
    await _writeValue(db, _ownerNameKey, ownerName.trim());
    await _writeValue(db, _phoneKey, mobileNumber.trim());
    if (address != null) {
      await _writeValue(db, _addressKey, address.trim());
    }
    await _writeValue(db, _gstRegisteredKey, gstRegistered ? '1' : '0');
    if (gstNumber != null) {
      await _writeValue(db, _gstNumberKey, gstNumber.trim());
    }
    notifySettingsChanged();
  }
  
  Future<void> _saveToBusinessProfile() async {
    // This is a placeholder - actual save should be done explicitly
    // through saveBusinessProfile method
  }

  Future<void> setDefaultDeliveryChargePaise(int paise) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    final normalized = paise < 0 ? 0 : paise;
    await _writeValue(db, _deliveryChargeKey, normalized.toString());
  }

  Future<void> setMinimumPreparationBufferMinutes(int minutes) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    final normalized = minutes <= 0 ? 60 : minutes;
    await _writeValue(
      db,
      _minimumPreparationBufferMinutesKey,
      normalized.toString(),
    );
  }

  Future<void> setWhatsapp(String value) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _whatsappKey, value.trim());
  }

  Future<String> getWhatsapp() async {
    if (kIsWeb) return '';
    final db = await AppDatabase.instance.database;
    return _fallback(await _readValue(db, _whatsappKey), '');
  }

  Future<void> setLogoPath(String value) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _logoPathKey, value.trim());
  }

  Future<String> getLogoPath() async {
    if (kIsWeb) return '';
    final db = await AppDatabase.instance.database;
    return _fallback(await _readValue(db, _logoPathKey), '');
  }

  Future<void> setSamePhoneAsWhatsapp(bool value) async {
    if (kIsWeb) return;
    final db = await AppDatabase.instance.database;
    await _writeValue(db, _samePhoneWhatsappKey, value ? '1' : '0');
  }

  Future<bool> isSamePhoneAsWhatsapp() async {
    if (kIsWeb) return true;
    final db = await AppDatabase.instance.database;
    final raw = await _readValue(db, _samePhoneWhatsappKey);
    return raw == null ? true : raw == '1';
  }

  Future<FiscalProfile> getFiscalProfile() async {
    final profile = await _resolveFiscalProfile();
    activeFiscalProfile = profile;
    return profile;
  }

  Future<FiscalProfile> _resolveFiscalProfile() async {
    if (kIsWeb || await _storageModeService.isCloud()) {
      try {
        final cloudProfile =
            await _cloudCompanyProfileRepository.getCachedProfile();
        if (cloudProfile != null && cloudProfile.name.trim().isNotEmpty) {
          final region = cloudProfile.region.trim().isNotEmpty
              ? cloudProfile.region.trim()
              : CountryPresets.countryCodeForCurrency(cloudProfile.currencyCode);
          final preset = CountryPresets.forCountry(
              region.isNotEmpty ? region : cloudProfile.currencyCode);
          final curr = cloudProfile.currencyCode.trim().isNotEmpty
              ? cloudProfile.currencyCode.trim()
              : preset.currencyCode;
          final symbol = curr.toUpperCase() == 'USD'
              ? '\$'
              : (curr.toUpperCase() == 'AED'
                  ? 'د.إ'
                  : (curr.toUpperCase() == 'INR' ? '₹' : preset.currencySymbol));
          final taxId = cloudProfile.taxIdentifier?.trim();

          final taxEnabled = cloudProfile.taxEnabled ??
              ((taxId != null && taxId.isNotEmpty) || preset.taxEnabled);
          final taxLabel = cloudProfile.taxLabel?.trim().isNotEmpty == true
              ? cloudProfile.taxLabel!.trim()
              : preset.taxLabel;
          final taxRatePercent =
              cloudProfile.taxRatePercent ?? preset.taxRatePercent;
          final taxInclusive =
              cloudProfile.taxInclusive ?? preset.taxInclusive;

          return FiscalProfile(
            countryCode: preset.countryCode,
            currencyCode: curr,
            currencySymbol: symbol,
            taxEnabled: taxEnabled,
            taxLabel: taxLabel,
            taxRatePercent: taxRatePercent,
            taxInclusive: taxInclusive,
            taxIdentifier: taxId,
            locale: preset.locale,
            timeZone: cloudProfile.timeZone.isNotEmpty
                ? cloudProfile.timeZone
                : preset.timeZone,
          );
        }
      } catch (_) {}
      return CountryPresets.india();
    }

    // Local SQLite mode: check settings table first
    final db = await AppDatabase.instance.database;
    final storedCountry = await _readValue(db, _countryCodeKey);
    if (storedCountry != null && storedCountry.trim().isNotEmpty) {
      final preset = CountryPresets.forCountry(storedCountry);
      final storedCurrency = await _readValue(db, _currencyCodeKey);
      final storedSymbol = await _readValue(db, _currencySymbolKey);
      final storedTaxEnabled = await _readValue(db, _taxEnabledKey);
      final storedTaxLabel = await _readValue(db, _taxLabelKey);
      final storedTaxRate = await _readValue(db, _taxRatePercentKey);
      final storedTaxInclusive = await _readValue(db, _taxInclusiveKey);
      final storedTaxId = await _readValue(db, _taxIdentifierKey);
      final storedLocale = await _readValue(db, _localeKey);
      final storedTimeZone = await _readValue(db, _timeZoneKey);

      final taxEnabled = storedTaxEnabled == null
          ? preset.taxEnabled
          : storedTaxEnabled == '1' ||
              storedTaxEnabled.toLowerCase() == 'true';
      final taxInclusive = storedTaxInclusive == null
          ? preset.taxInclusive
          : storedTaxInclusive == '1' ||
              storedTaxInclusive.toLowerCase() == 'true';
      final taxRatePercent =
          double.tryParse(storedTaxRate ?? '') ?? preset.taxRatePercent;

      return FiscalProfile(
        countryCode: storedCountry.trim().toUpperCase(),
        currencyCode: _fallback(storedCurrency, preset.currencyCode),
        currencySymbol: _fallback(storedSymbol, preset.currencySymbol),
        taxEnabled: taxEnabled,
        taxLabel: _fallback(storedTaxLabel, preset.taxLabel),
        taxRatePercent: taxRatePercent,
        taxInclusive: taxInclusive,
        taxIdentifier: storedTaxId?.trim(),
        locale: _fallback(storedLocale, preset.locale),
        timeZone: _fallback(storedTimeZone, preset.timeZone),
      );
    }

    // Fallback: Check business_profile table
    final profile = await _businessProfileRepository.getBusinessProfile();
    if (profile != null) {
      return CountryPresets.india().copyWith(
        taxEnabled: profile.gstRegistered,
        taxIdentifier: profile.gstNumber,
      );
    }

    // Fallback: Check legacy settings table
    final gstRaw = await _readValue(db, _gstRegisteredKey);
    final gstNumber = await _readValue(db, _gstNumberKey);
    final gstRegistered = gstRaw == null ? true : gstRaw == '1';

    return CountryPresets.india().copyWith(
      taxEnabled: gstRegistered,
      taxIdentifier: gstNumber?.trim(),
    );
  }

  Future<void> setFiscalProfile(FiscalProfile profile) async {
    activeFiscalProfile = profile;
    if (!kIsWeb) {
      final db = await AppDatabase.instance.database;
      await _writeValue(db, _countryCodeKey, profile.countryCode);
      await _writeValue(db, _currencyCodeKey, profile.currencyCode);
      await _writeValue(db, _currencySymbolKey, profile.currencySymbol);
      await _writeValue(db, _taxEnabledKey, profile.taxEnabled ? '1' : '0');
      await _writeValue(db, _taxLabelKey, profile.taxLabel);
      await _writeValue(
          db, _taxRatePercentKey, profile.taxRatePercent.toString());
      await _writeValue(db, _taxInclusiveKey, profile.taxInclusive ? '1' : '0');
      if (profile.taxIdentifier != null) {
        await _writeValue(db, _taxIdentifierKey, profile.taxIdentifier!.trim());
        await _writeValue(db, _gstNumberKey, profile.taxIdentifier!.trim());
      }
      await _writeValue(db, _gstRegisteredKey, profile.taxEnabled ? '1' : '0');
      await _writeValue(db, _localeKey, profile.locale);
      await _writeValue(db, _timeZoneKey, profile.timeZone);
    }

    if (kIsWeb || await _storageModeService.isCloud()) {
      final cached = await _cloudCompanyProfileRepository.getCachedProfile();
      if (cached != null) {
        final updated = cached.copyWith(
          region: profile.countryCode,
          currencyCode: profile.currencyCode,
          timeZone: profile.timeZone,
          taxIdentifier: profile.taxIdentifier,
          taxEnabled: profile.taxEnabled,
          taxLabel: profile.taxLabel,
          taxRatePercent: profile.taxRatePercent,
          taxInclusive: profile.taxInclusive,
        );
        await _cloudCompanyProfileRepository.saveCachedProfile(updated);
      }
    }

    notifySettingsChanged();
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
