import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final title = isKurdish ? 'ئاگادارکردنەوەکان' : isArabic ? 'الإشعارات' : 'Notifications';
    final noData = isKurdish ? 'هیچ ئاگادارکردنەوەیەک نییە' : isArabic ? 'لا توجد إشعارات' : 'No notifications yet';
    final markAllRead = isKurdish ? 'هەمووی وەک خوێندراوە دیاری بکە' : isArabic ? 'تحديد الكل كمقروء' : 'Mark all as read';
    final clearAll = isKurdish ? 'سڕینەوەی هەمووی' : isArabic ? 'مسح الكل' : 'Clear all';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    if (value == 'read') {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                    } else if (value == 'clear') {
                      ref.read(notificationProvider.notifier).clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(markAllRead, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 12),
                          Text(clearAll, style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 60, bottom: 16, end: 60),
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
          
          if (notifications.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_off_rounded, size: 64, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      noData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final notification = notifications[index];
                    final isRead = notification.isRead;
                    
                    IconData iconData = Icons.notifications_rounded;
                    Color iconColor = theme.colorScheme.primary;
                    if (notification.type == 'sync') {
                      iconData = Icons.sync_rounded;
                      iconColor = Colors.blueAccent;
                    } else if (notification.type == 'stock') {
                      iconData = Icons.inventory_2_rounded;
                      iconColor = Colors.orangeAccent;
                    } else if (notification.type == 'order') {
                      iconData = Icons.shopping_bag_rounded;
                      iconColor = Colors.greenAccent;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isRead ? theme.colorScheme.surface.withValues(alpha: 0.5) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead 
                            ? Colors.transparent 
                            : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!isRead) {
                              ref.read(notificationProvider.notifier).markAsRead(notification.id);
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isRead ? (isDark ? Colors.white10 : Colors.black12) : iconColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 20,
                                    color: isRead ? theme.colorScheme.onSurface.withValues(alpha: 0.3) : iconColor,
                                  ),
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
                                              _getTranslatedTitle(notification.title, isKurdish, isArabic),
                                              style: TextStyle(
                                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                fontSize: 15,
                                                color: isRead ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatTime(notification.timestamp, isKurdish, isArabic),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                              color: isRead ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _getTranslatedMessage(notification.message, isKurdish, isArabic),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.05);
                  },
                  childCount: notifications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, bool isKurdish, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return isKurdish ? '${diff.inDays} ڕۆژ' : isArabic ? 'يوم ${diff.inDays}' : '${diff.inDays}d';
    }
    if (diff.inHours > 0) {
      return isKurdish ? '${diff.inHours} کاتژمێر' : isArabic ? 'ساعة ${diff.inHours}' : '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return isKurdish ? '${diff.inMinutes} خولەک' : isArabic ? 'دقيقة ${diff.inMinutes}' : '${diff.inMinutes}m';
    }
    return isKurdish ? 'ئێستا' : isArabic ? 'الآن' : 'now';
  }

  String _getTranslatedTitle(String title, bool isKurdish, bool isArabic) {
    if (title.contains('Low Stock Alert')) {
      return isKurdish ? 'ئاگاداری کەمی کاڵا' : isArabic ? 'تنبيه نقص المخزون' : title;
    }
    if (title.contains('Debt Collection Reminder')) {
      return isKurdish ? 'بیرخستنەوەی قەرز' : isArabic ? 'تذكير بجمع الديون' : title;
    }
    if (title.contains('Order Submitted')) {
      return isKurdish ? 'داواکاری نێردرا' : isArabic ? 'تم تقديم الطلب' : title;
    }
    if (title.contains('Order Approved')) {
      return isKurdish ? 'داواکاری پەسەندکرا' : isArabic ? 'تمت الموافقة على الطلب' : title;
    }
    if (title.contains('Order Rejected')) {
      return isKurdish ? 'داواکاری ڕەتکرایەوە' : isArabic ? 'تم رفض الطلب' : title;
    }
    if (title.contains('New Product Registered')) {
      return isKurdish ? 'کاڵای نوێ تۆمارکرا' : isArabic ? 'تم تسجيل منتج جديد' : title;
    }
    if (title.contains('Payment Received')) {
      return isKurdish ? 'پارە وەرگیرا' : isArabic ? 'تم استلام الدفعة' : title;
    }
    return title;
  }

  String _getTranslatedMessage(String message, bool isKurdish, bool isArabic) {
    if (message.contains('running low on stock')) {
      final number = message.split(' ').first;
      return isKurdish ? '$number کاڵا لە کەمبوونەوەدایە (کەمتر لە 50 دانە).' : isArabic ? '$number عناصر على وشك النفاد (أقل من 50 وحدة).' : message;
    }
    if (message.contains('outstanding debt balances')) {
      final number = message.split(' ').first;
      return isKurdish ? '$number کڕیار قەرزیان لەسەرە.' : isArabic ? '$number عملاء لديهم ديون مستحقة.' : message;
    }
    if (message.contains('submitted successfully')) {
      final match = RegExp(r'Order for (.*?) submitted successfully').firstMatch(message);
      final customer = match != null ? match.group(1) : '';
      return isKurdish ? 'داواکاری بۆ $customer بە سەرکەوتوویی نێردرا.' : isArabic ? 'تم إرسال طلب $customer بنجاح.' : message;
    }
    if (message.contains('delivered') && message.contains('Order of')) {
      final match = RegExp(r'Order of (.*?) for (.*?) delivered').firstMatch(message);
      if (match != null) {
        return isKurdish ? 'داواکاری بە بڕی ${match.group(1)} بۆ ${match.group(2)} گەیەندرا.' : isArabic ? 'تم توصيل طلب بقيمة ${match.group(1)} لـ ${match.group(2)}.' : message;
      }
    }
    if (message.contains('was rejected')) {
      final match = RegExp(r'Order of (.*?) for (.*?) was rejected').firstMatch(message);
      if (match != null) {
        return isKurdish ? 'داواکاری بە بڕی ${match.group(1)} بۆ ${match.group(2)} ڕەتکرایەوە.' : isArabic ? 'تم رفض طلب بقيمة ${match.group(1)} لـ ${match.group(2)}.' : message;
      }
    }
    if (message.contains('added to inventory catalog')) {
      final match = RegExp(r'(.*?) added to inventory catalog').firstMatch(message);
      if (match != null) {
        return isKurdish ? '${match.group(1)} زیادکرا بۆ لیستی کاڵاکان.' : isArabic ? 'تمت إضافة ${match.group(1)} إلى كتالوج المخزون.' : message;
      }
    }
    if (message.contains('received from')) {
      final parts = message.replaceAll('.', '').split(' received from ');
      if (parts.length == 2) {
        return isKurdish ? 'بڕی ${parts[0]} وەرگیرا لە ${parts[1]}.' : isArabic ? 'تم استلام ${parts[0]} من ${parts[1]}.' : message;
      }
    }
    return message;
  }
}

