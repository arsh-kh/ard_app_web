import 'dart:math' show pi;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/routing/routes.dart';

import 'widgets/onboarding_page_indicator.dart';
import 'widgets/animated_card_stack.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with TickerProviderStateMixin {
  late final AnimationController _cardsAnimationController;
  late final AnimationController _pageIndicatorAnimationController;

  late List<Animation<Offset>> _slideAnimations;
  late Animation<double> _pageIndicatorAnimation;

  int _currentPage = 1;
  int _indicatorPage = 1; // Used for precise timing of the arc fill
  final int _totalPages = 4;

  @override
  void initState() {
    super.initState();
    _cardsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _pageIndicatorAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700), // Matched to card slide duration for smoothness
    );

    _setPageIndicatorAnimation();
    _setCardsSlideInAnimation(); // Initialize synchronously before first build!
    _cardsAnimationController.forward();
  }

  @override
  void dispose() {
    _cardsAnimationController.dispose();
    _pageIndicatorAnimationController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go(Routes.login);
  }

  void _setCardsSlideInAnimation() {
    setState(() {
      _slideAnimations = [
        Tween<Offset>(begin: const Offset(3.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
        ),
        Tween<Offset>(begin: const Offset(1.5, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic)),
        ),
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
        ),
      ];
    });
    _cardsAnimationController.reset();
  }

  void _setCardsSlideOutAnimation() {
    setState(() {
      _slideAnimations = [
        Tween<Offset>(begin: Offset.zero, end: const Offset(-3.0, 0.0)).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.0, 0.8, curve: Curves.easeInCubic)),
        ),
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, 0.0)).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.1, 0.9, curve: Curves.easeInCubic)),
        ),
        Tween<Offset>(begin: Offset.zero, end: const Offset(-1.0, 0.0)).animate(
          CurvedAnimation(parent: _cardsAnimationController, curve: const Interval(0.2, 1.0, curve: Curves.easeInCubic)),
        ),
      ];
    });
    _cardsAnimationController.reset();
  }

  void _setPageIndicatorAnimation({bool isClockwiseAnimation = true}) {
    // Github repo spins the entire circle 360 degrees (2 * pi)
    final multiplier = isClockwiseAnimation ? 2 : -2;

    setState(() {
      _pageIndicatorAnimation = Tween(
        begin: 0.0,
        end: multiplier * pi,
      ).animate(
        CurvedAnimation(
          parent: _pageIndicatorAnimationController,
          curve: Curves.easeInOutCubic, // Much smoother than easeIn
        ),
      );
      _pageIndicatorAnimationController.reset();
    });
  }

  Future<void> _nextPage() async {
    if (_currentPage == _totalPages) {
      _finishOnboarding();
      return;
    }

    if (_pageIndicatorAnimationController.status == AnimationStatus.dismissed) {
      _pageIndicatorAnimationController.forward().ignore();
      
      // Update the indicator exactly in the middle of the 700ms spin (350ms)
      // so the segment turns black while it's rotating fastest, hiding the change.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _indicatorPage++;
          });
        }
      });
      
      _setCardsSlideOutAnimation();
      await _cardsAnimationController.forward();
      
      if (!mounted) return;
      
      setState(() {
        _currentPage++;
      });
      
      _setCardsSlideInAnimation();
      await _cardsAnimationController.forward();
      
      _setPageIndicatorAnimation(isClockwiseAnimation: true);
    }
  }

  Widget _buildCardContent(IconData icon, String label, {required bool isDark}) {
    final color = isDark ? Colors.white : Colors.black;
    return GlassCard(
      isDark: isDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 72, color: color),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getAnimatedCards(String lang) {
    List<Widget> cards = [];
    int? activeIndex;

    switch (_currentPage) {
      case 1:
        // Gestures active (activeIndex = null)
        cards = [
          _buildCardContent(Icons.waving_hand_rounded, Tr.t('cardWelcome', lang), isDark: false),
          _buildCardContent(Icons.storefront_rounded, Tr.t('cardManage', lang), isDark: true),
        ];
        break;
      case 2:
        // Language screen: 3 cards, synced to language state
        cards = [
          _buildCardContent(Icons.language_rounded, "Language", isDark: false),
          _buildCardContent(Icons.language_rounded, "زمان", isDark: true),
          _buildCardContent(Icons.language_rounded, "اللغة", isDark: true),
        ];
        if (lang == 'en') {
          activeIndex = 0;
        } else if (lang == 'ku') {
          activeIndex = 1;
        } else if (lang == 'ar') {
          activeIndex = 2;
        }
        break;
      case 3:
        // Theme screen: 2 cards, synced to theme state
        cards = [
          _buildCardContent(Icons.light_mode_rounded, Tr.t('themeLight', lang), isDark: false),
          _buildCardContent(Icons.dark_mode_rounded, Tr.t('themeDark', lang), isDark: true),
        ];
        final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
        activeIndex = isDarkTheme ? 1 : 0;
        break;
      case 4:
        cards = [
          _buildCardContent(Icons.task_alt_rounded, Tr.t('cardReady', lang), isDark: false),
          _buildCardContent(Icons.rocket_launch_rounded, Tr.t('cardStart', lang), isDark: true),
        ];
        break;
      default:
        cards = [];
    }

    return AnimatedCardStack(
      cards: cards,
      slideAnimations: _slideAnimations,
      activeIndex: activeIndex,
    );
  }

  Widget _buildOptionButton(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? Colors.transparent 
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.surface,
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(String lang) {
    String titleKey;
    String descKey;

    switch (_currentPage) {
      case 1:
        titleKey = 'onboardingWelcomeTitle';
        descKey = 'onboardingWelcomeDesc';
        break;
      case 2:
        titleKey = 'onboardingTitle1';
        descKey = 'onboardingDesc1';
        break;
      case 3:
        titleKey = 'onboardingThemeTitle';
        descKey = 'onboardingThemeDesc';
        break;
      case 4:
        titleKey = 'onboardingTitle4';
        descKey = 'onboardingDesc4';
        break;
      default:
        titleKey = 'onboardingWelcomeTitle';
        descKey = 'onboardingWelcomeDesc';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey<int>(_currentPage),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Tr.t(titleKey, lang),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            Tr.t(descKey, lang),
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.2, end: 0),
          
          if (_currentPage == 2) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                _buildOptionButton(
                  'English', 
                  lang == 'en', 
                  () => ref.read(localeProvider.notifier).setLocale(const Locale('en'))
                ),
                _buildOptionButton(
                  'کوردی', 
                  lang == 'ku', 
                  () => ref.read(localeProvider.notifier).setLocale(const Locale('ku'))
                ),
                _buildOptionButton(
                  'العربية', 
                  lang == 'ar', 
                  () => ref.read(localeProvider.notifier).setLocale(const Locale('ar'))
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ],
          
          if (_currentPage == 3) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                _buildOptionButton(
                  Tr.t('themeLight', lang), 
                  Theme.of(context).brightness == Brightness.light, 
                  () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light)
                ),
                _buildOptionButton(
                  Tr.t('themeDark', lang), 
                  Theme.of(context).brightness == Brightness.dark, 
                  () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark)
                ),
              ],
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkTheme ? const Color(0xFF0A0A0A) : const Color(0xFFF9F9F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Adjusted vertical padding
          child: Column(
            children: [
              // Header
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text(
                    Tr.t('skipBtn', lang),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Cards Section (Takes up all available middle space, perfectly centering the cards)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _getAnimatedCards(lang),
                    ),
                  ),
                ),
              ),
              
              // Text and Controls Section (Hugs the bottom of the screen tightly)
              Column(
                mainAxisSize: MainAxisSize.min, // Hugs its content
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextContent(lang),
                  
                  const SizedBox(height: 32), // Strictly controlled, perfect gap between text and next button
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Next / Start Button (Animated)
                      AnimatedBuilder(
                        animation: _pageIndicatorAnimation,
                        builder: (_, Widget? child) {
                          return OnboardingPageIndicator(
                            angle: _pageIndicatorAnimation.value,
                            currentPage: _indicatorPage, // Uses perfectly timed indicator page
                            totalPages: _totalPages,
                            child: child!,
                          );
                        },
                        child: InkWell(
                          onTap: _nextPage,
                          borderRadius: BorderRadius.circular(36),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Icon(
                                _currentPage == _totalPages ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16), // Bottom safe area padding
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
