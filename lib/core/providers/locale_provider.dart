import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  static const _localeKey = 'app_locale';

  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_localeKey);
    if (savedCode != null) {
      if (savedCode == 'ku') {
        state = const Locale('ku');
        AppConstants.languageCode = 'ku';
        AppConstants.currencySymbol = 'د.ع';
      } else if (savedCode == 'ar') {
        state = const Locale('ar');
        AppConstants.languageCode = 'ar';
        AppConstants.currencySymbol = 'د.ع';
      } else {
        state = const Locale('en');
        AppConstants.languageCode = 'en';
        AppConstants.currencySymbol = 'IQD';
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == const Locale('en') || locale == const Locale('ku') || locale == const Locale('ar')) {
      state = locale;
      
      if (locale.languageCode == 'ku') {
        AppConstants.languageCode = 'ku';
        AppConstants.currencySymbol = 'د.ع';
      } else if (locale.languageCode == 'ar') {
        AppConstants.languageCode = 'ar';
        AppConstants.currencySymbol = 'د.ع';
      } else {
        AppConstants.languageCode = 'en';
        AppConstants.currencySymbol = 'IQD';
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

