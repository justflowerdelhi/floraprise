import '../data/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class OnboardingChecklist {
  const OnboardingChecklist({
    required this.shopSetup,
    required this.starterCatalogue,
    required this.firstCustomer,
    required this.firstSale,
    required this.printerTest,
  });

  final bool shopSetup;
  final bool starterCatalogue;
  final bool firstCustomer;
  final bool firstSale;
  final bool printerTest;

  bool get completed =>
      shopSetup &&
      starterCatalogue &&
      firstCustomer &&
      firstSale &&
      printerTest;
}

class OnboardingManager {
  static const String _completedKey = 'onboarding.completed';
  static const String _languageSelectedKey = 'onboarding.language_selected';
  static const String _shopSetupDoneKey = 'onboarding.shop_setup_completed';
  static const String _starterDoneKey =
      'onboarding.starter_catalogue_completed';
  static const String _permissionsDoneKey = 'onboarding.permissions_requested';
  static const String _printerTestKey = 'onboarding.printer_tested';

  Future<bool> isOnboardingCompleted() async {
    return _readBool(_completedKey, defaultValue: false);
  }

  Future<void> setLanguageSelected(bool value) async {
    await _writeBool(_languageSelectedKey, value);
  }

  Future<void> setShopSetupCompleted(bool value) async {
    await _writeBool(_shopSetupDoneKey, value);
  }

  Future<void> setStarterCatalogueCompleted(bool value) async {
    await _writeBool(_starterDoneKey, value);
  }

  Future<void> setPermissionsRequested(bool value) async {
    await _writeBool(_permissionsDoneKey, value);
  }

  Future<void> markPrinterTested() async {
    await _writeBool(_printerTestKey, true);
  }

  Future<void> completeOnboarding() async {
    await _writeBool(_completedKey, true);
  }

  Future<void> resetOnboarding() async {
    final db = await AppDatabase.instance.database;
    const keys = <String>[
      _completedKey,
      _languageSelectedKey,
      _shopSetupDoneKey,
      _starterDoneKey,
      _permissionsDoneKey,
      _printerTestKey,
    ];
    await db.delete(
      'settings',
      where: 'key IN (${List.filled(keys.length, '?').join(',')})',
      whereArgs: keys,
    );
  }

  Future<OnboardingChecklist> getChecklist() async {
    final db = await AppDatabase.instance.database;

    final customerRows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM customers WHERE deleted_at IS NULL',
    );
    final orderRows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM orders WHERE status NOT IN ('draft','cancelled')",
    );

    return OnboardingChecklist(
      shopSetup: await _readBool(_shopSetupDoneKey, defaultValue: false),
      starterCatalogue: await _readBool(_starterDoneKey, defaultValue: false),
      firstCustomer: (customerRows.first['c'] as int? ?? 0) > 0,
      firstSale: (orderRows.first['c'] as int? ?? 0) > 0,
      printerTest: await _readBool(_printerTestKey, defaultValue: false),
    );
  }

  Future<bool> _readBool(String key, {required bool defaultValue}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return defaultValue;
    return (rows.first['value'] as String?) == '1';
  }

  Future<void> _writeBool(String key, bool value) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value ? '1' : '0',
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
