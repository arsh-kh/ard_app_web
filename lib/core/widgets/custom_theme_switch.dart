import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/theme_provider.dart';

class CustomThemeSwitch extends ConsumerWidget {
  final VoidCallback onToggle;

  const CustomThemeSwitch({
    super.key,
    required this.onToggle,
    // Ignored legacy parameters
    String? dayText,
    String? nightText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    const switchWidth = 56.0;
    const switchHeight = 30.0;
    const thumbSize = 24.0;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: switchWidth,
        height: switchHeight,
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFD1D1D6),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
              color: Colors.black87,
              size: 14,
            ),
          ),
        ),
      ),
    );
  }
}
