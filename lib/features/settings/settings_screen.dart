import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/routing/routes.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/image_picker_widget.dart';
import '../../core/providers/business_provider.dart';
import '../../core/widgets/custom_theme_switch.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../data/repositories/user_repository.dart';
import 'data_wipe_dialog.dart' as data_wipe_dialog;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final GlobalKey _themeSwitchKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final langCode = currentLocale.languageCode;
    
    final businessAsync = ref.watch(currentBusinessEntityProvider);
    final business = businessAsync.valueOrNull;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final localizations = AppLocalizations.of(context)!;

    final profileLabel = Tr.t('profileLabel', langCode);
    final preferencesLabel = Tr.t('preferencesLabel', langCode);
    final darkModeLabel = Tr.t('darkModeLabel', langCode);
    final systemLabel = Tr.t('systemLabel', langCode);
    final logoutLabel = Tr.t('logoutLabel', langCode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localizations.settings),
        centerTitle: true,
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: Directionality.of(context) == TextDirection.rtl,
          hasBackButton: Navigator.canPop(context),
        ),
        actions: CustomTopBarHelper.buildActions(
          context: context,
          isRtl: Directionality.of(context) == TextDirection.rtl,
          hasBackButton: Navigator.canPop(context),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Standard Solid App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Hero Segment
                  _buildSectionLabel(
                    profileLabel,
                  ).animate().fadeIn().slideY(begin: 0.2),
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
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: ImagePickerWidget(
                                    initialImagePath: user?.imageUrl,
                                    isKurdish: langCode == 'ku',
                                    isArabic: langCode == 'ar',
                                    radius: 38,
                                    placeholderIcon: Icons.person_rounded,
                                    namePlaceholder: user?.name,
                                    onImageSelected: (path) {
                                      ref
                                          .read(authProvider.notifier)
                                          .updateProfile(
                                            avatarPath: path,
                                            removeAvatar: path == null,
                                          );
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
                                      user?.name ??
                                          Tr.t('unknownUser', langCode),
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
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Preferences Segment
                  _buildSectionLabel(
                    preferencesLabel,
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Inline Language Selector — first
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 14.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                localizations.language,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              _LanguageSegmentedPicker(
                                currentCode: langCode,
                                onChanged: (code) => ref
                                    .read(localeProvider.notifier)
                                    .setLocale(Locale(code)),
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                        _buildDivider(theme),
                        // Dark mode toggle — second
                        _buildSettingsRow(
                          title: darkModeLabel,
                          subtitle: themeMode == ThemeMode.system
                              ? systemLabel
                              : '',
                          theme: theme,
                          trailing: CustomThemeSwitch(
                            key: _themeSwitchKey,
                            onToggle: () {
                              final val =
                                  !(themeMode == ThemeMode.dark ||
                                      (themeMode == ThemeMode.system &&
                                          isDark));
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeMode(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                            },
                          ),
                        ),

                        if (user?.role == 'admin') ...[
                          _buildDivider(theme),
                          _buildSettingsRow(
                            title: Tr.t('auditLogs', langCode),
                            subtitle: '',
                            theme: theme,
                            onTap: () => context.push(Routes.auditLogs),
                          ),
                          _buildDivider(theme),
                          _buildSettingsRow(
                            title: Tr.t('manageUsers', langCode),
                            subtitle: '',
                            theme: theme,
                            onTap: () => context.push(Routes.adminUsers),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  if (business != null) ...[
                    _buildSectionLabel(Tr.t('workspace', langCode)).animate().fadeIn(delay: 120.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          if (user?.role == 'admin') ...[
                            _buildSettingsRow(
                              title: Tr.t('inviteEmployeesTitle', langCode),
                              theme: theme,
                              onTap: () => context.push(Routes.invite),
                            ),
                            _buildDivider(theme),
                          ],
                          _buildSettingsRow(
                            title: Tr.t('logoutBusinessBtn', langCode),
                            theme: theme,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) {
                                  String typedName = '';
                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      final isMatch = typedName.trim().toLowerCase() == business.name.toLowerCase();
                                      return AlertDialog(
                                        backgroundColor: theme.colorScheme.surface,
                                        title: Text(
                                          Tr.t('logoutBusinessTitle', langCode),
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              Tr.t('logoutBusinessDesc', langCode),
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                business.name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.colorScheme.onSurface,
                                                  letterSpacing: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TextField(
                                              autofocus: true,
                                              onChanged: (val) {
                                                setState(() => typedName = val);
                                              },
                                              decoration: InputDecoration(
                                                hintText: Tr.t('businessNameHintDialog', langCode),
                                                filled: true,
                                                fillColor: theme.colorScheme.surfaceContainerHighest,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide.none,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(
                                              Tr.t('cancelBtn', langCode),
                                              style: TextStyle(color: theme.colorScheme.onSurface),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: isMatch
                                                ? () async {
                                                    Navigator.pop(ctx);
                                                    final userId = user?.id;
                                                    if (userId != null) {
                                                      try {
                                                        await ref.read(userRepositoryProvider).updateUserBusinessAndRole(userId, '', 'employee', 'pending');
                                                      } catch (e) {
                                                        debugPrint('Error leaving workspace: $e');
                                                      }
                                                    }
                                                  }
                                                : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: theme.colorScheme.onSurface,
                                              foregroundColor: theme.colorScheme.surface,
                                            ),
                                            child: Text(Tr.t('leaveBtn', langCode)),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.2),
                    const SizedBox(height: 32),
                  ],

                  // Support Segment
                  _buildSectionLabel(
                    Tr.t('supportContact', langCode),
                  ).animate().fadeIn(delay: 210.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          title: Tr.t('helpCenter', langCode),
                          theme: theme,
                          onTap: () => context.push(Routes.helpCenter),
                        ),
                        _buildDivider(theme),
                        _buildSettingsRow(
                          title: Tr.t('contactUs', langCode),
                          theme: theme,
                          onTap: () => context.push(Routes.contactUs),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Data Management Segment (Admin only)
                  if (user?.role == 'admin') ...[
                    _buildSectionLabel(
                      Tr.t('dataManagement', langCode),
                    ).animate().fadeIn(delay: 230.ms).slideY(begin: 0.2),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildSettingsRow(
                            title: Tr.t('exportData', langCode),
                            theme: theme,
                            onTap: () => context.push(Routes.exportData),
                          ),

                        ],
                      ),
                    ).animate().fadeIn(delay: 235.ms).slideY(begin: 0.2),
                    const SizedBox(height: 32),
                  ],

                  // About & Legal Segment
                  _buildSectionLabel(
                    Tr.t('aboutLegal', langCode),
                  ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow(
                          title: Tr.t('privacyPolicy', langCode),
                          theme: theme,
                          onTap: () => context.push(Routes.privacyPolicy),
                        ),
                        _buildDivider(theme),
                        _buildSettingsRow(
                          title: Tr.t('termsOfService', langCode),
                          theme: theme,
                          onTap: () => context.push(Routes.termsOfService),
                        ),
                        _buildDivider(theme),
                        _buildSettingsRow(
                          title: Tr.t('aboutUs', langCode),
                          theme: theme,
                          onTap: () => context.push(Routes.aboutUs),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 245.ms).slideY(begin: 0.2),

                  const SizedBox(height: 32),

                  // Danger Zone
                  _buildSectionLabel(
                    Tr.t('dangerZone', langCode),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),

                  if (user?.role == 'admin') ...[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) =>
                                  const data_wipe_dialog.DataWipeDialog(),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 18.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    Tr.t('wipeAllDataBtn', langCode),
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.2),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.colorScheme.surface,
                              title: Text(
                                Tr.t('logoutProfileTitle', langCode),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                Tr.t('logoutProfileWarning', langCode),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    Tr.t('cancelBtn', langCode),
                                    style: TextStyle(color: theme.colorScheme.onSurface),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(authProvider.notifier).logout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.onSurface,
                                    foregroundColor: theme.colorScheme.surface,
                                  ),
                                  child: Text(logoutLabel),
                                ),
                              ],
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 18.0,
                          ),
                          child: Center(
                            child: Text(
                              logoutLabel,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
                      '${Tr.t('appName', langCode)} v1.0.0',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.3,
                        ),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(
                    height: 120,
                  ), // Extra space to clear the bottom navigation bar
                ],
              ),
            ),
          ),
        ],
      ), // CustomScrollView
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
      ),
    );
  }
}

