import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _welcomeKey = 'has_seen_welcome';
  ThemeMode _themeMode = ThemeMode.system;
  bool _hasSeenWelcome = false;
  bool _isLoaded = false;
  ThemeMode get themeMode => _themeMode;
  bool get hasSeenWelcome => _hasSeenWelcome;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _themeMode = switch (preferences.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _hasSeenWelcome = preferences.getBool(_welcomeKey) ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> completeWelcome() async {
    _hasSeenWelcome = true;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_welcomeKey, true);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
  }
}

