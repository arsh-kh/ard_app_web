import 'package:flutter/material.dart';
import '../../core/utils/app_translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/models/audit_log_entity.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/custom_loader.dart';

final auditLogsProvider = StreamProvider.autoDispose<List<AuditLogEntity>>((ref) {
  return FirebaseFirestore.instance
      .collection('audit_logs')
      .orderBy('timestamp', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => AuditLogEntity.fromJson({'id': doc.id, ...doc.data()}))
          .toList());
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
        error: (err, _) => Center(child: Text('${Tr.t('errorLoadingLogs', langCode)}: $err')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Text(Tr.t('auto_Noauditlogsfoun', langCode)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final icon = _getIconForAction(log.action);
              final color = _getColorForAction(log.action, theme);
              final localizedAction = _localizeAction(log.action, isKurdish, isArabic);
              final localizedEntity = _localizeEntity(log.entityType, isKurdish, isArabic);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            Text('${Tr.t('auto_User', langCode)}: ${log.userName}'),
                            const SizedBox(height: 8),
                            Text('${Tr.t('auto_Action', langCode)}: $localizedAction'),
                            const SizedBox(height: 8),
                            Text('${Tr.t('auto_Entity', langCode)}: $localizedEntity'),
                            const SizedBox(height: 8),
                            Text('${Tr.t('auto_Time', langCode)}: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)}'),
                            if (log.details != null && log.details!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('${Tr.t('auto_MoreDetails', langCode)}: ${log.details}'),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      log.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, HH:mm').format(log.timestamp),
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$localizedAction - $localizedEntity',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              if (log.details != null && log.details!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  log.details!,
                                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
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
              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index.clamp(0, 10))).slideY(begin: 0.1);
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
    if (lower.contains('create')) return Colors.green;
    if (lower.contains('delete')) return Colors.red;
    if (lower.contains('update') || lower.contains('deliver')) return theme.colorScheme.primary;
    return Colors.grey;
  }

  String _localizeAction(String action, bool isKu, bool isAr) {
    if (isKu) {
      switch (action) {
        case 'CREATED': return 'دروستکرا';
        case 'UPDATED': return 'نوێکرایەوە';
        case 'DELETED': return 'سڕایەوە';
        case 'STATUS_UPDATED': return 'باری نوێکرایەوە';
        case 'DELIVERED': return 'گەیەنرا';
        case 'RESTOCKED': return 'کۆگا پڕکرایەوە';
        case 'COLLECTED_DEBT': return 'قەرز وەرگیرا';
      }
    } else if (isAr) {
      switch (action) {
        case 'CREATED': return 'تم الإنشاء';
        case 'UPDATED': return 'تم التحديث';
        case 'DELETED': return 'تم الحذف';
        case 'STATUS_UPDATED': return 'تم تحديث الحالة';
        case 'DELIVERED': return 'تم التوصيل';
        case 'RESTOCKED': return 'تم إعادة التخزين';
        case 'COLLECTED_DEBT': return 'تم تحصيل الديون';
      }
    }
    return action;
  }

  String _localizeEntity(String entity, bool isKu, bool isAr) {
    if (isKu) {
      switch (entity) {
        case 'Order': return 'داواکاری';
        case 'Product': return 'کاڵا';
        case 'Customer': return 'کڕیار';
        case 'Payment': return 'پارەدان';
      }
    } else if (isAr) {
      switch (entity) {
        case 'Order': return 'طلب';
        case 'Product': return 'منتج';
        case 'Customer': return 'عميل';
        case 'Payment': return 'دفع';
      }
    }
    return entity;
  }
}
