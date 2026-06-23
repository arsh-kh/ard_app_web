import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/enums.dart';

class SortPreferencesNotifier
    extends StateNotifier<Map<String, SortOptionType>> {
  SortPreferencesNotifier() : super({}) {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final Map<String, SortOptionType> loadedPrefs = {};
    for (final key in keys) {
      if (key.startsWith('sort_pref_')) {
        final screenKey = key.replaceFirst('sort_pref_', '');
        final sortValueStr = prefs.getString(key);

        if (sortValueStr != null) {
          try {
            final sortOption = SortOptionType.values.firstWhere(
              (e) => e.name == sortValueStr,
            );
            loadedPrefs[screenKey] = sortOption;
          } catch (e) {
            // Invalid sort value saved, ignore
          }
        }
      }
    }

    if (loadedPrefs.isNotEmpty) {
      state = loadedPrefs;
    }
  }

  Future<void> setSort(String screenKey, SortOptionType sort) async {
    state = {...state, screenKey: sort};

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sort_pref_$screenKey', sort.name);
  }
}

final sortPreferencesProvider =
    StateNotifierProvider<SortPreferencesNotifier, Map<String, SortOptionType>>(
      (ref) {
        return SortPreferencesNotifier();
      },
    );
