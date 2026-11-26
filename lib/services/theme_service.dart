import 'package:flutter/material.dart';
import 'storage_service.dart';

/// Centralized Theme Mode State Controller (FR-06, FR-07, FR-08)
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _storageKey = 'is_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadFromStorage() async {
    final saved = await StorageService().loadBool(_storageKey, global: true);
    if (saved != null) {
      final target = saved ? ThemeMode.dark : ThemeMode.light;
      if (_themeMode != target) {
        _themeMode = target;
        notifyListeners();
      }
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    StorageService().saveBool(_storageKey, isDarkMode, global: true);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      StorageService().saveBool(_storageKey, isDarkMode, global: true);
      notifyListeners();
    }
  }
}

