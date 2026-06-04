import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/image_picker_widget.dart';

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
  late TextEditingController _roleController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _roleController = TextEditingController(text: user?.role ?? '');
    _avatarPath = user?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ref.read(authProvider.notifier).updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        role: _roleController.text,
        avatarPath: _avatarPath,
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final theme = Theme.of(context);
    final user = ref.read(authProvider).user;

    final title = isKurdish ? 'گۆڕینی پڕۆفایل' : isArabic ? 'تعديل الملف الشخصي' : 'Edit Profile';
    final nameLabel = isKurdish ? 'ناو' : isArabic ? 'الاسم' : 'Name';
    final emailLabel = isKurdish ? 'ئیمەیڵ' : isArabic ? 'البريد الإلكتروني' : 'Email';
    final phoneLabel = isKurdish ? 'ژمارەی مۆبایل' : isArabic ? 'رقم الهاتف' : 'Phone Number';
    final roleLabel = isKurdish ? 'ڕۆڵ' : isArabic ? 'الدور' : 'Role';
    final saveBtn = isKurdish ? 'پاشەکەوتکردن' : isArabic ? 'حفظ' : 'Save Changes';
    final reqError = isKurdish ? 'پێویستە' : isArabic ? 'مطلوب' : 'Required';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.8),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 60),
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
            ),
          ),
          
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Hero(
                        tag: 'avatar_${user?.id}',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5), width: 3),
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
                              placeholderIcon: Icons.camera_alt_rounded,
                              onImageSelected: (path) {
                                setState(() => _avatarPath = path);
                              },
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                    
                    const SizedBox(height: 48),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'PERSONAL INFO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                            label: nameLabel,
                            icon: Icons.person_rounded,
                            theme: theme,
                            validator: (value) => value == null || value.trim().isEmpty ? reqError : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56.0),
                            child: Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          _buildInputField(
                            controller: _emailController,
                            label: emailLabel,
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            theme: theme,
                            validator: (value) => value == null || value.trim().isEmpty ? reqError : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56.0),
                            child: Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          _buildInputField(
                            controller: _phoneController,
                            label: phoneLabel,
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                            theme: theme,
                            validator: (value) => value == null || value.trim().isEmpty ? reqError : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 56.0),
                            child: Divider(height: 1, thickness: 0.5, color: theme.colorScheme.onSurface.withOpacity(0.1)),
                          ),
                          _buildInputField(
                            controller: _roleController,
                            label: roleLabel,
                            icon: Icons.badge_rounded,
                            theme: theme,
                            validator: (value) => value == null || value.trim().isEmpty ? reqError : null,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 40),
                    
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required ThemeData theme,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      validator: validator,
    );
  }
}
