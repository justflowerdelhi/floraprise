import 'package:sqflite/sqflite.dart';

import '../data/database/app_database.dart';

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

  Future<RewardSettings> loadSettings() async {
    final db = await AppDatabase.instance.database;
    const defaults = RewardSettings.defaults;
    return RewardSettings(
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
      maximumRedemptionPercent: _boundedPercent(
        await _readValue(db, _maximumRedemptionPercentKey),
        defaults.maximumRedemptionPercent,
      ),
      expiryDays: _positiveInt(
        await _readValue(db, _expiryDaysKey),
        defaults.expiryDays,
      ),
    );
  }

  Future<void> saveSettings(RewardSettings settings) async {
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
    return rows.isEmpty ? null : rows.first['value'] as String?;
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

  int _positiveInt(String? raw, int fallback) {
    final parsed = int.tryParse(raw ?? '');
    return parsed == null || parsed <= 0 ? fallback : parsed;
  }

  int _nonNegativeInt(String? raw, int fallback) {
    final parsed = int.tryParse(raw ?? '');
    return parsed == null || parsed < 0 ? fallback : parsed;
  }

  int _boundedPercent(String? raw, int fallback) {
    final parsed = int.tryParse(raw ?? '');
    if (parsed == null) return fallback;
    if (parsed < 0) return 0;
    if (parsed > 100) return 100;
    return parsed;
  }
}
