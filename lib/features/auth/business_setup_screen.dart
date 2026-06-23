import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/business_setup_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/bouncing_widget.dart';

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();

  bool _isJoinMode = true;

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _inviteCodeController.dispose();
    _floatCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool joinMode) {
    if (_isJoinMode == joinMode) return;
    setState(() {
      _isJoinMode = joinMode;
      _formKey.currentState?.reset();
    });
    if (joinMode) {
      _tabCtrl.reverse();
    } else {
      _tabCtrl.forward();
    }
  }

  Future<void> _submit(String lang) async {
    final provider = ref.read(businessSetupProvider.notifier);
    if (!mounted) return;

    try {
      if (!(_formKey.currentState?.validate() ?? false)) return;

      if (_isJoinMode) {
        final code = _inviteCodeController.text.trim().toUpperCase();
        await provider.joinBusiness(code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Tr.t('business_joined_success', lang), style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }
      } else {
        final name = _businessNameController.text.trim();
        await provider.createBusiness(name);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Tr.t('business_created_success', lang), style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessSetupProvider);
    final isLoading = state.isLoading;
    final lang = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final fg = Theme.of(context).colorScheme.onSurface;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final joinTitle = Tr.t('businessSetupTitleJoin', lang);
    final createTitle = Tr.t('businessSetupTitleCreate', lang);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, __) {
                        final floatOffset = (_floatAnim.value - 0.5) * 6;
                        return Column(
                          children: [
                            Transform.translate(
                              offset: Offset(0, floatOffset),
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                ),
                                child: Icon(
                                  Icons.business_center_rounded,
                                  size: 48,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Dynamic Pedestal Shadow
                            Container(
                              width: 60 - (_floatAnim.value * 15),
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Animated Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey(_isJoinMode),
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${(_isJoinMode ? joinTitle : createTitle).split(' ').first} ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: fg,
                                    letterSpacing: -1.0,
                                    fontFamily: theme.textTheme.headlineMedium?.fontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: (_isJoinMode ? joinTitle : createTitle).split(' ').skip(1).join(' '),
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w300,
                                    color: fg,
                                    letterSpacing: -0.5,
                                    fontFamily: theme.textTheme.headlineMedium?.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Premium Solid Card
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tab bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final tabWidth = constraints.maxWidth / 2;
                                return Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Stack(
                                    children: [
                                      AnimatedPositioned(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOutCubic,
                                        top: 4,
                                        bottom: 4,
                                        left: isRTL
                                            ? (_isJoinMode ? tabWidth + 2 : 4)
                                            : (_isJoinMode ? 4 : tabWidth + 2),
                                        width: tabWidth - 6,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                                blurRadius: 5,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          _tab(
                                            label: Tr.t('joinBtn', lang),
                                            selected: _isJoinMode,
                                            fg: fg,
                                            onTap: () => _switchTab(true),
                                          ),
                                          _tab(
                                            label: Tr.t('createBtn', lang),
                                            selected: !_isJoinMode,
                                            fg: fg,
                                            onTap: () => _switchTab(false),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Form
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                              child: _isJoinMode
                                  ? _buildJoinForm(lang, isDark, fg, theme, isLoading)
                                  : _buildCreateForm(lang, isDark, fg, theme, isLoading),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required String label,
    required bool selected,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: BouncingWidget(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? fg : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinForm(String lang, bool isDark, Color fg, ThemeData theme, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Tr.t('joinWorkspaceInfo', lang),
                    style: TextStyle(fontSize: 13, color: fg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildInputField(
            controller: _inviteCodeController,
            hint: Tr.t('inviteCodeHint', lang),
            icon: Icons.vpn_key_rounded,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (v.trim().length != 6) return Tr.t('err_code_length', lang);
              return null;
            },
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
          ),
          const SizedBox(height: 24),
          _submitBtn(
            label: Tr.t('joinBtn', lang),
            isDark: isDark,
            fg: fg,
            theme: theme,
            isLoading: isLoading,
            onTap: () => _submit(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(String lang, bool isDark, Color fg, ThemeData theme, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning/Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: fg.withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Tr.t('createWorkspaceInfo', lang),
                    style: TextStyle(fontSize: 13, color: fg),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildInputField(
            controller: _businessNameController,
            hint: Tr.t('businessNameHint', lang),
            icon: Icons.store_rounded,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (v.trim().length < 3) return Tr.t('err_name_length', lang);
              return null;
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          _submitBtn(
            label: Tr.t('createBtn', lang),
            isDark: isDark,
            fg: fg,
            theme: theme,
            isLoading: isLoading,
            onTap: () => _submit(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required String? Function(String?) validator,
    required TextCapitalization textCapitalization,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      textInputAction: TextInputAction.done,
      maxLength: maxLength,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: hint,
        counterText: '',
        labelStyle: TextStyle(color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : Colors.grey.shade600),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        prefixIcon: Icon(icon, color: isDark ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5) : Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _submitBtn({
    required String label,
    required bool isDark,
    required Color fg,
    required ThemeData theme,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CustomLoader(color: Colors.white))
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
