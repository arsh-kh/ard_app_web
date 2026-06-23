import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/custom_top_bar_helper.dart';

enum LegalDocumentType { privacyPolicy, termsOfService }

class LegalSection {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const LegalSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });
}

class LegalScreen extends ConsumerWidget {
  final LegalDocumentType documentType;

  const LegalScreen({super.key, required this.documentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final isRtl = langCode == 'ku' || langCode == 'ar';

    final title = documentType == LegalDocumentType.privacyPolicy
        ? Tr.t('privacyPolicy', langCode)
        : Tr.t('termsOfService', langCode);

    final List<LegalSection> sections = _getSections(documentType, langCode);

    final String description = documentType == LegalDocumentType.privacyPolicy
        ? (langCode == 'ku'
              ? 'تکایە بە وردی ئەم سیاسەتی تایبەتمەندییە بخوێنەوە. ئەمە ڕوونی دەکاتەوە کە ئێمە چۆن مامەڵە لەگەڵ زانیارییەکانت دەکەین و چۆن دەیانپارێزین لەناو ئەم بەرنامەیەدا.'
              : langCode == 'ar'
              ? 'يرجى قراءة سياسة الخصوصية هذه بعناية. توضح هذه السياسة كيف نتعامل مع معلوماتك وكيف نحميها داخل هذا التطبيق.'
              : 'Please read this Privacy Policy carefully. It explains how we handle your information and how we protect it within this application.')
        : (langCode == 'ku'
              ? 'بەکارهێنانی تۆ بۆ ئەم بەرنامەیە بە واتای قبوڵکردنی تەواوی ئەم مەرج و ڕێنماییانە دێت. تکایە بە وردی بیانخوێنەوە بۆ تێگەیشتن لە ماف و ئەرکەکانت.'
              : langCode == 'ar'
              ? 'استخدامك لهذا التطبيق يعني قبولك الكامل لهذه الشروط والأحكام. يرجى قراءتها بعناية لفهم حقوقك ومسؤولياتك.'
              : 'Your use of this application constitutes your full acceptance of these terms and conditions. Please read them carefully to understand your rights and responsibilities.');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: isRtl,
          hasBackButton: Navigator.canPop(context),
        ),
        actions: CustomTopBarHelper.buildActions(
          context: context,
          isRtl: isRtl,
          hasBackButton: Navigator.canPop(context),
        ),
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
                    documentType == LegalDocumentType.privacyPolicy
                        ? Icons.shield_rounded
                        : Icons.gavel_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      description,
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ...sections.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: section.iconColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                section.icon,
                                color: section.iconColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                section.title,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          section.content,
                          textDirection: isRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<LegalSection> _getSections(LegalDocumentType type, String langCode) {
    if (type == LegalDocumentType.privacyPolicy) {
      if (langCode == 'ku') {
        return const [
          LegalSection(
            icon: Icons.article_rounded,
            iconColor: Colors.blue,
            title: '١. پێشەکی و ئامانجی ئەم سیاسەتە',
            content:
                'پاراستنی زانیارییەکانت کاری لەپێشینەی ئێمەیە. ئەم سیاسەتی تایبەتمەندییە بە شێوەیەکی ڕوون و ئاشکرا دیاری دەکات کە چۆن زانیارییەکانت کۆدەکرێنەوە، بەکاردەهێنرێن و دەپارێزرێن. کاتێک تۆ ئەم بەرنامەیە بەکاردەهێنیت، متمانەت بە ئێمە کردووە بە داتاکانی کارەکەت، و ئێمەش بەڵێن دەدەین کە ئەو متمانەیە بپارێزین و زانیارییەکانت لە هەر مەترسییەک بەدوور بگرین.',
          ),
          LegalSection(
            icon: Icons.dataset_rounded,
            iconColor: Colors.purple,
            title: '٢. جۆری ئەو زانیارییانەی کۆدەکرێنەوە',
            content:
                'ئەو داتایانەی کە لەناو ئەم بەرنامەیەدا تۆماریان دەکەیت بریتین لە: ناوی کڕیارەکان، ژمارەی تەلەفۆنەکانیان، بڕی قەرزەکانیان، لیست و نرخی کاڵاکانی کۆگاکەت، لەگەڵ تەواوی زانیارییەکانی پسوڵەی فرۆشتن. هەموو ئەم زانیارییانە تەنها بۆ ئەوەن کە بەرنامەکە بتوانێت ڕاپۆرتی ڕۆژانە و قازانجەکانت بۆ حیساب بکات.',
          ),
          LegalSection(
            icon: Icons.phone_android_rounded,
            iconColor: Colors.green,
            title: '٣. هەڵگرتنی داتا لەسەر ئامێرەکەت (لۆکاڵی)',
            content:
                'یەکێک لە گرنگترین خاڵەکانی ئەم بەرنامەیە ئەوەیە کە تەواوی زانیارییەکانت بە شێوەی "لۆکاڵی" تەنها لەناو بیرگەی (Memory) مۆبایلەکەی خۆتدا خەزن دەکرێن. بەرنامەکە هیچ سێرڤەرێکی دەرەکی (Cloud) بەکارناهێنێت بۆ ناردنی زانیارییەکانت. ئەمەش واتای ئەوەیە کە هیچ کەسێک—تەنانەت گەشەپێدەرانی بەرنامەکەش—ناتوانن داتاکانت ببینن.',
          ),
          LegalSection(
            icon: Icons.block_rounded,
            iconColor: Colors.red,
            title: '٤. هاوبەشینەکردنی زانیاری لەگەڵ لایەنی سێیەم',
            content:
                'ئێمە بە توندی دژی فرۆشتن یان هاوبەشیکردنی زانیاری بەکارهێنەرانین. داتاکانی تۆ بۆ هیچ کۆمپانیایەکی ڕیکلام، دەزگایەکی بازرگانی، یان هەر لایەنێکی تری سێیەم نانێردرێت. داتاکانت تەنها موڵکی خۆتن و تەنها بۆ بەڕێوەبردنی کارەکەی خۆت بەکاردێن.',
          ),
          LegalSection(
            icon: Icons.security_rounded,
            iconColor: Colors.teal,
            title: '٥. ڕێکارەکانی ئاسایش و پاراستن',
            content:
                'بەرنامەکە پشت دەبەستێت بە سیستەمی پاراستنی خودی مۆبایلەکەت بۆ خەزنکردنی داتاکان. بۆیە زۆر گرنگە کە وشەی نهێنی (پاسۆرد) یان پەنجەمۆر لەسەر مۆبایلەکەت دابنێیت بۆ ئەوەی کەسانی تر نەتوانن دەستکاری بەرنامەکە و زانیارییەکانی ناوی بکەن.',
          ),
          LegalSection(
            icon: Icons.file_download_rounded,
            iconColor: Colors.orange,
            title: '٦. مافەکانی تۆ بەسەر داتاکانتەوە',
            content:
                'تۆ خاوەنی تەواوەتی داتاکانتی. لە هەر کاتێکدا بتەوێت، دەتوانیت هەموو زانیارییەکانت لە ڕێگەی بەشی "هەناردەکردنی داتا" (Export) وەربگریتەوە بە شێوەی فایلی ئیکسڵ (Excel). هەروەها دەتوانیت لە هەر کاتێکدا بتەوێت تەواوی داتاکان بسڕیتەوە یان بەرنامەکە لەسەر مۆبایلەکەت لابدەیت.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepOrange,
            title: '٧. گۆڕانکارییەکان لەم سیاسەتەدا',
            content:
                'لەوانەیە پێویست بکات لە داهاتوودا گۆڕانکاری لەم سیاسەتی تایبەتمەندییەدا بکەین بەپێی زیادکردنی تایبەتمەندی نوێ بۆ بەرنامەکە. لە کاتی هەر گۆڕانکارییەکی گەورەدا، لەناو بەرنامەکەوە ئاگادارت دەکەینەوە بۆ ئەوەی بەردەوام بیت لە ئاگاداربوون لە مافەکانت.',
          ),
        ];
      } else if (langCode == 'ar') {
        return const [
          LegalSection(
            icon: Icons.article_rounded,
            iconColor: Colors.blue,
            title: '١. المقدمة وهدف هذه السياسة',
            content:
                'حماية بياناتك هي أولويتنا القصوى. تحدد سياسة الخصوصية هذه بوضوح وشفافية كيف يتم جمع معلوماتك، استخدامها، وحمايتها. عندما تستخدم هذا التطبيق، فإنك تضع ثقتك فينا، ونحن نلتزم بالحفاظ على هذه الثقة وإبقاء بياناتك آمنة.',
          ),
          LegalSection(
            icon: Icons.dataset_rounded,
            iconColor: Colors.purple,
            title: '٢. نوع المعلومات التي يتم جمعها',
            content:
                'البيانات التي تسجلها في هذا التطبيق تشمل: أسماء العملاء، أرقام هواتفهم، مبالغ ديونهم، قائمة المنتجات وأسعارها، بالإضافة إلى تفاصيل إيصالات البيع. كل هذه المعلومات تستخدم فقط ليتمكن التطبيق من حساب تقاريرك وأرباحك اليومية.',
          ),
          LegalSection(
            icon: Icons.phone_android_rounded,
            iconColor: Colors.green,
            title: '٣. التخزين المحلي للبيانات',
            content:
                'من أهم مميزات هذا التطبيق أن جميع معلوماتك يتم تخزينها "محلياً" فقط في ذاكرة هاتفك المحمول. لا يستخدم التطبيق أي خوادم خارجية (Cloud) لإرسال أو حفظ بياناتك، مما يعني أن لا أحد—حتى مطوري التطبيق—يمكنه الوصول إلى بياناتك.',
          ),
          LegalSection(
            icon: Icons.block_rounded,
            iconColor: Colors.red,
            title: '٤. عدم مشاركة البيانات مع أطراف ثالثة',
            content:
                'نحن نعارض بشدة بيع أو مشاركة بيانات المستخدمين. لن يتم إرسال بياناتك إلى أي شركات إعلانية، أو وكالات تجارية، أو أي أطراف ثالثة أخرى. بياناتك هي ملكك وحدك وتستخدم فقط لإدارة عملك.',
          ),
          LegalSection(
            icon: Icons.security_rounded,
            iconColor: Colors.teal,
            title: '٥. إجراءات الأمن والحماية',
            content:
                'يعتمد التطبيق على نظام الحماية الخاص بهاتفك لتخزين البيانات بأمان. لذلك، من المهم جداً أن تقوم بتعيين كلمة مرور أو بصمة إصبع على هاتفك لضمان عدم تمكن الآخرين من العبث بالتطبيق والمعلومات الموجودة فيه.',
          ),
          LegalSection(
            icon: Icons.file_download_rounded,
            iconColor: Colors.orange,
            title: '٦. حقوقك في بياناتك',
            content:
                'أنت المالك الكامل لبياناتك. في أي وقت تريده، يمكنك استخراج جميع معلوماتك من خلال قسم "تصدير البيانات" (Export) على شكل ملف إكسل (Excel). كما يمكنك حذف جميع البيانات أو إزالة التطبيق في أي وقت.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepOrange,
            title: '٧. التغييرات في هذه السياسة',
            content:
                'قد نحتاج إلى إجراء تغييرات على سياسة الخصوصية هذه في المستقبل بناءً على إضافة ميزات جديدة للتطبيق. في حالة حدوث أي تغييرات كبيرة، سنقوم بإعلامك من داخل التطبيق لتبقى على اطلاع بحقوقك.',
          ),
        ];
      } else {
        return const [
          LegalSection(
            icon: Icons.article_rounded,
            iconColor: Colors.blue,
            title: '1. Introduction & Purpose',
            content:
                'Protecting your data is our highest priority. This Privacy Policy clearly outlines how your information is collected, used, and protected. When you use this application, you trust us with your business data, and we are committed to maintaining that trust and keeping your data safe from any risks.',
          ),
          LegalSection(
            icon: Icons.dataset_rounded,
            iconColor: Colors.purple,
            title: '2. Types of Data Collected',
            content:
                'The data you enter into this application includes: customer names, phone numbers, debt amounts, your inventory products and prices, as well as full sales receipt details. All of this information is strictly used to allow the app to calculate your daily reports and profits.',
          ),
          LegalSection(
            icon: Icons.phone_android_rounded,
            iconColor: Colors.green,
            title: '3. Local Data Storage',
            content:
                'One of the most important features of this application is that all your data is stored completely "locally" in your device\'s memory. The app does not use any external cloud servers to transmit your data. This means absolutely no one—not even the app developers—can view your data.',
          ),
          LegalSection(
            icon: Icons.block_rounded,
            iconColor: Colors.red,
            title: '4. No Third-Party Sharing',
            content:
                'We are strictly against selling or sharing user data. Your data will never be sent to any advertising companies, commercial agencies, or any other third parties. Your data is your sole property and is used exclusively for managing your own business.',
          ),
          LegalSection(
            icon: Icons.security_rounded,
            iconColor: Colors.teal,
            title: '5. Security Measures',
            content:
                'The application relies on your device\'s built-in security system to safely store the data. Therefore, it is highly recommended that you secure your device with a passcode or fingerprint to prevent unauthorized access to the application and its contents.',
          ),
          LegalSection(
            icon: Icons.file_download_rounded,
            iconColor: Colors.orange,
            title: '6. Your Data Rights',
            content:
                'You have total ownership over your data. At any time, you can retrieve all your information through the "Export Data" section as an Excel-compatible file. You also have the right to permanently delete all data or uninstall the application whenever you choose.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepOrange,
            title: '7. Policy Modifications',
            content:
                'We may need to update this Privacy Policy in the future as we add new features to the application. If any major changes occur, we will notify you within the app so you remain fully aware of how your data is handled.',
          ),
        ];
      }
    } else {
      // Terms of Service
      if (langCode == 'ku') {
        return const [
          LegalSection(
            icon: Icons.handshake_rounded,
            iconColor: Colors.blue,
            title: '١. قبوڵکردنی مەرجەکان',
            content:
                'بە دابەزاندن، دامەزراندن و بەکارهێنانی ئەم بەرنامەیە، تۆ بە تەواوی ڕەزامەندی دەردەبڕیت لەسەر پابەندبوون بە هەموو ئەو مەرج و ڕێنماییانەی لێرەدا باسکراون. ئەگەر بەشێک یان هەموو ئەم مەرجانەت قبوڵ نییە، تکایە بەرنامەکە بەکارمەهێنە.',
          ),
          LegalSection(
            icon: Icons.person_rounded,
            iconColor: Colors.orange,
            title: '٢. ئەرک و بەرپرسیارێتی بەکارهێنەر',
            content:
                'تۆ وەک بەکارهێنەر، بەتەواوی بەرپرسیاریت لە دروستی و ڕاستی ئەو زانیاری و ژمارانەی کە تۆماری دەکەیت لەناو ئەپەکەدا، وەک نرخی کاڵاکان یان قەرزی کڕیارەکان. بەرنامەکە تەنها ئامرازێکە بۆ حیسابات و نابێتە هۆی دروستبوونی هیچ ئیلتیزامێکی یاسایی لەسەر گەشەپێدەرەکانی.',
          ),
          LegalSection(
            icon: Icons.save_rounded,
            iconColor: Colors.green,
            title: '٣. پاراستن و باکئەپکردنی داتا',
            content:
                'لەبەر ئەوەی ئەم بەرنامەیە ئینتەرنێت و سێرڤەر بەکارناهێنێت، داتاکانت تەنها لەسەر مۆبایلەکەتن. بۆیە لە ئەستۆی خۆتە کە ناوە ناوە داتاکانت باکئەپ (Export) بکەیت بۆ ئەوەی ئەگەر مۆبایلەکەت ون بوو یان تێکچوو، زانیارییەکانت لەدەست نەدەیت.',
          ),
          LegalSection(
            icon: Icons.warning_rounded,
            iconColor: Colors.red,
            title: '٤. سنووردارکردنی بەرپرسیارێتی',
            content:
                'تیمی گەشەپێدەری ئەم بەرنامەیە بە هیچ شێوەیەک بەرپرسیار نابێت لە هەر زیانێکی دارایی، لەدەستدانی قازانج، کێشەی نێوان تۆ و کڕیارەکانت، یان سڕینەوەی داتاکانت بەهۆی هەڵەی بەکارهێنان یان تێکچوونی ئامێرەکەتەوە.',
          ),
          LegalSection(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.teal,
            title: '٥. بەکارهێنانی دروست و ڕێگەپێدراو',
            content:
                'دەبێت ئەم بەرنامەیە تەنها بۆ مەبەستی یاسایی و بەڕێوەبردنی کاری بازرگانی ئاسایی بەکاربهێنرێت. هەوڵدان بۆ هاککردن، تێکدانی کۆدەکانی بەرنامەکە، یان فرۆشتنەوەی کۆپییەکەی بە کەسانی تر بەبێ مۆڵەت، قەدەغەیە.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepPurple,
            title: '٦. گۆڕانکاری لە مەرجەکان',
            content:
                'ئێمە مافی ئەوەمان هەیە کە لە هەر کاتێکدا گۆڕانکاری یان نوێکردنەوە لەم مەرجانەدا بکەین بەبێ ئاگادارکردنەوەی پێشوەختە. بەردەوامبوونت لە بەکارهێنانی بەرنامەکە پاش گۆڕانکارییەکان، بە واتای قبوڵکردنی ئەو گۆڕانکارییانە دێت.',
          ),
          LegalSection(
            icon: Icons.gavel_rounded,
            iconColor: Colors.brown,
            title: '٧. یاسا کارپێکراوەکان',
            content:
                'ئەم مەرج و ڕێنماییانە بەپێی یاسا کارپێکراوەکانی هەرێم و وڵات لێکدەدرێنەوە. هەر ناکۆکییەک لەسەر بەکارهێنانی ئەم بەرنامەیە دروست بێت، لە ڕێگەی لایەنە پەیوەندیدارە یاساییەکانەوە چارەسەر دەکرێت.',
          ),
        ];
      } else if (langCode == 'ar') {
        return const [
          LegalSection(
            icon: Icons.handshake_rounded,
            iconColor: Colors.blue,
            title: '١. قبول الشروط',
            content:
                'عن طريق تنزيل وتثبيت واستخدام هذا التطبيق، فإنك توافق تمامًا وتلتزم بجميع الشروط والإرشادات المذكورة هنا. إذا كنت لا توافق على جزء من هذه الشروط أو كلها، يرجى عدم استخدام التطبيق.',
          ),
          LegalSection(
            icon: Icons.person_rounded,
            iconColor: Colors.orange,
            title: '٢. التزامات ومسؤولية المستخدم',
            content:
                'بصفتك مستخدمًا، فأنت مسؤول تمامًا عن دقة المعلومات والأرقام التي تدخلها في التطبيق، مثل أسعار المنتجات أو ديون العملاء. التطبيق هو مجرد أداة حسابية ولا يفرض أي التزام قانوني على مطوريه.',
          ),
          LegalSection(
            icon: Icons.save_rounded,
            iconColor: Colors.green,
            title: '٣. حفظ البيانات والنسخ الاحتياطي',
            content:
                'نظرًا لأن هذا التطبيق لا يستخدم الإنترنت أو الخوادم السحابية، فإن بياناتك موجودة فقط على هاتفك. لذلك، من مسؤوليتك القيام بنسخ احتياطي (تصدير) لبياناتك من وقت لآخر حتى لا تفقد معلوماتك إذا ضاع هاتفك أو تعطل.',
          ),
          LegalSection(
            icon: Icons.warning_rounded,
            iconColor: Colors.red,
            title: '٤. تحديد المسؤولية',
            content:
                'لن يكون فريق تطوير هذا التطبيق مسؤولاً بأي حال من الأحوال عن أي خسارة مالية، أو فقدان للأرباح، أو نزاعات بينك وبين عملائك، أو حذف بياناتك بسبب أخطاء الاستخدام أو أعطال الجهاز.',
          ),
          LegalSection(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.teal,
            title: '٥. الاستخدام المقبول والمشروع',
            content:
                'يجب استخدام هذا التطبيق فقط لأغراض قانونية ولإدارة الأعمال التجارية العادية. يمنع منعًا باتًا محاولة اختراق التطبيق أو العبث بشيفرته أو إعادة بيعه للآخرين دون إذن.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepPurple,
            title: '٦. تعديلات الشروط',
            content:
                'نحتفظ بالحق في تعديل أو تحديث هذه الشروط في أي وقت دون إشعار مسبق. استمرارك في استخدام التطبيق بعد أي تغييرات يعني قبولك لتلك التغييرات.',
          ),
          LegalSection(
            icon: Icons.gavel_rounded,
            iconColor: Colors.brown,
            title: '٧. القوانين الحاكمة',
            content:
                'تُفسر هذه الشروط والإرشادات وفقًا للقوانين المعمول بها. سيتم حل أي نزاع ينشأ حول استخدام هذا التطبيق من خلال السلطات القانونية المختصة.',
          ),
        ];
      } else {
        return const [
          LegalSection(
            icon: Icons.handshake_rounded,
            iconColor: Colors.blue,
            title: '1. Acceptance of Terms',
            content:
                'By downloading, installing, and using this application, you fully agree to be bound by all the terms and guidelines stated herein. If you do not agree with any part of these terms, please do not use the application.',
          ),
          LegalSection(
            icon: Icons.person_rounded,
            iconColor: Colors.orange,
            title: '2. User Obligations',
            content:
                'As a user, you are entirely responsible for the accuracy of the data and numbers you enter into the app, such as product prices or customer debts. The application is strictly a calculation tool and imposes no legal liability on its developers regarding your data accuracy.',
          ),
          LegalSection(
            icon: Icons.save_rounded,
            iconColor: Colors.green,
            title: '3. Data Backup Responsibility',
            content:
                'Because this application does not use the internet or cloud servers, your data lives only on your device. Therefore, it is your sole responsibility to regularly export (backup) your data to avoid losing your business records if your device is lost or damaged.',
          ),
          LegalSection(
            icon: Icons.warning_rounded,
            iconColor: Colors.red,
            title: '4. Limitation of Liability',
            content:
                'The development team of this application shall in no event be held liable for any financial loss, loss of profits, disputes between you and your customers, or the deletion of your data resulting from user errors or device malfunctions.',
          ),
          LegalSection(
            icon: Icons.verified_user_rounded,
            iconColor: Colors.teal,
            title: '5. Acceptable Use',
            content:
                'This application must be used solely for legal purposes and standard business management. Attempting to hack, reverse-engineer the code, or resell copies of the app without explicit permission is strictly prohibited.',
          ),
          LegalSection(
            icon: Icons.update_rounded,
            iconColor: Colors.deepPurple,
            title: '6. Modifications to Terms',
            content:
                'We reserve the right to modify or update these terms at any time without prior notice. Your continued use of the application following any changes constitutes your acceptance of those changes.',
          ),
          LegalSection(
            icon: Icons.gavel_rounded,
            iconColor: Colors.brown,
            title: '7. Governing Law',
            content:
                'These terms and conditions are governed by and construed in accordance with applicable regional laws. Any disputes arising from the use of this application will be resolved through the appropriate legal authorities.',
          ),
        ];
      }
    }
  }
}
