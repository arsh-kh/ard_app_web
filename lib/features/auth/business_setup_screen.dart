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
  ConsumerState<BusinessSetupScreen> createState() =>
      _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen>
    with TickerProviderStateMixin {
  final _joinFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _recoveryEmailController =
      TextEditingController();
  final FocusNode _businessNameFocus = FocusNode();
  final FocusNode _recoveryEmailFocus = FocusNode();

  bool _isJoinMode = true;

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
    _businessNameFocus.dispose();
    _recoveryEmailFocus.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool joinMode) {
    if (_isJoinMode == joinMode) return;
    setState(() {
      _isJoinMode = joinMode;
      _joinFormKey.currentState?.reset();
      _createFormKey.currentState?.reset();
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
      final formKey = _isJoinMode ? _joinFormKey : _createFormKey;
      if (!(formKey.currentState?.validate() ?? false)) return;

      if (_isJoinMode) {
        final code = _inviteCodeController.text.trim().toUpperCase();
        await provider.joinBusiness(code);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Tr.t('business_joined_success', lang),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }
      } else {
        final name = _businessNameController.text.trim();
        final email = _recoveryEmailController.text.trim();
        await provider.createBusiness(name, recoveryEmail: email);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Tr.t('business_created_success', lang),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg == 'businessNameTaken') {
        errorMsg = Tr.t('businessNameTaken', lang);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onInverseSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRecoverDialog(String lang, bool isDark, Color fg) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            Tr.t('recoverDialogTitle', lang),
            style: TextStyle(color: fg, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Tr.t('recoverDialogBody', lang),
                style: TextStyle(
                  color: fg.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: emailCtrl,
                hint: Tr.t('recoveryEmailHint', lang),
                icon: Icons.email_outlined,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.isEmpty) return Tr.t('reqField', lang);
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                },
                textCapitalization: TextCapitalization.none,
                forceLtr: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                Tr.t('cancelBtn', lang),
                style: TextStyle(color: fg.withValues(alpha: 0.5)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: fg,
                foregroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (emailCtrl.text.trim().isNotEmpty &&
                    emailCtrl.text.contains('@')) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(Tr.t('recoverSuccess', lang)),
                      backgroundColor: isDark ? Colors.white : Colors.black,
                    ),
                  );
                }
              },
              child: Text(
                Tr.t('recoverBtn', lang),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
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
                      key: ValueKey<bool>(_isJoinMode),
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
                          _isJoinMode
                              ? Icons.group_add_rounded
                              : Icons.domain_add_rounded,
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
                      key: ValueKey(_isJoinMode),
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      '${(_isJoinMode ? joinTitle : createTitle).split(' ').first} ',
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
                                  text: (_isJoinMode ? joinTitle : createTitle)
                                      .split(' ')
                                      .skip(1)
                                      .join(' '),
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
                              key: ValueKey(_isJoinMode),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                18,
                                20,
                                20,
                              ),
                              child: _isJoinMode
                                  ? _buildJoinForm(
                                      lang,
                                      isDark,
                                      fg,
                                      theme,
                                      isLoading,
                                    )
                                  : _buildCreateForm(
                                      lang,
                                      isDark,
                                      fg,
                                      theme,
                                      isLoading,
                                    ),
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
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showRecoverDialog(lang, isDark, fg),
              child: Text(
                Tr.t('recoverPrompt', lang),
                style: TextStyle(color: fg, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
