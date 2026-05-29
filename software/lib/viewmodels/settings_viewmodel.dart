import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_strings.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _keyDark = 'is_dark_mode';
  static const _keyMute = 'is_muted';
  static const _keyLanguage = 'language';

  bool _isDark = true;
  bool _isMuted = false;
  AppLanguage _language = AppLanguage.vietnamese;

  bool get isDark  => _isDark;
  bool get isMuted => _isMuted;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _isDark = prefs.getBool(_keyDark) ?? true;
    _isMuted = prefs.getBool(_keyMute) ?? false;

    final lang = prefs.getString(_keyLanguage);

    if (lang == 'en') {
      _language = AppLanguage.english;
    } else {
      _language = AppLanguage.vietnamese;
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDark, _isDark);
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMute, _isMuted);
  }

  Future<void> toggleLanguage() async {
    _language =
    _language == AppLanguage.vietnamese
        ? AppLanguage.english
        : AppLanguage.vietnamese;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyLanguage,
      _language == AppLanguage.vietnamese ? 'vi' : 'en',
    );
  }
}

enum AppLanguage {
  vietnamese,
  english,
}