import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/cart_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class MainShellLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShellLayout> createState() => _MainShellLayoutState();
}

class _MainShellLayoutState extends ConsumerState<MainShellLayout> {
  int _lastTapTime = 0;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final clientsLabel = currentLocale.languageCode == 'ku' ? 'کڕیارەکان' : currentLocale.languageCode == 'ar' ? 'العملاء' : 'Clients';

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. The Main Application Content (forced edge-to-edge)
          MediaQuery.removePadding(
            context: context,
            removeBottom: true, // Forces inner SafeAreas to ignore the bottom home indicator gap
            child: widget.navigationShell,
          ),


          // 3. The True Floating Pill Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 20, // Lowered vertically as requested
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavItem(
                          context,
                          index: 0,
                          icon: Icons.dashboard_outlined,
                          activeIcon: Icons.dashboard,
                          label: localizations.dashboard,
                        ),
                        _buildNavItem(
                          context,
                          index: 1,
                          icon: Icons.shopping_bag_outlined,
                          activeIcon: Icons.shopping_bag,
                          label: currentLocale.languageCode == 'ku' ? 'فرۆشتن' : currentLocale.languageCode == 'ar' ? 'المبيعات' : 'POS',
                          badgeCount: cartItems.length,
                        ),
                        _buildNavItem(
                          context,
                          index: 2,
                          icon: Icons.people_outline,
                          activeIcon: Icons.people,
                          label: clientsLabel,
                        ),
                        _buildNavItem(
                          context,
                          index: 3,
                          icon: Icons.inventory_2_outlined,
                          activeIcon: Icons.inventory,
                          label: localizations.inventory,
                        ),
                        _buildNavItem(
                          context,
                          index: 4,
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings,
                          label: localizations.settings,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Inactive text/icon colors
    final inactiveColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    // Active colors: Pure black text/icon, and "black liquid glass" for the pill
    final activeColor = isDark ? Colors.white : Colors.black;
    final activeBgColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.06); // Extremely subtle smooth tint

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: 60,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
          decoration: BoxDecoration(
            color: isSelected ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey<bool>(isSelected),
                      color: isSelected ? activeColor : inactiveColor,
                      size: 26,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? activeBgColor : Colors.transparent, width: 2),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ).animate().shake(duration: 300.ms),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                    child: Text(label, maxLines: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTapTime < 300) return; // Debounce fast taps
    _lastTapTime = now;

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}

