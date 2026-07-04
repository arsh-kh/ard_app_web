import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/custom_top_bar_helper.dart';

class FaqCategory {
  final String categoryName;
  final List<FaqItem> items;

  const FaqCategory(this.categoryName, this.items);
}

class FaqItem {
  final String question;
  final String answer;

  const FaqItem(this.question, this.answer);
}

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final isRtl = langCode == 'ku' || langCode == 'ar';

    final categories = _getFaqCategories(langCode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        title: Text(
          Tr.t('helpCenter', langCode),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                  child: Text(
                    category.categoryName.toUpperCase(),
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: Column(
                      children: category.items.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              childrenPadding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                              ),
                              iconColor: theme.colorScheme.onSurface.withValues(
                                alpha: 0.4,
                              ),
                              collapsedIconColor: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.4),
                              title: Text(
                                item.question,
                                textDirection: isRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              children: [
                                Align(
                                  alignment: isRtl
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Text(
                                    item.answer,
                                    textDirection: isRtl
                                        ? TextDirection.rtl
                                        : TextDirection.ltr,
                                    style: TextStyle(
                                      height: 1.6,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (i < category.items.length - 1)
                              Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FaqCategory> _getFaqCategories(String langCode) {
    if (langCode == 'ku') {
      return const [
        FaqCategory('فرۆشتن و پسوڵەکان', [
          FaqItem(
            'چۆن فرۆشتنێکی نوێ تۆمار بکەم؟',
            '١. بڕۆ بۆ بەشی "فرۆشتن" (ئایکۆنی خوارەوە).\n٢. ئەو کاڵایانە هەڵبژێرە کە کڕیارەکە دەیەوێت.\n٣. کرتە بکە سەر دوگمەی "پارەدان".\n٤. دیاری بکە ئایا پارەکە کاشە یان قەرزە، پاشان پسوڵەکە خەزن بکە.',
          ),
          FaqItem(
            'چۆن نرخێکی جیاواز بە کڕیار بدەم؟',
            'لە کاتی پارەداندا، لە بەشی چەپی هەر بەرهەمێکدا دوگمەی دەستکاریکردنی نرخی تاکی هەر بەرهەمێک هەیە، کە دەتوانی ئەو نرخە کەم یان زیاد بکەیت.',
          ),
          FaqItem(
            'چۆن کاڵایەکی فرۆشراو وەربگرمەوە (گەڕاندنەوە)؟',
            '١. بڕۆ بۆ بەشی "داواکارییەکان" (پسوڵەکان).\n٢. پسوڵەی مەبەست بکەرەوە.\n٣. کرتە بکە سەر "گەڕاندنەوە" (Return).\n٤. دیاری بکە چەند دانە لە کاڵاکە گەڕاوەتەوە بۆ ناو کۆگا، بەمەش پارەکە و ژمارەی کاڵاکە لە کۆگا ڕاست دەکرێتەوە.',
          ),
          FaqItem(
            'چۆن پسوڵە کۆنەکان ببینمەوە؟',
            'لە بەشی "داواکارییەکان"، هەموو پسوڵەکان بەپێی کات ڕیزکراون. دەتوانیت بەپێی ناوی کڕیار یان بەروار بگەڕێیت.',
          ),
        ]),
        FaqCategory('کڕیارەکان و قەرزەکان', [
          FaqItem(
            'چۆن کڕیارێکی نوێ زیاد بکەم؟',
            '١. بڕۆ بۆ بەشی "کڕیارەکان".\n٢. نیشانەی (+) دابگرە.\n٣. ناو و ژمارەی مۆبایلەکەی بنووسە. ئێستا دەتوانیت قەرزی بدەیتێ.',
          ),
          FaqItem(
            'چۆن قەرزی کڕیارەکانم وەربگرمەوە؟',
            '١. بڕۆ بۆ سەر ناوی کڕیارەکە لە بەشی کڕیارەکان.\n٢. کرتە بکە سەر "وەرگرتنی پارە".\n٣. ئەو بڕە پارەیە بنووسە کە کڕیارەکە هێناویەتی و خەزنی بکە. قەرزەکەی خۆکارانە کەم دەبێتەوە.',
          ),
          FaqItem(
            'چۆن بزانم کڕیارێک چەندی لایە؟',
            'لە بەشی "کڕیارەکان"، لە پاڵ ناوی هەر کڕیارێکدا کۆی قەرزەکانی نووسراوە. ئەگەر بە ڕەنگی سوور بوو، واتە قەرزدارە.',
          ),
          FaqItem(
            'مێژووی مامەڵەکانی کڕیار چۆن دەبینرێت؟',
            'بە کرتەکردن لەسەر ناوی هەر کڕیارێک، دەتوانیت تەواوی مێژووی کڕینەکان، قەرزەکان، و پارەدانەکانی پێشووی ببینیت.',
          ),
        ]),
        FaqCategory('کۆگا و کاڵاکان', [
          FaqItem(
            'چۆن کاڵایەکی نوێ زیاد بکەم؟',
            '١. بڕۆ بۆ بەشی "کۆگا".\n٢. نیشانەی (+) دابگرە.\n٣. ناو، نرخی کڕین و نرخی فرۆشتن بنووسە.\n٤. ژمارەی کاڵاکان لە کۆگا بنووسە و دەتوانیت ناوی دابینکەرەکەش (شەریکە) بنووسیت و خەزنی بکەیت.',
          ),
          FaqItem(
            'چۆن نرخی کاڵایەک بگۆڕم؟',
            'لە بەشی کۆگا، کرتە لەسەر کاڵاکە بکە و پاشان نیشانەی "قەڵەم" دابگرە بۆ دەستکاریکردن. نرخە نوێیەکە بنووسە و خەزنی بکە.',
          ),
          FaqItem(
            'چۆن ئاگادارکردنەوە بۆ کەمی کاڵا دابنێم؟',
            'کاتێک کاڵایەک داخڵ دەکەیت، خانەیەک هەیە بە ناوی "کەمترین ئاست". ئەگەر ژمارە ٥ بنووسیت، ئەوا کاتێک تەنها ٥ دانە دەمێنێتەوە، بەرنامەکە بە ڕەنگی سوور ئاگادارت دەکاتەوە.',
          ),
        ]),
        FaqCategory('خەرجییەکان و کڕینەکان', [
          FaqItem(
            'چۆن خەرجییەکانی دوکان یان کڕینی کاڵا تۆمار بکەم؟',
            'بڕۆ بۆ بەشی "کڕینەکان" (Purchases) لە سەرەوەی شاشەکە. لەوێ دەتوانیت مامەڵەی کڕینی کاڵای نوێ یان خەرجییەکانت داخڵ بکەیت بۆ ئەوەی لە قازانجەکەت دەربچێت.',
          ),
          FaqItem(
            'ئەگەر کاڵایەکم کڕی و دواتر گەڕاندمەوە چی بکەم؟',
            'لەناو هەمان بەشی کڕینەکان، دەتوانیت پسوڵەی کڕینەکە بکەیتەوە و "گەڕاندنەوە" هەڵبژێریت بۆ ئەوەی پارەکە و کاڵاکە ڕاست ببێتەوە لە سیستەمەکەدا.',
          ),
        ]),
        FaqCategory('بەڕێوەبردنی کارمەندان', [
          FaqItem(
            'چۆن کارمەندێک زیاد بکەم بۆ بەرنامەکە؟',
            '١. بڕۆ بۆ "ڕێکخستنەکان" -> "بانگهێشتکردنی کارمەندان".\n٢. کۆدێکی ٦ پیتە پیشان دەدرێت. ئەم کۆدە بدە بە کارمەندەکەت.\n٣. کارمەندەکە لە مۆبایلەکەی خۆیەوە کۆدەکە داخڵ دەکات بۆ ئەوەی ببەسترێتەوە بە دوکانەکەتەوە.',
          ),
          FaqItem(
            'بۆچی کارمەندەکەم ناتوانێت بچێتە ژوورەوە؟',
            'پێویستە تۆ ڕێگەی پێ بدەیت! بڕۆ بۆ "ڕێکخستنەکان" -> "بەڕێوەبردنی بەکارهێنەران". لەوێ ناوی کارمەندەکە دەبینیت، دوگمەی "پەسەندکردن" دابگرە.',
          ),
          FaqItem(
            'چۆن بزانم کارمەندەکانم چیان کردووە؟',
            'لە شاشەی سەرەکی (Dashboard)، بەشێک هەیە بە ناوی "تۆماری چالاکییەکان" (Audit Log). لەوێ دەتوانیت هەموو جوڵەیەک ببینیت: کێ کاڵای فرۆشتووە، کێ قەرزی وەرگرتووە، و کێ دەستکاری داتای کردووە.',
          ),
        ]),
        FaqCategory('ڕێکخستنەکان و پاراستنی داتا', [
          FaqItem(
            'چۆن دڵنیا بم کە داتاکانم نافەوتێت؟',
            'داتاکانت لە کلاود (Cloud) پارێزراون، بەڵام بۆ دڵنیایی خۆت دەتوانیت بڕۆیتە "ڕێکخستنەکان" -> "هەناردەکردنی داتا" و "کۆپییەکی پارێزراو" (Full Backup) دابگریت و لە تێلیگرام یان واتساپ بۆ خۆتی بنێریت.',
          ),
          FaqItem(
            'چۆن ڕاپۆرتەکان دەربهێنم بە شێوەی ئیکسڵ؟',
            'لە بەشی "هەناردەکردنی داتا"، دەتوانیت داتای کڕیارەکان، فرۆشتنی مانگانە، و کۆگا بە شێوەی ئیکسڵ (CSV) دابگریت بۆ پرینتکردن یان ژمێریاری.',
          ),
          FaqItem(
            'چۆن پرۆفایلەکەم یان وێنەی پرۆفایلەکەم نوێ بکەمەوە؟',
            'لە سەرەوەی شاشەی ڕێکخستنەکان کرتە بکە سەر ناوەکەت. لەوێ دەتوانیت ناوەکەت، ژمارەی تەلەفۆنەکەت، و وێنەی پرۆفایلەکەت بگۆڕیت.',
          ),
          FaqItem(
            'چۆن زمانی بەرنامەکە بگۆڕم؟',
            'لە خوارەوەی شاشەی ڕێکخستنەکان، زمانەکانی (کوردی، عەرەبی، ئینگلیزی) دانراون. بە کرتەکردن لەسەریان زمانەکە دەگۆڕێت.',
          ),
        ]),
      ];
    } else if (langCode == 'ar') {
      return const [
        FaqCategory('المبيعات والإيصالات', [
          FaqItem(
            'كيف أسجل عملية بيع جديدة؟',
            '١. اذهب إلى قسم "المبيعات" في أسفل الشاشة.\n٢. حدد المنتجات التي يريد العميل شراءها.\n٣. انقر على زر "الدفع" في الأسفل.\n٤. حدد ما إذا كان الدفع نقداً أو بالآجل ثم احفظ الإيصال.',
          ),
          FaqItem(
            'كيف أعطي سعراً مختلفاً للعميل؟',
            'أثناء البيع، يمكنك النقر على أيقونة القلم بجانب أي منتج لتعديل سعر الوحدة الخاص به مباشرة.',
          ),
          FaqItem(
            'كيف أسترجع منتجاً مباعاً (إرجاع)؟',
            '١. اذهب إلى قسم "الطلبات" (الإيصالات).\n٢. افتح الإيصال المعني وانقر على زر "إرجاع" (Return).\n٣. أدخل كمية العناصر المرتجعة ليتم إعادتها إلى المخزن وتحديث الحسابات.',
          ),
          FaqItem(
            'كيف يمكنني عرض الإيصالات السابقة؟',
            'في قسم "الطلبات"، ستجد جميع الإيصالات مرتبة زمنياً. يمكنك البحث باسم العميل أو بالتاريخ.',
          ),
        ]),
        FaqCategory('العملاء والديون', [
          FaqItem(
            'كيف أضيف عميلاً جديداً؟',
            '١. اذهب إلى قسم "العملاء" وانقر على زر الإضافة (+).\n٢. أدخل اسم العميل ورقم هاتفه واحفظه لتتمكن من تسجيل ديونه.',
          ),
          FaqItem(
            'كيف أستلم ديون العملاء؟',
            '١. ابحث عن اسم العميل في قائمة العملاء وانقر على "استلام الدفعة".\n٢. أدخل المبلغ المدفوع واحفظه. سيتم تقليل دينه تلقائياً.',
          ),
          FaqItem(
            'كيف أعرف إجمالي ديون العميل؟',
            'في قائمة العملاء، يظهر إجمالي الديون بجوار اسم كل عميل. اللون الأحمر يشير إلى وجود ديون غير مسددة.',
          ),
          FaqItem(
            'كيف أرى سجل معاملات العميل؟',
            'اضغط على اسم العميل لفتح ملفه الشخصي، حيث يمكنك رؤية جميع مشترياته، ديونه، ودفعاته السابقة بالتفصيل.',
          ),
        ]),
        FaqCategory('المخزون والمنتجات', [
          FaqItem(
            'كيف أضيف منتجاً جديداً إلى مخزني؟',
            '١. اذهب إلى قسم "المخزن" وانقر على (+).\n٢. أدخل اسم المنتج، سعر الشراء، وسعر البيع.\n٣. أدخل المخزون المتوفر ويمكنك أيضاً كتابة اسم المورد.',
          ),
          FaqItem(
            'كيف أغير سعر المنتج؟',
            'في المخزن، انقر على المنتج ثم أيقونة "القلم" للتعديل. أدخل السعر الجديد واحفظه.',
          ),
          FaqItem(
            'كيف أقوم بتعيين تنبيه نقص المخزون؟',
            'أثناء إضافة أو تعديل المنتج، يوجد حقل "الحد الأدنى". إذا كتبت ٥، سيتم تنبيهك باللون الأحمر عندما يتبقى ٥ قطع فقط.',
          ),
        ]),
        FaqCategory('المشتريات والمصروفات', [
          FaqItem(
            'كيف أسجل مشترياتي ومصروفات المتجر؟',
            'اذهب إلى قسم "المشتريات" في أعلى الشاشة. يمكنك هناك تسجيل البضائع الجديدة التي تشتريها لتتبع نفقاتك وأرباحك بدقة.',
          ),
          FaqItem(
            'ماذا أفعل إذا أرجعت بضاعة اشتريتها؟',
            'في قسم المشتريات، افتح الفاتورة المعنية واختر "إرجاع" ليتم تعديل المخزون واسترداد المبلغ في النظام.',
          ),
        ]),
        FaqCategory('إدارة الموظفين', [
          FaqItem(
            'كيف أضيف موظفاً إلى التطبيق؟',
            '١. اذهب إلى "الإعدادات" -> "دعوة الموظفين".\n٢. ستجد رمزاً من ٦ أحرف، أعطه لموظفك.\n٣. يقوم الموظف بإدخال الرمز من هاتفه للانضمام لمتجرك.',
          ),
          FaqItem(
            'لماذا لا يمكن لموظفي الدخول بعد إدخال الرمز؟',
            'لأسباب أمنية، يجب الموافقة عليه أولاً. اذهب إلى "الإعدادات" -> "إدارة المستخدمين"، وانقر على "قبول" بجوار اسم الموظف.',
          ),
          FaqItem(
            'كيف أراقب نشاط الموظفين؟',
            'في الشاشة الرئيسية (Dashboard)، يوجد سجل "النشاطات" (Audit Log) يظهر لك من قام بالبيع، من استلم الديون، وأي تعديلات أخرى بالتفصيل.',
          ),
        ]),
        FaqCategory('الإعدادات وحماية البيانات', [
          FaqItem(
            'كيف أضمن عدم ضياع بياناتي؟',
            'بياناتك محفوظة سحابياً بشكل آمن، ولكن يمكنك تصدير "نسخة احتياطية كاملة" من "تصدير البيانات" في الإعدادات وحفظها في تليجرام أو واتساب كإجراء إضافي.',
          ),
          FaqItem(
            'كيف أستخرج التقارير بصيغة إكسل (Excel)؟',
            'في قسم "تصدير البيانات"، يمكنك تنزيل بيانات العملاء، المبيعات الشهرية، والمخزون كملفات (CSV) قابلة للطباعة والمشاركة.',
          ),
          FaqItem(
            'كيف أقوم بتحديث ملفي الشخصي أو صورتي الشخصية؟',
            'اضغط على اسمك في أعلى شاشة الإعدادات. هنا يمكنك تعديل اسمك الشخصي ورقم هاتفك وتحميل صورة شخصية جديدة.',
          ),
          FaqItem(
            'كيف أغير لغة التطبيق؟',
            'في أسفل شاشة الإعدادات، انقر على اللغة المطلوبة (الكردية، العربية، الإنجليزية) لتتغير فوراً.',
          ),
        ]),
      ];
    } else {
      return const [
        FaqCategory('Sales & Receipts', [
          FaqItem(
            'How do I record a new sale?',
            '1. Go to the "Sales" section at the bottom of the screen.\n2. Select the products the customer wishes to buy.\n3. Click the "Checkout" button.\n4. Specify whether they are paying in cash or accumulating debt, then save the receipt.',
          ),
          FaqItem(
            'How do I give a specific price to a customer?',
            'While creating a sale, click the pencil icon next to any product to adjust its individual unit price.',
          ),
          FaqItem(
            'How do I process a return for a sold item?',
            '1. Go to the "Orders" section.\n2. Open the specific receipt.\n3. Click "Return".\n4. Enter the quantity being returned to adjust your inventory and total sales.',
          ),
          FaqItem(
            'How do I view past receipts?',
            'In the "Orders" section, you will see a chronological list of all receipts. You can search by customer name or date to find exactly what you need.',
          ),
        ]),
        FaqCategory('Customers & Debts', [
          FaqItem(
            'How do I add a new customer?',
            '1. Go to the "Customers" section.\n2. Click the add (+) button.\n3. Enter their name and phone number to start tracking their debts.',
          ),
          FaqItem(
            'How do I collect a debt payment?',
            '1. Find the customer in the Customers list and click "Receive Payment".\n2. Enter the amount paid. The system will automatically reduce their outstanding debt.',
          ),
          FaqItem(
            'How do I check a customer\'s total debt?',
            'The total debt is displayed right next to each customer\'s name in the list. Red text indicates outstanding unpaid debt.',
          ),
          FaqItem(
            'How can I view a customer\'s history?',
            'Tap on any customer\'s name to open their profile. You will see a complete history of their purchases, debts, and payments.',
          ),
        ]),
        FaqCategory('Inventory & Products', [
          FaqItem(
            'How do I add a new product to my store?',
            '1. Go to the "Inventory" section and click the add (+) button.\n2. Enter the product name, buy price, sell price, and initial stock.\n3. You can also optionally enter a Supplier Name for your reference.',
          ),
          FaqItem(
            'How do I change a product\'s price?',
            'In the Inventory section, tap the product, then click the "Edit" pencil icon. Update the price and save.',
          ),
          FaqItem(
            'How do I set a low stock alert?',
            'When adding or editing a product, use the "Low Stock" threshold field. If you enter 5, the app alerts you in red when only 5 items are left.',
          ),
        ]),
        FaqCategory('Purchases & Expenses', [
          FaqItem(
            'How do I track store expenses or new stock?',
            'Go to the "Purchases" section at the top of the home screen. Record new stock purchases and expenses here to accurately track your profitability.',
          ),
          FaqItem(
            'What if I return goods I purchased?',
            'Open the relevant purchase receipt in the Purchases section and select "Return" to adjust your inventory and financial records accordingly.',
          ),
        ]),
        FaqCategory('Employee Management', [
          FaqItem(
            'How do I invite an employee?',
            '1. Go to "Settings" -> "Invite Employees".\n2. Give the displayed 6-character code to your employee.\n3. They enter this code in their app to link to your store.',
          ),
          FaqItem(
            'Why can\'t my employee log in?',
            'You must approve them first! Go to "Settings" -> "Manage Users", find their name, and click "Accept" to grant access.',
          ),
          FaqItem(
            'How do I monitor employee actions?',
            'Check the "Audit Log" on your Dashboard. It provides a detailed trail of every action: who made a sale, collected debt, or edited a product.',
          ),
        ]),
        FaqCategory('Settings & Data Backup', [
          FaqItem(
            'How can I make sure my data is safe?',
            'Your data is safely backed up in the cloud. For extra security, go to "Settings" -> "Export Data" and download a "Secure Full Backup" file to your device or Telegram.',
          ),
          FaqItem(
            'How do I generate Excel (CSV) reports?',
            'In the "Export Data" section, you can download specialized Excel sheets for Customers, Monthly Sales, and Inventory.',
          ),
          FaqItem(
            'How do I update my profile or profile picture?',
            'Tap your name at the top of the Settings screen. Here you can edit your personal name, phone number, and upload a new profile picture.',
          ),
          FaqItem(
            'How do I change the app language?',
            'Scroll to the bottom of the Settings screen and select your preferred language (Kurdish, Arabic, or English). The app will update immediately.',
          ),
        ]),
      ];
    }
  }
}
