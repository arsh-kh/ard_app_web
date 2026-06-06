import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)] 
              : [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 24,
                        spreadRadius: -4,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Icon
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 64,
                          color: isDark ? Colors.white : Colors.black87,
                        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                         .rotate(duration: 2.seconds, begin: -0.1, end: 0.1)
                         .scale(duration: 1.seconds, begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
                      ),
                      const SizedBox(height: 32),
                      
                      // Title
                      Text(
                        lang == 'ku' ? 'Ú†Ø§ÙˆÛ•Ú•ÛŽÛŒ Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø¯Ù†' : lang == 'ar' ? 'ÙÙŠ Ø§Ù†ØªØ¸Ø§Ø± Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø©' : 'Pending Approval',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        lang == 'ku' 
                          ? 'Ù‡Û•Ú˜Ù…Ø§Ø±Û•Ú©Û•Øª Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆØ§Ù†Û• Ø¯Ø±ÙˆØ³ØªÚ©Ø±Ø§. ØªÚ©Ø§ÛŒÛ• Ú†Ø§ÙˆÛ•Ú•ÛŽ Ø¨Ú©Û• ØªØ§ Ø¨Û•Ú•ÛŽÙˆÛ•Ø¨Û•Ø±ÛŽÚ© Ù¾Û•Ø³Û•Ù†Ø¯ÛŒ Ø¯Û•Ú©Ø§Øª Ø¨Û† Ø¦Û•ÙˆÛ•ÛŒ Ø¨ØªÙˆØ§Ù†ÛŒØª Ø¨Ú†ÛŒØªÛ• Ú˜ÙˆÙˆØ±Û•ÙˆÛ•.' 
                          : lang == 'ar' 
                            ? 'ØªÙ… Ø¥Ù†Ø´Ø§Ø¡ Ø­Ø³Ø§Ø¨Ùƒ Ø¨Ù†Ø¬Ø§Ø­. ÙŠØ±Ø¬Ù‰ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø± Ø­ØªÙ‰ ÙŠÙˆØ§ÙÙ‚ Ø§Ù„Ù…Ø³Ø¤ÙˆÙ„ Ù„ØªØªÙ…ÙƒÙ† Ù…Ù† ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„.' 
                            : 'Your account has been created successfully. Please wait for an administrator to approve your access before you can log in.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 48),
                      
                      // Refresh Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : () {
                            ref.read(authProvider.notifier).refreshSession();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: authState.isLoading
                            ? SizedBox(width: 24, height: 24, child: CustomLoader())
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.refresh_rounded),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang == 'ku' ? 'Ù†ÙˆÛŽÚ©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¯Û†Ø®' : lang == 'ar' ? 'ØªØ­Ø¯ÙŠØ« Ø§Ù„Ø­Ø§Ù„Ø©' : 'Refresh Status',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 16),
                      
                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            lang == 'ku' ? 'Ú†ÙˆÙˆÙ†Û• Ø¯Û•Ø±Û•ÙˆÛ•' : lang == 'ar' ? 'ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø®Ø±ÙˆØ¬' : 'Log Out',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

