import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/image_picker_widget.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/services/cloud_storage_service.dart';
import '../../core/utils/focus_utils.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  late final _nameFocus = SelectAllFocusNode(controller: _nameController);
  late final _emailFocus = SelectAllFocusNode(controller: _emailController);
  late final _phoneFocus = SelectAllFocusNode(controller: _phoneController);

  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _avatarPath = user?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CustomLoader()),
      ).ignore();

      String? finalImageUrl = _avatarPath;
      if (_avatarPath != null && !_avatarPath!.startsWith('http')) {
        final storage = ref.read(cloudStorageServiceProvider);
        final uploadedUrl = await storage.uploadImage(_avatarPath!, 'profiles');
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      await ref
          .read(authProvider.notifier)
          .updateProfile(
            name: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            avatarPath: finalImageUrl,
            removeAvatar: finalImageUrl == null,
          );

      if (mounted) {
        Navigator.pop(context); // dismiss loader
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = ref.read(localeProvider).languageCode == 'ku';
    final langCode = currentLocale.languageCode;
    final isArabic = currentLocale.languageCode == 'ar';

    final theme = Theme.of(context);
    final user = ref.read(authProvider).user;

    final title = Tr.t('auto_EditProfile', langCode);
    final nameLabel = Tr.t('auto_Name', langCode);
    final emailLabel = Tr.t('auto_Email', langCode);
    final phoneLabel = Tr.t('auto_PhoneNumber', langCode);
    final saveBtn = Tr.t('auto_SaveChanges', langCode);
    final reqError = Tr.t('auto_Required', langCode);

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
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.surface,
                          ),
                          child: ImagePickerWidget(
                            initialImagePath: _avatarPath,
                            isKurdish: isKurdish,
                            isArabic: isArabic,
                            radius: 56,
                            heroTag: 'avatar_${user?.id}',
                            placeholderIcon: Icons.camera_alt_rounded,
                            namePlaceholder: _nameController.text.isNotEmpty
                                ? _nameController.text
                                : user?.name,
                            onImageSelected: (path) {
                              setState(() => _avatarPath = path);
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 12,
                        bottom: 8,
                      ),
                      child: Text(
                        Tr.t('auto_PERSONALINFO', langCode),
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
                            icon: Icons.person_rounded,
                            theme: theme,
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? reqError
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 56.0,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          _buildInputField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: emailLabel,
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            theme: theme,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? reqError
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 56.0,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          _buildInputField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            label: phoneLabel,
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            theme: theme,
                            validator: (value) => null, // Phone is optional
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

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
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      onChanged: onChanged,
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
}
