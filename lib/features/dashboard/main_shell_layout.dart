import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/cart_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/app_translations.dart';

class MainShellLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShellLayout> createState() => _MainShellLayoutState();
}

class _MainShellLayoutState extends ConsumerState<MainShellLayout> {
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final lang = currentLocale.languageCode;
    final clientsLabel = Tr.t('clientsLabel', lang);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: Stack(
        children: [
          // 1. The Main Application Content (forced edge-to-edge)
          MediaQuery.removePadding(
            context: context,
            removeBottom:
                true, // Forces inner SafeAreas to ignore the bottom home indicator gap
            child: widget.navigationShell,
          ),
          // 2. Gradient Blur Background Overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
                      theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 3. The True Floating Pill Navigation Bar
          Positioned(
            left: 20,
            right: 20,
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
                  color: isDark ? const Color(0xFF141414) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final activeIndex = widget.navigationShell.currentIndex;
                      final isRtl =
                          Directionality.of(context) == TextDirection.rtl;

                      // Total flex is 500 * 4 + 600 = 2600
                      const double totalFlex = 2600.0;

                      // Calculate flex before the active item
                      double flexBefore = 0.0;
                      for (int i = 0; i < activeIndex; i++) {
                        flexBefore += 500;
                      }

                      final double pillWidth =
                          (600 / totalFlex) * constraints.maxWidth;
                      final double pillLeftOffset =
                          (flexBefore / totalFlex) * constraints.maxWidth;

                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            top: 4,
                            bottom: 4,
                            left: isRtl ? null : pillLeftOffset,
                            right: isRtl ? pillLeftOffset : null,
                            width: pillWidth,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3B3B3B)
                                    : Colors.black.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                          Row(
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
                                label: Tr.t('posLabel', lang),
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
                        ],
                      );
                    },
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
    final activeBgColor = isDark
        ? const Color(0xFF3B3B3B)
        : Colors.black.withValues(alpha: 0.06); // Extremely subtle smooth tint

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      tween: Tween<double>(
        begin: isSelected ? 1.0 : 0.0,
        end: isSelected ? 1.0 : 0.0,
      ),
      builder: (context, value, child) {
        return Expanded(
          flex: (500 + (value * 100))
              .round(), // smoothly interpolates flex from 500 to 600!
          child: child!,
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          height: 67,
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(100),
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
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor ?? Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? activeBgColor
                                : Colors.transparent,
                            width: 2,
                          ),
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
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
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
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
