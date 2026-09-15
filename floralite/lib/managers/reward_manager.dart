import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';
import '../data/repositories/cloud_rewards_settings_repository.dart';
import '../services/mobile_auth_service.dart';
import '../services/storage_mode_service.dart';

class RewardSettings {
  const RewardSettings({
    required this.enabled,
    required this.earnSpendPaisePerPoint,
    required this.minimumBillPaise,
    required this.pointValuePaise,
    required this.maximumRedemptionPercent,
    required this.expiryDays,
  });

  final bool enabled;
  final int earnSpendPaisePerPoint;
  final int minimumBillPaise;
  final int pointValuePaise;
  final int maximumRedemptionPercent;
  final int expiryDays;

  static const defaults = RewardSettings(
    enabled: true,
    earnSpendPaisePerPoint: 10000,
    minimumBillPaise: 30000,
    pointValuePaise: 100,
    maximumRedemptionPercent: 20,
    expiryDays: 365,
  );
}

class RewardManager {
  static const String _enabledKey = 'rewards.enabled';
  static const String _earnSpendPaisePerPointKey =
      'rewards.earn_spend_paise_per_point';
  static const String _minimumBillPaiseKey = 'rewards.minimum_bill_paise';
  static const String _pointValuePaiseKey = 'rewards.point_value_paise';
  static const String _maximumRedemptionPercentKey =
      'rewards.maximum_redemption_percent';
  static const String _expiryDaysKey = 'rewards.expiry_days';

  final StorageModeService _storageModeService;
  final MobileAuthService _authService;
  final CloudRewardsSettingsRepository _cloudRepository;

  RewardSettings? _cachedSettings;
  DateTime? _lastCacheFetchTime;
  static const Duration _cacheTtl = Duration(minutes: 10);

  RewardManager({
    StorageModeService? storageModeService,
    MobileAuthService? authService,
    CloudRewardsSettingsRepository? cloudRepository,
  })  : _storageModeService = storageModeService ?? StorageModeService(),
        _authService = authService ?? MobileAuthService(),
        _cloudRepository = cloudRepository ?? CloudRewardsSettingsRepository();

  Future<bool> get _isCloud async =>
      kIsWeb || await _storageModeService.isCloud();

  void invalidateCache() {
    _cachedSettings = null;
    _lastCacheFetchTime = null;
  }

  Future<RewardSettings> loadSettings({bool forceRefresh = false}) async {
    if (await _isCloud) {
      final now = DateTime.now();
      if (!forceRefresh &&
          _cachedSettings != null &&
          _lastCacheFetchTime != null &&
          now.difference(_lastCacheFetchTime!) < _cacheTtl) {
        return _cachedSettings!;
      }

      final token = await _authService.getStoredAccessToken();
      if (token != null && token.trim().isNotEmpty) {
        try {
          final fetched = await _cloudRepository.fetchSettings(
            baseUrl: _authService.baseUrl,
            accessToken: token,
          );
          _cachedSettings = fetched;
          _lastCacheFetchTime = now;
          return fetched;
        } catch (_) {
          if (_cachedSettings != null) {
            return _cachedSettings!;
          }
        }
      }
      return _cachedSettings ?? RewardSettings.defaults;
    }

    final db = await AppDatabase.instance.database;
    const defaults = RewardSettings.defaults;
    final loaded = RewardSettings(
      enabled: (await _readValue(db, _enabledKey)) != '0',
      earnSpendPaisePerPoint: _positiveInt(
        await _readValue(db, _earnSpendPaisePerPointKey),
        defaults.earnSpendPaisePerPoint,
      ),
      minimumBillPaise: _nonNegativeInt(
        await _readValue(db, _minimumBillPaiseKey),
        defaults.minimumBillPaise,
      ),
      pointValuePaise: _positiveInt(
        await _readValue(db, _pointValuePaiseKey),
        defaults.pointValuePaise,
      ),
      maximumRedemptionPercent: _percent(
        await _readValue(db, _maximumRedemptionPercentKey),
        defaults.maximumRedemptionPercent,
      ),
      expiryDays: _positiveInt(
        await _readValue(db, _expiryDaysKey),
        defaults.expiryDays,
      ),
    );
    _cachedSettings = loaded;
    _lastCacheFetchTime = DateTime.now();
    return loaded;
  }

  Future<void> saveSettings(RewardSettings settings) async {
    if (await _isCloud) {
      final token = await _authService.getStoredAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw StateError('You must be logged in to save reward settings.');
      }
      final persisted = await _cloudRepository.saveSettings(
        baseUrl: _authService.baseUrl,
        accessToken: token,
        settings: settings,
      );
      _cachedSettings = persisted;
      _lastCacheFetchTime = DateTime.now();
      return;
    }

    final db = await AppDatabase.instance.database;
    await _writeValue(db, _enabledKey, settings.enabled ? '1' : '0');
    await _writeValue(
      db,
      _earnSpendPaisePerPointKey,
      settings.earnSpendPaisePerPoint.toString(),
    );
    await _writeValue(
      db,
      _minimumBillPaiseKey,
      settings.minimumBillPaise.toString(),
    );
    await _writeValue(
      db,
      _pointValuePaiseKey,
      settings.pointValuePaise.toString(),
    );
    await _writeValue(
      db,
      _maximumRedemptionPercentKey,
      settings.maximumRedemptionPercent.toString(),
    );
    await _writeValue(db, _expiryDaysKey, settings.expiryDays.toString());
    _cachedSettings = settings;
    _lastCacheFetchTime = DateTime.now();
  }

  int calculateEarnedPoints({
    required int paidBillPaise,
    required RewardSettings settings,
  }) {
    if (!settings.enabled || paidBillPaise < settings.minimumBillPaise) {
      return 0;
    }
    return paidBillPaise ~/ settings.earnSpendPaisePerPoint;
  }

  int calculateMaximumRedeemablePoints({
    required int billPaise,
    required int availablePoints,
    required RewardSettings settings,
  }) {
    if (!settings.enabled ||
        billPaise < settings.minimumBillPaise ||
        availablePoints <= 0) {
      return 0;
    }
    final maximumDiscountPaise =
        (billPaise * settings.maximumRedemptionPercent / 100).floor();
    final maximumPointsByBill =
        maximumDiscountPaise ~/ settings.pointValuePaise;
    if (maximumPointsByBill <= 0) return 0;
    return availablePoints < maximumPointsByBill
        ? availablePoints
        : maximumPointsByBill;
  }

  int redemptionAmountPaise({
    required int points,
    required RewardSettings settings,
  }) {
    if (!settings.enabled || points <= 0) return 0;
    return points * settings.pointValuePaise;
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

  int _positiveInt(String? raw, int defaultValue) {
    final value = int.tryParse(raw ?? '');
    if (value == null || value <= 0) return defaultValue;
    return value;
  }

  int _nonNegativeInt(String? raw, int defaultValue) {
    final value = int.tryParse(raw ?? '');
    if (value == null || value < 0) return defaultValue;
    return value;
  }

  int _percent(String? raw, int defaultValue) {
    final value = int.tryParse(raw ?? '');
    if (value == null || value < 0 || value > 100) return defaultValue;
    return value;
  }
}
