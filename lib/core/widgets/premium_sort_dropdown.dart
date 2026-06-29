import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_translations.dart';
import '../../core/providers/locale_provider.dart';

class SortOption<T> {
  final String labelKey;
  final IconData icon;
  final T value;

  const SortOption({
    required this.labelKey,
    required this.icon,
    required this.value,
  });
}

class PremiumSortDropdown<T> extends ConsumerWidget {
  final List<SortOption<T>> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  const PremiumSortDropdown({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final langCode = ref.watch(localeProvider).languageCode;

    // Premium styling colors
    final menuColor = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final iconColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    final selectedBgColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: PopupMenuButton<T>(
        icon: const Icon(Icons.sort),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF2F2F2F) : Colors.black12,
            width: 1,
          ),
        ),
        color: menuColor,
        elevation: 12,
        offset: const Offset(0, 48), // Drops down slightly below the icon
        onSelected: onSelected,
        itemBuilder: (context) {
          return options.map((option) {
            final isSelected = option.value == selectedValue;
            return PopupMenuItem<T>(
              value: option.value,
              padding: EdgeInsets.zero,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? selectedBgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 20,
                      color: isSelected ? theme.colorScheme.primary : iconColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final fullText = Tr.t(option.labelKey, langCode);
                          final textStyle = TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : textColor,
                          );

                          if (fullText.contains('|')) {
                            final parts = fullText.split('|');
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(parts[0], style: textStyle),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : iconColor,
                                  ),
                                ),
                                Text(
                                  parts.length > 1 ? parts[1] : '',
                                  style: textStyle,
                                ),
                              ],
                            );
                          }
                          return Text(fullText, style: textStyle);
                        },
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
