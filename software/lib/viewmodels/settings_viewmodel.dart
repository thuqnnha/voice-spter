import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  static const _keyDark = 'is_dark_mode';
  static const _keyMute = 'is_muted';

  bool _isDark = true;
  bool _isMuted = false;

  bool get isDark  => _isDark;
  bool get isMuted => _isMuted;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark  = prefs.getBool(_keyDark) ?? true;
    _isMuted = prefs.getBool(_keyMute) ?? false;
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
}