// ─── Sliding Segmented Language Picker ────────────────────────────────────────
class _LanguageSegmentedPicker extends StatefulWidget {
  final String currentCode;
  final void Function(String) onChanged;
  final ThemeData theme;

  const _LanguageSegmentedPicker({
    required this.currentCode,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_LanguageSegmentedPicker> createState() =>
      _LanguageSegmentedPickerState();
}

class _LanguageSegmentedPickerState extends State<_LanguageSegmentedPicker>
    with SingleTickerProviderStateMixin {
  // Fixed order: English=0, Kurdish=1, Arabic=2
  static const _langs = [('en', 'English'), ('ku', 'کوردی'), ('ar', 'العربية')];

  late AnimationController _controller;
  late Animation<double> _slideAnim;
  int _selectedIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _indexForCode(widget.currentCode);
    _previousIndex = _selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<double>(
      begin: _selectedIndex.toDouble(),
      end: _selectedIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(_LanguageSegmentedPicker old) {
    super.didUpdateWidget(old);
    final newIndex = _indexForCode(widget.currentCode);
    if (newIndex != _selectedIndex) {
      _previousIndex = _selectedIndex;
      _selectedIndex = newIndex;
      _slideAnim =
          Tween<double>(
            begin: _previousIndex.toDouble(),
            end: _selectedIndex.toDouble(),
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _indexForCode(String code) {
    for (int i = 0; i < _langs.length; i++) {
      if (_langs[i].$1 == code) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = theme.brightness == Brightness.dark;

    // Force LTR so order is always English | Kurdish | Arabic in every locale
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          const gap = 4.0;
          final itemWidth = (totalWidth - gap * 2) / 3;

          return Container(
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            ),
            child: AnimatedBuilder(
              animation: _slideAnim,
              builder: (context, _) {
                final leftOffset = _slideAnim.value * (itemWidth + gap) + 2;
                return Stack(
                  children: [
                    // Sliding pill
                    Positioned(
                      top: 2,
                      bottom: 2,
                      left: leftOffset,
                      width: itemWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: theme.colorScheme.onSurface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.4 : 0.15,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Labels — text color transitions in sync with the pill
                    Row(
                      children: List.generate(_langs.length, (i) {
                        final (code, name) = _langs[i];
                        // How much is this slot "covered" by the pill (0→1)
                        final dist = (_slideAnim.value - i).abs().clamp(
                          0.0,
                          1.0,
                        );
                        final selected = dist < 0.5;
                        final textColor = Color.lerp(
                          theme.colorScheme.surface,
                          theme.colorScheme.onSurface.withValues(alpha: 0.45),
                          dist.clamp(0.0, 1.0),
                        )!;
                        return SizedBox(
                          width: itemWidth + (i < _langs.length - 1 ? gap : 0),
                          child: GestureDetector(
                            onTap: () => widget.onChanged(code),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
