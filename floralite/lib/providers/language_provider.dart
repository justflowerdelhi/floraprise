import 'package:flutter/material.dart';
import '../managers/language_manager.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider(this._languageManager);

  final LanguageManager _languageManager;
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  Future<void> loadSavedLanguage() async {
    final languageCode = await _languageManager.getSavedLanguage();
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode) async {
    await _languageManager.saveLanguage(languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }
}
