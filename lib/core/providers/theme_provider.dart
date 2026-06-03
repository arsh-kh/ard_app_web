import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  // Defaulting to system, but this can be switched to light/dark
  // and in the future persisted with shared_preferences.
  return ThemeMode.system;
});
