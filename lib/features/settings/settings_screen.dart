import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/localization/dashboard_translations.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/image_picker_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final langCode = currentLocale.languageCode;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final localizations = AppLocalizations.of(context)!;

    String t(String key) => DashboardTranslations.get(key, langCode);
    final profileLabel = langCode == 'ku' ? 'پڕۆفایل' : langCode == 'ar' ? 'الملف الشخصي' : 'ACCOUNT';
    final preferencesLabel = langCode == 'ku' ? 'ڕێکخستنەکان' : langCode == 'ar' ? 'التفضيلات' : 'PREFERENCES';
    final darkModeLabel = langCode == 'ku' ? 'دۆخی تاریک' : langCode == 'ar' ? 'الوضع الداكن' : 'Dark Mode';
    final systemLabel = langCode == 'ku' ? 'سیستەم' : langCode == 'ar' ? 'النظام' : 'System';
    final logoutLabel = langCode == 'ku' ? 'چوونە دەرەوە' : langCode == 'ar' ? 'تسجيل الخروج' : 'Log Out';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Glassmorphic App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 24, bottom: 16, end: 24),
                  title: Text(
                    localizations.settings,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Hero Segment
                  _buildSectionLabel(profileLabel).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push(Routes.editProfile),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              Hero(
                                tag: 'avatar_${user?.id}',
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                                  ),
                                  child: ImagePickerWidget(
                                    initialImagePath: user?.imageUrl,
                                    radius: 38,
                                    placeholderIcon: Icons.person_rounded,
                                    onImageSelected: (path) {
                                      ref.read(authProvider.notifier).updateProfile(avatarPath: path);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.name ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user?.email ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  
                  const SizedBox(height: 32),

                  // Preferences Segment
                  _buildSectionLabel(preferencesLabel).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          icon: Icons.dark_mode_rounded,
                          iconBg: const Color(0xFF1E1E1E),
                          iconFg: Colors.white,
                          title: darkModeLabel,
                          subtitle: themeMode == ThemeMode.system ? systemLabel : '',
                          theme: theme,
                          trailing: Switch.adaptive(
                            value: themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark),
                            activeTrackColor: theme.colorScheme.primary,
                            onChanged: (val) {
                              ref.read(themeModeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                            },
                          ),
                        ),
                        _buildDivider(theme),
                        _buildSettingsRow(
                          icon: Icons.language_rounded,
                          iconBg: Colors.blueAccent,
                          iconFg: Colors.white,
                          title: localizations.language,
                          subtitle: langCode == 'en' ? 'English' : langCode == 'ku' ? 'کوردی' : 'العربية',
                          theme: theme,
                          onTap: () => _showLanguagePicker(context, ref, currentLocale.languageCode),
                        ),
                        _buildDivider(theme),
                        if (user?.role == 'admin') ...[
                          _buildSettingsRow(
                            icon: Icons.history_rounded,
                            iconBg: Colors.teal,
                            iconFg: Colors.white,
                            title: langCode == 'ku' ? 'تۆماری چالاکییەکان' : langCode == 'ar' ? 'سجل النشاط' : 'Audit Logs',
                            subtitle: '',
                            theme: theme,
                            onTap: () => context.push(Routes.auditLogs),
                          ),
                          _buildDivider(theme),
                        ],
                        _buildSettingsRow(
                          icon: Icons.notifications_rounded,
                          iconBg: Colors.redAccent,
                          iconFg: Colors.white,
                          title: langCode == 'ku' ? 'ئاگادارییەکان' : langCode == 'ar' ? 'الإشعارات' : 'Notifications',
                          subtitle: '',
                          theme: theme,
                          onTap: () => context.push(Routes.notifications),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),
                  
                  // Danger Zone
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => ref.read(authProvider.notifier).logout(),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                          child: Center(
                            child: Text(
                              logoutLabel,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                  const SizedBox(height: 48),
                  
                  // Footer
                  Center(
                    child: Text(
                      '${t('appName')} v1.0.0',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 12, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconBg,
    required Color iconFg,
    required String title,
    String subtitle = '',
    Widget? trailing,
    VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconFg, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const Spacer(),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Spacer(),
                    ]
                  ],
                ),
              ),
              trailing ?? Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 68.0),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLangCode) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    currentLangCode == 'ku' ? 'هەڵبژاردنی زمان' : currentLangCode == 'ar' ? 'اختر اللغة' : 'Select Language',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLangOption(ctx, ref, 'English', 'en', currentLangCode),
                  const SizedBox(height: 12),
                  _buildLangOption(ctx, ref, 'کوردی (Sorani)', 'ku', currentLangCode),
                  const SizedBox(height: 12),
                  _buildLangOption(ctx, ref, 'العربية', 'ar', currentLangCode),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangOption(BuildContext context, WidgetRef ref, String title, String code, String current) {
    final theme = Theme.of(context);
    final isSelected = code == current;
    return InkWell(
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(Locale(code));
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.scaffoldBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

