import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';

class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;

    final isRtl = langCode == 'ku' || langCode == 'ar';

    final aboutUsTitle = Tr.t('aboutUs', langCode);

    final String appDesc = langCode == 'ku'
        ? 'سڵاو، من ئارش خەسرەوم.\n\nبەرنامەی ئاردم دروستکرد چونکە بینیم چەندە قورسە بۆ خاوەن دوکانەکان بەڕێوەبردنی فرۆشتنی ڕۆژانە، تۆمارکردنی قەرزەکان، و زانینی ئەوەی چی لە کۆگادا ماوە—بە تایبەت بە بەکارهێنانی قەڵەم و کاغەز یان سیستەمی ئاڵۆز.\n\nویستم شتێکی سادە، خێرا و سەلامەت دروست بکەم. بۆیە ئاردم دروستکرد تا هەموو ئەرکە قورسەکانت بە شێوەیەکی ئۆتۆماتیکی بۆ ڕاپەڕێنێت، تەنانەت ئەگەر هێڵی ئینتەرنێتیشت نەبێت. ئامانجی من ئەوەیە هەموو هەفتەیەک چەندین کاتژمێر لە ماندووبوونت بۆ بگەڕێنمەوە، تا بتوانیت سەرنج بخەیتە سەر گەشەپێدانی کارەکەت لەبری ئەوەی خەریکی ژمێریاری بیت.'
        : langCode == 'ar'
        ? 'مرحباً، أنا آرش خسرو!\n\nلقد قمت ببناء تطبيق آرد لأنني رأيت مدى صعوبة إدارة المبيعات اليومية، تتبع الديون، ومعرفة المتبقي في المخزن لأصحاب المتاجر المحلية—خاصة عند استخدام الورقة والقلم أو الأنظمة المعقدة.\n\nأردت صنع شيء بسيط، سريع، وآمن. لهذا السبب طورت آرد ليقوم بكل العمل الشاق نيابة عنك بشكل تلقائي، حتى لو لم يكن لديك اتصال بالإنترنت. هدفي هو أن أوفر عليك ساعات من التعب كل أسبوع، لتتمكن من التركيز على تنمية عملك بدلاً من القيام بالحسابات.'
        : 'Hi, I\'m Arsh Khasraw!\n\nI built Ard App because I saw how tough it can be for local shop owners to manage daily sales, keep track of debts, and figure out what\'s left in the store—all using pen and paper or clunky systems.\n\nI wanted to make something simple, fast, and secure. That\'s why I created Ard to do all the heavy lifting for you automatically, even if you don\'t have an internet connection. My goal is to save you hours of headaches every week, so you can focus on growing your business instead of doing math.';

    final String featureTitle = langCode == 'ku'
        ? 'بۆچی ئێمە هەڵبژێریت؟'
        : langCode == 'ar'
        ? 'لماذا تختارنا؟'
        : 'Why choose us?';

    final String devTitle = langCode == 'ku'
        ? 'گەشەپێدەر'
        : langCode == 'ar'
        ? 'المطور'
        : 'Developer';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          aboutUsTitle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero App Icon Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/APPLogo.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Tr.t('appName', langCode),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                appDesc,
                textAlign: TextAlign.justify,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Title
            Text(
              featureTitle,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Features List
            _buildFeatureCard(
              context,
              icon: Icons.speed_rounded,
              color: Theme.of(context).colorScheme.primary,
              title: langCode == 'ku'
                  ? 'خێرا و ئاسان'
                  : langCode == 'ar'
                  ? 'سريع وسهل'
                  : 'Fast & Easy',
              isRtl: isRtl,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.security_rounded,
              color: Theme.of(context).colorScheme.primary,
              title: langCode == 'ku'
                  ? 'سەلامەت و پارێزراو'
                  : langCode == 'ar'
                  ? 'آمن ومحمي'
                  : 'Safe & Secure',
              isRtl: isRtl,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context,
              icon: Icons.wifi_off_rounded,
              color: Theme.of(context).colorScheme.primary,
              title: langCode == 'ku'
                  ? 'کارکردن بەبێ ئینتەرنێت'
                  : langCode == 'ar'
                  ? 'يعمل بدون إنترنت'
                  : 'Works Offline',
              isRtl: isRtl,
            ),
            const SizedBox(height: 32),

            // Developer Info Title
            Text(
              devTitle,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Developer Details
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.person_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Arsh Khasraw',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    langCode == 'ku'
                        ? 'گەشەپێدەری بەرنامە و دیزاینەر'
                        : langCode == 'ar'
                        ? 'مطور التطبيق والمصمم'
                        : 'Lead Developer & Designer',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildContactItem(
                    context,
                    icon: Icons.phone_rounded,
                    title: '+964 770 645 5868',
                    onTap: () => _launchUrl('tel:07706455868'),
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    context,
                    icon: Icons.email_rounded,
                    title: 'yarasdywanh@gmail.com',
                    onTap: () => _launchUrl('mailto:yarasdywanh@gmail.com'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required bool isRtl,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
