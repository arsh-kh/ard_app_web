import 'package:flutter/material.dart';
import '../../core/utils/app_translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/audit_log_entity.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/custom_loader.dart';

final auditLogsProvider = StreamProvider.autoDispose<List<AuditLogEntity>>((
  ref,
) {
  final user = ref.watch(authProvider).user;
  if (user == null || user.businessId == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('audit_logs')
      .where('businessId', isEqualTo: user.businessId)
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => AuditLogEntity.fromJson({'id': doc.id, ...doc.data()}),
            )
            .toList(),
      );
});

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsProvider);
    final isKurdish = ref.read(localeProvider).languageCode == 'ku';
    final langCode = ref.watch(localeProvider).languageCode;
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(Tr.t('auto_AuditLogs', langCode)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CustomLoader()),
        error: (err, _) =>
            Center(child: Text('${Tr.t('errorLoadingLogs', langCode)}: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(child: Text(Tr.t('auto_Noauditlogsfoun', langCode)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final icon = _getIconForAction(log.action);
              final color = _getColorForAction(log.action, theme);
              final localizedAction = _localizeAction(
                log.action,
                isKurdish,
                isArabic,
              );
              final localizedEntity = _localizeEntity(
                log.entityType,
                isKurdish,
                isArabic,
              );

              return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: theme.cardTheme.color,
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(Tr.t('auto_Details', langCode)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${Tr.t('auto_User', langCode)}: ${log.userName}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${Tr.t('auto_Action', langCode)}: $localizedAction',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${Tr.t('auto_Entity', langCode)}: $localizedEntity',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${Tr.t('auto_Time', langCode)}: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}',
                                ),
                                if (log.details != null &&
                                    log.details!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    '${Tr.t('auto_MoreDetails', langCode)}: ${_getLocalizedDetails(log, langCode)}',
                                  ),
                                ],
                                if (log.metadata != null &&
                                    log.metadata!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  if (log.metadata!.containsKey('changes')) ...[
                                    Text(
                                      langCode == 'ku'
                                          ? 'گۆڕانکارییەکان:'
                                          : langCode == 'ar'
                                          ? 'التغييرات:'
                                          : 'Changes:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            (log.metadata!['changes']
                                                    as Map<String, dynamic>)
                                                .entries
                                                .map((c) {
                                                  final field =
                                                      _localizeFieldName(
                                                        c.key,
                                                        langCode,
                                                      );
                                                  final val =
                                                      c.value
                                                          as Map<
                                                            String,
                                                            dynamic
                                                          >;
                                                  final oldVal =
                                                      val['old']?.toString() ??
                                                      'N/A';
                                                  final newVal =
                                                      val['new']?.toString() ??
                                                      'N/A';
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 4.0,
                                                        ),
                                                    child: Text(
                                                      '• $field: $oldVal ➔ $newVal',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      langCode == 'ku'
                                          ? 'زانیاری زیاتر:'
                                          : langCode == 'ar'
                                          ? 'معلومات إضافية:'
                                          : 'Additional Details:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: log.metadata!.entries.map((
                                          e,
                                        ) {
                                          final field = _localizeFieldName(
                                            e.key,
                                            langCode,
                                          );
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4.0,
                                            ),
                                            child: Text(
                                              '• $field: ${e.value}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(Tr.t('auto_Close', langCode)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          log.userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM d, HH:mm',
                                        ).format(log.timestamp),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$localizedAction - $localizedEntity',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (log.details != null &&
                                      log.details!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _getLocalizedDetails(log, langCode),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 50 * index.clamp(0, 10)),
                  )
                  .slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  IconData _getIconForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('create')) return Icons.add_circle_outline;
    if (lower.contains('update')) return Icons.edit_outlined;
    if (lower.contains('delete')) return Icons.delete_outline;
    if (lower.contains('deliver')) return Icons.local_shipping_outlined;
    return Icons.info_outline;
  }

  Color _getColorForAction(String action, ThemeData theme) {
    final lower = action.toLowerCase();
    if (lower.contains('create')) return Colors.grey;
    if (lower.contains('delete')) return Colors.grey;
    if (lower.contains('update') || lower.contains('deliver')) {
      return theme.colorScheme.primary;
    }
    return Colors.grey;
  }

  String _localizeAction(String action, bool isKu, bool isAr) {
    if (isKu) {
      switch (action) {
        case 'CREATED':
          return 'دروستکرا';
        case 'UPDATED':
          return 'نوێکرایەوە';
        case 'DELETED':
          return 'سڕایەوە';
        case 'STATUS_UPDATED':
          return 'باری نوێکرایەوە';
        case 'DELIVERED':
          return 'گەیەنرا';
        case 'RESTOCKED':
          return 'کۆگا پڕکرایەوە';
        case 'COLLECTED_DEBT':
          return 'قەرز وەرگیرا';
      }
    } else if (isAr) {
      switch (action) {
        case 'CREATED':
          return 'تم الإنشاء';
        case 'UPDATED':
          return 'تم التحديث';
        case 'DELETED':
          return 'تم الحذف';
        case 'STATUS_UPDATED':
          return 'تم تحديث الحالة';
        case 'DELIVERED':
          return 'تم التوصيل';
        case 'RESTOCKED':
          return 'تم إعادة التخزين';
        case 'COLLECTED_DEBT':
          return 'تم تحصيل الديون';
      }
    }
    return action;
  }

  String _localizeEntity(String entity, bool isKu, bool isAr) {
    if (isKu) {
      switch (entity) {
        case 'Order':
          return 'داواکاری';
        case 'Product':
          return 'کاڵا';
        case 'Customer':
          return 'کڕیار';
        case 'Payment':
          return 'پارەدان';
      }
    } else if (isAr) {
      switch (entity) {
        case 'Order':
          return 'طلب';
        case 'Product':
          return 'منتج';
        case 'Customer':
          return 'عميل';
        case 'Payment':
          return 'دفع';
      }
    }
    return entity;
  }

  String _formatCurrency(String raw) {
    final val = double.tryParse(raw.replaceAll(',', ''));
    if (val != null) {
      return NumberFormat('#,###').format(val);
    }
    return raw;
  }

  String _getLocalizedDetails(AuditLogEntity log, String lang) {
    if (log.details == null) return '';
    final details = log.details!;
    final walkIn = Tr.t('walkIn', lang);

    try {
      if (details.contains('Collected payment of')) {
        final match = RegExp(
          r'Collected payment of (.*?) IQD from (.*)',
        ).firstMatch(details);
        if (match != null) {
          final amt = _formatCurrency(match.group(1)!);
          final cust = match.group(2)!.toLowerCase().contains('walk-in')
              ? walkIn
              : match.group(2)!;
          return lang == 'ku'
              ? 'بڕی $amt وەرگیرا لە کڕیار $cust'
              : lang == 'ar'
              ? 'تم استلام مبلغ $amt من العميل $cust'
              : 'Collected payment of $amt from $cust';
        }
      }

      if (details.contains('Sold') && details.contains('product(s) to')) {
        final match = RegExp(
          r'Sold (.*?) product\(s\) to (.*?) for (.*?)\. \(Order #(.*?)\)',
        ).firstMatch(details);
        if (match != null) {
          final qty = match.group(1)!;
          final cust = match.group(2)!.toLowerCase().contains('walk-in')
              ? walkIn
              : match.group(2)!;
          final amt = _formatCurrency(match.group(3)!);
          final order = match.group(4)!;
          return lang == 'ku'
              ? '$qty کاڵا فرۆشرا بە $cust بە بڕی $amt (داواکاری #$order)'
              : lang == 'ar'
              ? 'تم بيع $qty منتج(منتجات) لـ $cust بمبلغ $amt (طلب #$order)'
              : 'Sold $qty product(s) to $cust for $amt (Order #$order)';
        }
      }

      if (details.startsWith('Modified product')) {
        final match = RegExp(
          r"Modified product '(.*?)' \(Price: (.*?), Stock: (.*?)\)",
        ).firstMatch(details);
        if (match != null) {
          final name = match.group(1)!;
          final price = _formatCurrency(match.group(2)!);
          final stock = match.group(3)!;
          return lang == 'ku'
              ? 'کاڵای \'$name\' نوێکرایەوە (نرخ: $price, کۆگا: $stock)'
              : lang == 'ar'
              ? 'تم تحديث المنتج \'$name\' (السعر: $price, المخزون: $stock)'
              : 'Modified product \'$name\' (Price: $price, Stock: $stock)';
        }
      }

      if (details.startsWith('Paid') && details.contains('to factory')) {
        final match = RegExp(
          r'Paid (.*?) to factory: (.*)',
        ).firstMatch(details);
        if (match != null) {
          final amt = _formatCurrency(match.group(1)!);
          final fact = match.group(2)!;
          return lang == 'ku'
              ? 'بڕی $amt درا بە کارگەی: $fact'
              : lang == 'ar'
              ? 'تم دفع مبلغ $amt للمصنع: $fact'
              : 'Paid $amt to factory: $fact';
        }
      }

      if (details.contains('Deleted Order')) {
        return lang == 'ku'
            ? 'داواکاری سڕایەوە. کۆگا و قەرز گەڕێندرانەوە ئەگەر گەیەنرابێت.'
            : lang == 'ar'
            ? 'تم حذف الطلب. تم استرجاع المخزون والديون إذا تم التوصيل.'
            : 'Deleted Order. Stock and Debt reverted if it was delivered.';
      }

      if (details.startsWith('Added new product')) {
        final match = RegExp(
          r"Added new product '(.*?)' with starting stock (.*)",
        ).firstMatch(details);
        if (match != null) {
          final name = match.group(1)!;
          final stock = match.group(2)!;
          return lang == 'ku'
              ? 'کاڵای نوێ \'$name\' زیادکرا بە بڕی $stock'
              : lang == 'ar'
              ? 'تم إضافة منتج جديد \'$name\' بمخزون $stock'
              : 'Added new product \'$name\' with starting stock $stock';
        }
      }

      if (details.startsWith('Registered new client:')) {
        final name = details.split(': ').last;
        return lang == 'ku'
            ? 'کڕیاری نوێ تۆمارکرا: $name'
            : lang == 'ar'
            ? 'تم تسجيل عميل جديد: $name'
            : 'Registered new client: $name';
      }

      if (details.startsWith('Deleted product')) {
        final match = RegExp(r"Deleted product '(.*?)'").firstMatch(details);
        if (match != null) {
          final name = match.group(1)!;
          return lang == 'ku'
              ? 'کاڵای \'$name\' سڕایەوە'
              : lang == 'ar'
              ? 'تم حذف المنتج \'$name\''
              : 'Deleted product \'$name\'';
        }
      }
    } catch (e) {
      // ignore
    }

    // fallback for walkin names in other logs
    if (details.toLowerCase().contains('walk-in') && lang != 'en') {
      return details.replaceAll(
        RegExp(r'walk-in customer|walk-in', caseSensitive: false),
        walkIn,
      );
    }

    return details;
  }

  String _localizeFieldName(String field, String langCode) {
    if (langCode == 'en') return field;

    final Map<String, String> ku = {
      'businessName': 'ناوی کڕیار',
      'phone': 'تەلەفۆن',
      'debtBalance': 'بڕی قەرز',
      'email': 'ئیمەیڵ',
      'address': 'ناونیشان',
      'notes': 'تێبینی',
      'name': 'ناوی کاڵا',
      'buyPrice': 'نرخی کڕین',
      'sellPrice': 'نرخی فرۆشتن',
      'stockQuantity': 'بڕی کۆگا',
      'lowStockThreshold': 'ئاگاداری کەمی کاڵا',
      'barcode': 'بارکۆد',
      'category': 'جۆر',
      'orderNumber': 'ژمارەی داواکاری',
      'totalAmount': 'بڕی گشتی',
      'itemsCount': 'ژمارەی کاڵاکان',
      'itemsList': 'لیستی کاڵاکان',
      'status': 'بارودۆخ',
      'initialDebt': 'قەرزی سەرەتا',
      'customerName': 'ناوی کڕیار',
      'productName': 'ناوی کاڵا',
    };

    final Map<String, String> ar = {
      'businessName': 'اسم العميل',
      'phone': 'رقم الهاتف',
      'debtBalance': 'الرصيد',
      'email': 'البريد الإلكتروني',
      'address': 'العنوان',
      'notes': 'ملاحظات',
      'name': 'اسم المنتج',
      'buyPrice': 'سعر الشراء',
      'sellPrice': 'سعر البيع',
      'stockQuantity': 'كمية المخزون',
      'lowStockThreshold': 'تنبيه انخفاض المخزون',
      'barcode': 'الباركود',
      'category': 'الفئة',
      'orderNumber': 'رقم الطلب',
      'totalAmount': 'المبلغ الإجمالي',
      'itemsCount': 'عدد العناصر',
      'itemsList': 'قائمة العناصر',
      'status': 'الحالة',
      'initialDebt': 'الرصيد الأولي',
      'customerName': 'اسم العميل',
      'productName': 'اسم المنتج',
    };

    if (langCode == 'ku') return ku[field] ?? field;
    if (langCode == 'ar') return ar[field] ?? field;
    return field;
  }
}
