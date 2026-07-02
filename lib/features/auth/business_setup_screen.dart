import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/business_setup_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/bouncing_widget.dart';
import '../../core/utils/feedback_utils.dart';

enum SetupMode { join, create, recover, reset }

class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen>
    with TickerProviderStateMixin {
  final _joinFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();
  final _recoverFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _recoveryEmailController =
      TextEditingController();
  final TextEditingController _businessPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _recoveryEmailFocus = FocusNode();
  final FocusNode _businessPasswordFocus = FocusNode();

  SetupMode _mode = SetupMode.join;
  bool get _isJoinMode => _mode == SetupMode.join;

  late AnimationController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _inviteCodeController.dispose();
    _recoveryEmailController.dispose();
    _businessPasswordController.dispose();
    _newPasswordController.dispose();
    _businessNameFocus.dispose();
    _recoveryEmailFocus.dispose();
    _businessPasswordFocus.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool joinMode) {
    final newMode = joinMode ? SetupMode.join : SetupMode.create;
    if (_mode == newMode) return;
    setState(() {
      _mode = newMode;
      _joinFormKey.currentState?.reset();
      _createFormKey.currentState?.reset();
      _recoverFormKey.currentState?.reset();
      _resetFormKey.currentState?.reset();
    });
    if (joinMode) {
      _tabCtrl.reverse();
    } else {
      _tabCtrl.forward();
    }
  }

  void _switchMode(SetupMode mode) {
    setState(() {
      _mode = mode;
      _joinFormKey.currentState?.reset();
      _createFormKey.currentState?.reset();
      _recoverFormKey.currentState?.reset();
      _resetFormKey.currentState?.reset();
    });
  }

  Future<void> _submit(String lang) async {
    final provider = ref.read(businessSetupProvider.notifier);
    if (!mounted) return;

    try {
      final GlobalKey<FormState> formKey;
      switch (_mode) {
        case SetupMode.join: formKey = _joinFormKey; break;
        case SetupMode.create: formKey = _createFormKey; break;
        case SetupMode.recover: formKey = _recoverFormKey; break;
        case SetupMode.reset: formKey = _resetFormKey; break;
      }
      
      if (!(formKey.currentState?.validate() ?? false)) return;

      if (_mode == SetupMode.join) {
        final code = _inviteCodeController.text.trim().toUpperCase();
        await provider.joinBusiness(code);
        if (mounted) {
          _showSuccess(Tr.t('business_joined_success', lang));
        }
      } else if (_mode == SetupMode.create) {
        final name = _businessNameController.text.trim();
        final email = _recoveryEmailController.text.trim();
        final password = _businessPasswordController.text;
        await provider.createBusiness(name, recoveryEmail: email, password: password);
        if (mounted) {
          _showSuccess(Tr.t('business_created_success', lang));
        }
      } else if (_mode == SetupMode.recover) {
        final email = _recoveryEmailController.text.trim();
        final password = _businessPasswordController.text;
        await provider.restoreBusiness(email, password);
        if (mounted) {
          _showSuccess(Tr.t('businessRestoredSuccess', lang));
        }
      } else if (_mode == SetupMode.reset) {
        final email = _recoveryEmailController.text.trim();
        await provider.resetBusinessPassword(email);
        if (mounted) {
          _showSuccess(Tr.t('businessPasswordResetSuccess', lang));
          // Go back to recover mode after successful reset
          _switchMode(SetupMode.recover);
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e);
    }
  }

  void _showSuccess(String message) {
    AppFeedback.showSuccess(context, message);
  }

  IconData _getIconForMode() {
    switch (_mode) {
      case SetupMode.join: return Icons.group_add_rounded;
      case SetupMode.create: return Icons.domain_add_rounded;
      case SetupMode.recover: return Icons.admin_panel_settings_rounded;
      case SetupMode.reset: return Icons.lock_reset_rounded;
    }
  }

  String _getTitleForMode(String lang) {
    switch (_mode) {
      case SetupMode.join: return Tr.t('businessSetupTitleJoin', lang);
      case SetupMode.create: return Tr.t('businessSetupTitleCreate', lang);
      case SetupMode.recover: return Tr.t('adminLoginTitle', lang);
      case SetupMode.reset: return Tr.t('forgotBusinessPassword', lang);
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

    final currentTitle = _getTitleForMode(lang);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                  // Icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInBack,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: RotationTransition(
                            turns: Tween<double>(
                              begin: 0.8,
                              end: 1.0,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey<SetupMode>(_mode),
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                      ),
                      child: Center(
                        child: Icon(
                          _getIconForMode(),
                          size: 52,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Animated Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(_mode),
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${currentTitle.split(' ').first} ',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: fg,
                                    letterSpacing: -1.2,
                                    fontFamily: theme
                                        .textTheme
                                        .headlineMedium
                                        ?.fontFamily,
                                  ),
                                ),
                                TextSpan(
                                  text: currentTitle.split(' ').skip(1).join(' '),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w300,
                                    color: fg,
                                    letterSpacing: -0.5,
                                    fontFamily: theme
                                        .textTheme
                                        .headlineMedium
                                        ?.fontFamily,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Premium Solid Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151515) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 40,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        if (_mode == SetupMode.join || _mode == SetupMode.create)
                          Padding(
                          padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final tabWidth = constraints.maxWidth / 2;
                              return Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      top: 4,
                                      bottom: 4,
                                      left: isRTL
                                          ? (_isJoinMode ? tabWidth + 2 : 4)
                                          : (_isJoinMode ? 4 : tabWidth + 2),
                                      width: tabWidth - 6,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.15,
                                                )
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.08,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.black.withValues(
                                                    alpha: 0.05,
                                                  ),
                                            width: 0.5,
                                          ),
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
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            layoutBuilder: (currentChild, previousChildren) {
                              return Stack(
                                alignment: Alignment.topCenter,
                                children: <Widget>[
                                  ...previousChildren,
                                  if (currentChild != null) currentChild,
                                ],
                              );
                            },
                            child: Padding(
                              key: ValueKey(_mode),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                20,
                              ),
                              child: _mode == SetupMode.join
                                  ? _buildJoinForm(lang, isDark, fg, theme, isLoading)
                                  : _mode == SetupMode.create
                                      ? _buildCreateForm(lang, isDark, fg, theme, isLoading)
                                      : _mode == SetupMode.recover
                                          ? _buildRecoverForm(lang, isDark, fg, theme, isLoading)
                                          : _buildResetForm(lang, isDark, fg, theme, isLoading),
                            ),
                          ),
                        ),

                      ],
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
              color: selected
                  ? fg
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinForm(
    String lang,
    bool isDark,
    Color fg,
    ThemeData theme,
    bool isLoading,
  ) {
    return Form(
      key: _joinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Tr.t('joinWorkspaceInfo', lang),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
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
            forceLtr: true,
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _switchMode(SetupMode.recover),
            child: Text(
              Tr.t('adminLoginBtn', lang),
              style: TextStyle(color: fg.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm(
    String lang,
    bool isDark,
    Color fg,
    ThemeData theme,
    bool isLoading,
  ) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Warning/Info Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Tr.t('createWorkspaceInfo', lang),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildInputField(
            controller: _businessNameController,
            focusNode: _businessNameFocus,
            nextFocusNode: _recoveryEmailFocus,
            hint: Tr.t('businessNameHint', lang),
            icon: Icons.store_rounded,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (v.trim().length < 3) return Tr.t('err_name_length', lang);
              return null;
            },
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            forceLtr: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _recoveryEmailController,
            focusNode: _recoveryEmailFocus,
            nextFocusNode: _businessPasswordFocus,
            hint: Tr.t('recoveryEmailHint', lang),
            icon: Icons.email_outlined,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (!v.contains('@')) return Tr.t('invalidEmail', lang);
              return null;
            },
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            forceLtr: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _businessPasswordController,
            focusNode: _businessPasswordFocus,
            hint: Tr.t('businessPasswordHint', lang),
            icon: Icons.lock_outline,
            isDark: isDark,
            isPassword: true,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (v.length < 6) return Tr.t('err_password_length', lang);
              return null;
            },
            textInputAction: TextInputAction.done,
            forceLtr: true,
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
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _switchMode(SetupMode.recover),
            child: Text(
              Tr.t('adminLoginBtn', lang),
              style: TextStyle(color: fg.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverForm(
    String lang,
    bool isDark,
    Color fg,
    ThemeData theme,
    bool isLoading,
  ) {
    return Form(
      key: _recoverFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              Tr.t('adminLoginInfo', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _recoveryEmailController,
            focusNode: _recoveryEmailFocus,
            nextFocusNode: _businessPasswordFocus,
            hint: Tr.t('recoveryEmailHint', lang),
            icon: Icons.email_outlined,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (!v.contains('@')) return Tr.t('invalidEmail', lang);
              return null;
            },
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            forceLtr: true,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _businessPasswordController,
            focusNode: _businessPasswordFocus,
            hint: Tr.t('businessPasswordHint', lang),
            icon: Icons.lock_outline,
            isDark: isDark,
            isPassword: true,
            textCapitalization: TextCapitalization.none,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              return null;
            },
            textInputAction: TextInputAction.done,
            forceLtr: true,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _switchMode(SetupMode.reset),
              child: Text(
                Tr.t('forgotBusinessPassword', lang),
                style: TextStyle(color: fg, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _submitBtn(
            label: Tr.t('adminLoginBtn', lang),
            isDark: isDark,
            fg: fg,
            theme: theme,
            isLoading: isLoading,
            onTap: () => _submit(lang),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _switchMode(SetupMode.join),
            child: Text(
              Tr.t('backToSetupBtn', lang),
              style: TextStyle(color: fg.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm(
    String lang,
    bool isDark,
    Color fg,
    ThemeData theme,
    bool isLoading,
  ) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              Tr.t('resetPasswordInfo', lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _recoveryEmailController,
            hint: Tr.t('recoveryEmailHint', lang),
            icon: Icons.email_outlined,
            isDark: isDark,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return Tr.t('reqField', lang);
              if (!v.contains('@')) return Tr.t('invalidEmail', lang);
              return null;
            },
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            forceLtr: true,
          ),
          const SizedBox(height: 24),
          _submitBtn(
            label: Tr.t('resetBtn', lang),
            isDark: isDark,
            fg: fg,
            theme: theme,
            isLoading: isLoading,
            onTap: () => _submit(lang),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _switchMode(SetupMode.recover),
            child: Text(
              Tr.t('cancelBtn', lang),
              style: TextStyle(color: fg.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    Key? key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    required String? Function(String?) validator,
    required TextCapitalization textCapitalization,
    TextInputAction textInputAction = TextInputAction.next,
    int? maxLength,
    bool forceLtr = false,
    bool isPassword = false,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
  }) {
    final fg = isDark ? Colors.white : Colors.black;
    final Widget field = TextFormField(
      key: key,
      controller: controller,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      obscureText: isPassword,
      onFieldSubmitted: (_) {
        if (textInputAction == TextInputAction.next) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          } else {
            FocusScope.of(context).nextFocus();
          }
        } else if (textInputAction == TextInputAction.done) {
          FocusScope.of(context).unfocus();
        }
      },
      maxLength: maxLength,
      style: TextStyle(fontSize: 16, color: fg, fontWeight: FontWeight.w600),
      cursorColor: fg,
      decoration: InputDecoration(
        labelText: hint,
        counterText: '',
        labelStyle: TextStyle(
          color: fg.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        prefixIcon: Icon(icon, color: fg.withValues(alpha: 0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: fg, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        errorMaxLines: 2,
      ),
      validator: validator,
    );

    if (forceLtr) {
      return Directionality(textDirection: TextDirection.ltr, child: field);
    }

    return field;
  }

  Widget _submitBtn({
    required String label,
    required bool isDark,
    required Color fg,
    required ThemeData theme,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final bgColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.black : Colors.white;

    return BouncingWidget(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CustomLoader(color: textColor),
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
