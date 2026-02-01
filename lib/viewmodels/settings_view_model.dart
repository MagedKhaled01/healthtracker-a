import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsService _service;

  SettingsViewModel({SettingsService? service}) 
      : _service = service ?? SettingsService();

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isDark = await _service.getIsDarkMode();
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      final langCode = await _service.getLanguageCode();
      _locale = Locale(langCode);
    } catch (e) {
      debugPrint("Error loading settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _service.setDarkMode(isDark);
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'ar') return;
    _locale = Locale(code);
    notifyListeners();
    await _service.setLanguageCode(code);
  }
}
