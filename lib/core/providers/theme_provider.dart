import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'app_theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    // Force light mode natively for the first time as requested
    return ThemeMode.light;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_key);
    if (savedValue != null) {
      if (savedValue == 'dark') {
        state = ThemeMode.dark;
      } else if (savedValue == 'system') {
        state = ThemeMode.system;
      } else {
        state = ThemeMode.light;
      }
    }
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

