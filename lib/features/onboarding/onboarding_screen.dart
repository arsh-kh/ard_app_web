import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/routing/routes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      _buildWelcomePage(context, lang, isDark),
      _buildLanguagePage(context, lang, isDark),
      _buildThemePage(context, lang, isDark),
      _buildPage(
        icon: Icons.rocket_launch_rounded,
        title: Tr.t('onboardingTitle4', lang),
        desc: Tr.t('onboardingDesc4', lang),
        isDark: isDark,
      ),
    ];

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: pages.length,
            itemBuilder: (context, index) => pages[index],
          ),

          // Skip button
          if (_currentPage < pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    Tr.t('skipBtn', lang),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 24,
            right: 24,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (or invisible placeholder to keep dots centered)
                  AnimatedOpacity(
                    opacity: _currentPage > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _currentPage == 0,
                      child: IconButton(
                        onPressed: () {
                          if (_currentPage > 0) {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.all(14),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                    ),
                  ),

                  // Dots indicator
                  Row(
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? (Theme.of(context).colorScheme.onSurface)
                              : (Theme.of(context).colorScheme.surfaceContainerHighest),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentPage == pages.length - 1
                        ? ElevatedButton(
                            key: const ValueKey('start'),
                            onPressed: _finishOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.onSurface,
                              foregroundColor: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              Tr.t('getStartedBtn', lang),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : IconButton(
                            key: const ValueKey('next'),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.onSurface,
                              foregroundColor: Theme.of(context).colorScheme.surface,
                              padding: const EdgeInsets.all(14),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context, String lang, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Tr.t('onboardingWelcomeTitle', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).colorScheme.onSurface).withValues(
                    alpha: 0.03,
                  ),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              Tr.t('onboardingWelcomeDesc', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.5,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemePage(BuildContext context, String lang, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).colorScheme.onSurface).withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            Tr.t('onboardingThemeTitle', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Tr.t('onboardingThemeDesc', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 48),
          _themeTile(
            label: Tr.t('themeLight', lang),
            icon: Icons.light_mode_rounded,
            mode: ThemeMode.light,
            currentMode: themeMode,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _themeTile(
            label: Tr.t('themeDark', lang),
            icon: Icons.dark_mode_rounded,
            mode: ThemeMode.dark,
            currentMode: themeMode,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _themeTile({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required bool isDark,
  }) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).colorScheme.surfaceContainerHighest)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (Theme.of(context).colorScheme.onSurface)
                : (Theme.of(context).colorScheme.surfaceContainerHighest),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePage(BuildContext context, String lang, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Tr.t('onboardingTitle1', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            Tr.t('onboardingDesc1', lang),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 48),
          _langTile('English', 'en', lang, isDark),
          const SizedBox(height: 12),
          _langTile('کوردی سۆرانی', 'ku', lang, isDark),
          const SizedBox(height: 12),
          _langTile('العربية', 'ar', lang, isDark),
        ],
      ),
    );
  }

  Widget _langTile(String label, String code, String currentLang, bool isDark) {
    final isSelected = currentLang == code;
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).colorScheme.surfaceContainerHighest)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (Theme.of(context).colorScheme.onSurface)
                : (Theme.of(context).colorScheme.surfaceContainerHighest),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).colorScheme.onSurface).withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 40,
                  spreadRadius: 10,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 100,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
