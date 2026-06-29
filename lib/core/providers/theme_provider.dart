import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    return _loadFromPrefs();
  }

  ThemeMode _loadFromPrefs() {
    // Read synchronously using the global sharedPrefs initialized in main.dart
    final savedValue = sharedPrefs.getString(_key);
    if (savedValue != null) {
      if (savedValue == 'dark') {
        return ThemeMode.dark;
      } else if (savedValue == 'system') {
        return ThemeMode.system;
      }
    }
    // Force light mode natively for the first time as requested
    return ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (mode == ThemeMode.dark) {
      await prefs.setString(_key, 'dark');
    } else if (mode == ThemeMode.system) {
      await prefs.setString(_key, 'system');
    } else {
      await prefs.setString(_key, 'light');
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
