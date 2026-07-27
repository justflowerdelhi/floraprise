import 'package:flutter/material.dart';
import '../data/database/app_database.dart';

class VoiceProvider extends ChangeNotifier {
  static const String _voiceEnabledKey = 'voice_enabled';

  bool _voiceEnabled = false;

  bool get voiceEnabled => _voiceEnabled;

  Future<void> loadVoiceSetting() async {
    final db = await AppDatabase.instance.database;
    final result = await db.rawQuery(
      'SELECT value FROM settings WHERE key = ?',
      [_voiceEnabledKey],
    );
    if (result.isNotEmpty) {
      _voiceEnabled = (result.first['value'] as String) == '1';
    }
    notifyListeners();
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    final db = await AppDatabase.instance.database;
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      [_voiceEnabledKey, enabled ? '1' : '0'],
    );
    _voiceEnabled = enabled;
    notifyListeners();
  }
}
