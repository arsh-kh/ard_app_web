import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';

class ContactUsScreen extends ConsumerWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final isRtl = langCode == 'ku' || langCode == 'ar';

    final Map<String, String> descMap = {
      'en':
          'We are always here to help. Whether you have a question about the app, need technical support, or want to provide feedback, feel free to reach out to our team using any of the methods below.',
      'ku':
          'ئێمە بەردەوام لێرەین بۆ یارمەتیدانت. ئەگەر هەر پرسیارێکت دەربارەی بەرنامەکە هەیە، پێویستت بە هاوکارییە، یان دەتەوێت سەرنجەکانت بگەیەنیت، تکایە پەیوەندیمان پێوە بکە لە ڕێگەی هەڵبژاردنەکانی خوارەوە.',
      'ar':
          'نحن دائماً هنا للمساعدة. سواء كان لديك سؤال حول التطبيق، أو تحتاج إلى دعم فني، أو ترغب في تقديم ملاحظات، فلا تتردد في التواصل مع فريقنا باستخدام أي من الطرق أدناه.',
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          Tr.t('contactSupportTitle', langCode),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      descMap[langCode] ?? descMap['en']!,
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              Tr.t('contactUs', langCode),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactCard(
              theme: theme,
              icon: Icons.call_rounded,
              iconColor: Colors.blue,
              title: Tr.t('callUs', langCode),
              subtitle: '0770 645 5868',
              isRtl: isRtl,
              onTap: () => launchUrl(Uri.parse('tel:+9647706455868')),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              theme: theme,
              icon: Icons.message_rounded,
              iconColor: Colors.green,
              title: 'WhatsApp',
              subtitle: '0770 645 5868',
              isRtl: isRtl,
              onTap: () => launchUrl(Uri.parse('https://wa.me/9647706455868')),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              theme: theme,
              icon: Icons.email_rounded,
              iconColor: Colors.redAccent,
              title: 'Email',
              subtitle: 'yarasdywanh@gmail.com',
              isRtl: isRtl,
              onTap: () => launchUrl(Uri.parse('mailto:yarasdywanh@gmail.com')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isRtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
