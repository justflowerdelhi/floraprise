import '../data/database/app_database.dart';

class LanguageManager {
  static const String _defaultLanguage = 'en';
  static const Set<String> _supportedLanguages = {'en', 'hi', 'gu'};

  String _normalizeLanguageCode(String? languageCode) {
    final normalized = languageCode?.trim().toLowerCase();
    if (normalized == null || !_supportedLanguages.contains(normalized)) {
      return _defaultLanguage;
    }

    return normalized;
  }

  Future<String> getSavedLanguage() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT value FROM settings WHERE key = ?',
      ['language'],
    );
    if (result.isNotEmpty) {
      return _normalizeLanguageCode(result.first['value'] as String?);
    }
    return _defaultLanguage;
  }

  Future<void> saveLanguage(String languageCode) async {
    final normalizedLanguageCode = _normalizeLanguageCode(languageCode);
    final db = await AppDatabase.instance.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (key, value, updated_at) VALUES (?, ?, ?)',
      ['language', normalizedLanguageCode, DateTime.now().toIso8601String()],
    );
  }

  Future<void> clearLanguage() async {
    final db = await AppDatabase.instance.database;
    await db.rawDelete('DELETE FROM settings WHERE key = ?', ['language']);
  }
}
