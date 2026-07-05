import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/error_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';


import '../../core/providers/locale_provider.dart';
import '../../core/providers/business_provider.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/utils/focus_utils.dart';
import '../../data/repositories/business_repository.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late final _nameFocus = SelectAllFocusNode(controller: _nameController);

  late TextEditingController _recoveryEmailController;
  late final _recoveryEmailFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final business = ref.read(currentBusinessEntityProvider).valueOrNull;
    _nameController = TextEditingController(text: business?.name ?? '');
    _recoveryEmailController = TextEditingController(text: business?.recoveryEmail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _recoveryEmailController.dispose();
    _recoveryEmailFocus.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final business = ref.read(currentBusinessEntityProvider).valueOrNull;
      if (business == null) return;
      
      final newName = _nameController.text.trim();
      final newRecoveryEmail = _recoveryEmailController.text.trim();
      
      if (newName == business.name && newRecoveryEmail == (business.recoveryEmail ?? '')) {
        context.pop();
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CustomLoader()),
      ).ignore();

      try {
        await ref
            .read(businessRepositoryProvider)
            .updateBusinessProfile(business.id, newName, newRecoveryEmail);
        
        if (mounted) {
          Navigator.pop(context); // dismiss loader
          context.pop(); // pop screen
          AppFeedback.showSuccess(context, Tr.t('businessNameUpdated', ref.read(localeProvider).languageCode));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // dismiss loader
          AppFeedback.showError(context, e);
        }
      }
    }
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ChangeBusinessPasswordSheet(
          businessId: ref.read(currentBusinessEntityProvider).valueOrNull?.id ?? '',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;
    final theme = Theme.of(context);

    final title = Tr.t('businessProfileTitle', langCode);
    final nameLabel = Tr.t('businessNameHintDialog', langCode);
    final recoveryEmailLabel = Tr.t('recoveryEmailLabel', langCode);
    final inviteCodeLabel = Tr.t('inviteCodeLabel', langCode);
    final saveBtn = Tr.t('auto_SaveChanges', langCode);
    final reqError = Tr.t('businessNameEmpty', langCode);
    final sectionTitle = Tr.t('businessDetails', langCode);
    
    final business = ref.watch(currentBusinessEntityProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 60,
                bottom: 16,
                end: 60,
              ),
              title: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Placeholder for future Business Logo/Avatar
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                            width: 3,
                          ),
                        ),
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.store_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 50.ms).scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 48),

                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        bottom: 8,
                      ),
                      child: Text(
                        sectionTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildInputField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            label: nameLabel,
                            icon: Icons.store_rounded,
                            theme: theme,
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? reqError
                                : null,
                            textInputAction: TextInputAction.next,
                          ),
                          _buildDivider(theme),
                          _buildInputField(
                            controller: _recoveryEmailController,
                            focusNode: _recoveryEmailFocus,
                            label: recoveryEmailLabel,
                            icon: Icons.email_outlined,
                            theme: theme,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => setState(() {}),
                            validator: (value) => null,
                            textInputAction: TextInputAction.done,
                          ),
                          if (business != null && business.inviteCode.isNotEmpty) ...[
                            _buildDivider(theme),
                            _buildReadOnlyField(
                              label: inviteCodeLabel,
                              value: business.inviteCode,
                              icon: Icons.vpn_key_outlined,
                              theme: theme,
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        onTap: _showChangePasswordDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                Tr.t('changeBusinessPasswordBtn', langCode),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        saveBtn,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ThemeData theme,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
    TextInputAction textInputAction = TextInputAction.next,
    FocusNode? nextFocusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
    );
  }
}

class _ChangeBusinessPasswordSheet extends ConsumerStatefulWidget {
  final String businessId;
  const _ChangeBusinessPasswordSheet({required this.businessId});

  @override
  ConsumerState<_ChangeBusinessPasswordSheet> createState() => _ChangeBusinessPasswordSheetState();
}

class _ChangeBusinessPasswordSheetState extends ConsumerState<_ChangeBusinessPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final oldPass = _oldPassController.text;
    final newPass = _newPassController.text;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(businessRepositoryProvider).updateBusinessPassword(widget.businessId, oldPass, newPass);
      if (mounted) {
        Navigator.pop(context);
        AppFeedback.showSuccess(context, Tr.t('passwordChangedSuccess', ref.read(localeProvider).languageCode));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ErrorUtils.translate(e, ref.read(localeProvider).languageCode);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final insets = MediaQuery.viewInsetsOf(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: insets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Tr.t('changeBusinessPasswordBtn', langCode),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
            TextFormField(
              controller: _oldPassController,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              obscureText: _obscureOld,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return Tr.t('reqField', langCode);
                return null;
              },
              decoration: InputDecoration(
                labelText: Tr.t('currentPassword', langCode),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureOld = !_obscureOld),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newPassController,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              obscureText: _obscureNew,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return Tr.t('reqField', langCode);
                if (v.length < 6) return Tr.t('err_password_length', langCode);
                return null;
              },
              decoration: InputDecoration(
                labelText: Tr.t('businessPasswordHint', langCode),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPassController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return Tr.t('reqField', langCode);
                if (v != _newPassController.text) return Tr.t('err_password_mismatch', langCode);
                return null;
              },
              decoration: InputDecoration(
                labelText: Tr.t('confirmPasswordHint', langCode),
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.onSurface,
                foregroundColor: theme.colorScheme.surface,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      Tr.t('auto_SaveChanges', langCode),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
