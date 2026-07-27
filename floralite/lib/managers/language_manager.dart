import '../data/database/app_database.dart';

class LanguageManager {
  static const String _defaultLanguage = 'en';

  Future<String> getSavedLanguage() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT value FROM settings WHERE key = ?',
      ['language'],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String? ?? _defaultLanguage;
    }
    return _defaultLanguage;
  }

  Future<void> saveLanguage(String languageCode) async {
    final db = await AppDatabase.instance.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, ?)',
      ['language', languageCode, DateTime.now().toIso8601String()],
    );
  }

  Future<void> clearLanguage() async {
    final db = await AppDatabase.instance.database;
    await db.rawDelete('DELETE FROM settings WHERE key = ?', ['language']);
  }
}
