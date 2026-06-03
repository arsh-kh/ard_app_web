import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/localization/dashboard_translations.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final langCode = currentLocale.languageCode;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final localizations = AppLocalizations.of(context)!;

    String t(String key) => DashboardTranslations.get(key, langCode);
    final profileLabel = langCode == 'ku' ? 'پڕۆفایل' : langCode == 'ar' ? 'الملف الشخصي' : 'Profile';
    final preferencesLabel = langCode == 'ku' ? 'ڕێکخستنەکان' : langCode == 'ar' ? 'التفضيلات' : 'Preferences';
    final darkModeLabel = langCode == 'ku' ? 'دۆخی تاریک' : langCode == 'ar' ? 'الوضع الداكن' : 'Dark Mode';
    final systemLabel = langCode == 'ku' ? 'سیستەم' : langCode == 'ar' ? 'النظام' : 'System Default';
    final logoutLabel = langCode == 'ku' ? 'چوونە دەرەوە' : langCode == 'ar' ? 'تسجيل الخروج' : 'Log Out';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settings),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          // Profile Card Mockup
          _buildSectionHeader(context, profileLabel),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t('appName')} Admin',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'admin@ardapp.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {}, // Edit profile stub
                    icon: const Icon(Icons.edit_outlined),
                    color: theme.colorScheme.primary,
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Preferences
          _buildSectionHeader(context, preferencesLabel),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(darkModeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(themeMode == ThemeMode.system ? systemLabel : '', style: const TextStyle(fontSize: 12)),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
                  value: themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark),
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.language, color: theme.colorScheme.primary),
                  title: Text(localizations.language, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    langCode == 'en' ? 'English' : langCode == 'ku' ? 'کوردی' : 'العربية',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showLanguagePicker(context, ref, currentLocale.languageCode);
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {}, // Stub
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Danger Zone
          Card(
            elevation: 0,
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: theme.colorScheme.error.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text(logoutLabel, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
              onTap: () {
                // Logout mock
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$logoutLabel...')),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          
          // Footer
          Center(
            child: Text(
              '${t('appName')} - Ard App v1.0.0\nMade with ❤️',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String currentLangCode) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('English', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentLangCode == 'en' ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('کوردی', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentLangCode == 'ku' ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('ku'));
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('العربية', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: currentLangCode == 'ar' ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(const Locale('ar'));
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
