import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:intl/intl.dart';
import 'dart:convert';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;

    final theme = Theme.of(context);

    final title = Tr.t('notifTitle', langCode);
    final noData = Tr.t('noNotifs', langCode);
    final clearAll = Tr.t('clearAll', langCode);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            pinned: true,
            actions: [
              if (notifications.isNotEmpty)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == 'clear') {
                      ref.read(notificationProvider.notifier).clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_sweep_rounded,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            clearAll,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
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
                      child: Icon(
                        Icons.notifications_off_rounded,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ).animate().scale(
                      delay: 200.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      noData,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final notification = notifications[index];
                  final isRead = notification.isRead;

                  IconData iconData = Icons.notifications_rounded;
                  Color iconColor = theme.colorScheme.primary;
                  if (notification.type == 'sync') {
                    iconData = Icons.sync_rounded;
                  } else if (notification.type == 'stock') {
                    iconData = Icons.inventory_2_rounded;
                  } else if (notification.type == 'order') {
                    iconData = Icons.shopping_bag_rounded;
                  }

                  return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isRead
                              ? theme.colorScheme.surface.withValues(alpha: 0.5)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isRead
                                ? Colors.transparent
                                : (theme.colorScheme.surfaceContainerHighest),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (!isRead) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .markAsRead(notification.id);
                              }
                              if (notification.route != null) {
                                context.push(notification.route!);
                                return;
                              }
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: iconColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          iconData,
                                          color: iconColor,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _getTranslatedTitle(
                                            notification.title,
                                            langCode,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'yyyy-MM-dd • HH:mm',
                                        ).format(notification.timestamp),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _getTranslatedMessage(
                                          notification.message,
                                          langCode,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(Tr.t('closeBtn', langCode)),
                                    ),
                                  ],
                                ),
                              );
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
                                      color: isRead
                                          ? (theme.colorScheme.onSurface
                                                .withValues(alpha: 0.12))
                                          : iconColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      size: 20,
                                      color: isRead
                                          ? theme.colorScheme.onSurface
                                                .withValues(alpha: 0.3)
                                          : iconColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _getTranslatedTitle(
                                                  notification.title,
                                                  langCode,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.w600
                                                      : FontWeight.w800,
                                                  fontSize: 15,
                                                  color: isRead
                                                      ? theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.7,
                                                            )
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTime(
                                                notification.timestamp,
                                                langCode,
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isRead
                                                    ? FontWeight.w500
                                                    : FontWeight.w700,
                                                color: isRead
                                                    ? theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
                                                    : theme.colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _getTranslatedMessage(
                                            notification.message,
                                            langCode,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
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
                      )
                      .animate()
                      .fadeIn(delay: (50 * index).ms)
                      .slideX(begin: 0.05);
                }, childCount: notifications.length),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time, String lang) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return Tr.t('timeDays', lang, {'days': diff.inDays.toString()});
    }
    if (diff.inHours > 0) {
      return Tr.t('timeHours', lang, {'hours': diff.inHours.toString()});
    }
    if (diff.inMinutes > 0) {
      return Tr.t('timeMins', lang, {'mins': diff.inMinutes.toString()});
    }
    return Tr.t('timeNow', lang);
  }

  String _getTranslatedTitle(String title, String lang) {
    if (title == 'low_stock' || title.contains('Low Stock Alert')) {
      return Tr.t('notifTitleLowStock', lang);
    }
    if (title == 'order_delivered' ||
        title.contains('Order Approved') ||
        title.contains('Order Delivered')) {
      return Tr.t('notifTitleOrderApproved', lang);
    }
    if (title == 'order_rejected' || title.contains('Order Rejected')) {
      return Tr.t('notifTitleOrderRejected', lang);
    }
    if (title == 'new_product' || title.contains('New Product Registered')) {
      return Tr.t('notifTitleNewProduct', lang);
    }
    if (title == 'new_customer' || title.contains('New Customer Created')) {
      return Tr.t('notifTitleNewCustomer', lang);
    }
    if (title.contains('Debt Collection Reminder')) {
      return Tr.t('notifTitleDebtReminder', lang);
    }
    if (title == 'order_submitted' || title.contains('Order Submitted')) {
      return Tr.t('notifTitleOrderSubmitted', lang);
    }
    if (title.contains('Payment Received')) {
      return Tr.t('notifTitlePaymentReceived', lang);
    }
    if (title == 'new_factory' || title.contains('New Factory')) {
      return Tr.t('newFactory', lang);
    }
    if (title == 'return_processed') {
      return Tr.t('notifTitleReturnProcessed', lang);
    }
    if (title == 'purchase_return_processed') {
      return Tr.t('notifTitlePurchaseReturnProcessed', lang);
    }
    if (title == 'purchase_saved') {
      return Tr.t('notifTitlePurchaseSaved', lang);
    }
    return title;
  }

  String _translateWalkIn(String name, String lang) {
    if (name.toLowerCase().contains('walk-in')) {
      return Tr.t('walkIn', lang);
    }
    return name;
  }

  String _getTranslatedMessage(String message, String lang) {
    try {
      if (message.startsWith('{')) {
        final Map<String, dynamic> data = jsonDecode(message);

        if (data.containsKey('count') && data.containsKey('threshold')) {
          final count = data['count'].toString();
          final limit = data['threshold'].toString();
          return Tr.t('notifMsgLowStockJson', lang, {
            'count': count,
            'limit': limit,
          });
        }
        if (data.containsKey('amount') && data.containsKey('customer')) {
          final amt = CurrencyFormatter.format(data['amount']);
          final cust = _translateWalkIn(data['customer'], lang);
          return Tr.t('notifMsgOrderDeliveredJson', lang, {
            'amt': amt,
            'cust': cust,
          });
        }
        if (data.containsKey('id') && data.containsKey('customer')) {
          final id = data['id'].toString();
          final cust = _translateWalkIn(data['customer'], lang);
          return Tr.t('notifMsgOrderProcessedJson', lang, {
            'id': id,
            'cust': cust,
          });
        }
        if (data.containsKey('name')) {
          final name = data['name'];
          return Tr.t('notifMsgAddedSystemJson', lang, {'name': name});
        }
      }
    } catch (_) {}

    // Fallback for old notifications
    if (message.contains('running low on stock')) {
      final number = message.split(' ').first;
      return Tr.t('notifMsgLowStockTxt', lang, {'number': number});
    }
    if (message.contains('outstanding debt balances')) {
      final number = message.split(' ').first;
      return Tr.t('notifMsgDebtTxt', lang, {'number': number});
    }
    if (message.contains('submitted successfully')) {
      final match = RegExp(
        r'Order for (.*?) submitted successfully',
      ).firstMatch(message);
      final customer = match != null ? match.group(1) : '';
      return Tr.t('notifMsgOrderSuccessTxt', lang, {
        'customer': _translateWalkIn(customer ?? '', lang),
      });
    }
    if (message.contains('delivered') && message.contains('Order of')) {
      final match = RegExp(
        r'Order of (.*?) for (.*?) delivered',
      ).firstMatch(message);
      if (match != null) {
        final amt = match.group(1)!;
        final cust = _translateWalkIn(match.group(2)!, lang);
        return Tr.t('notifMsgOrderDeliveredTxt', lang, {
          'amt': amt,
          'cust': cust,
        });
      }
    }
    if (message.contains('was rejected')) {
      final match = RegExp(
        r'Order of (.*?) for (.*?) was rejected',
      ).firstMatch(message);
      if (match != null) {
        final amt = match.group(1)!;
        final cust = _translateWalkIn(match.group(2)!, lang);
        return Tr.t('notifMsgOrderRejectedTxt', lang, {
          'amt': amt,
          'cust': cust,
        });
      }
    }
    if (message.contains('added to inventory catalog')) {
      final match = RegExp(
        r'(.*?) added to inventory catalog',
      ).firstMatch(message);
      if (match != null) {
        return Tr.t('notifMsgProductAddedTxt', lang, {
          'product': match.group(1)!,
        });
      }
    }
    if (message.contains('received from')) {
      final parts = message.replaceAll('.', '').split(' received from ');
      if (parts.length == 2) {
        final amt = parts[0];
        final cust = _translateWalkIn(parts[1], lang);
        return Tr.t('notifMsgPaymentReceivedTxt', lang, {
          'amt': amt,
          'cust': cust,
        });
      }
    }

    // Check if DAS is the name of the factory "DAS زیادکرا بۆ سیستم"
    if (message.contains('added to system')) {
      final match = RegExp(r'(.*?) added to system').firstMatch(message);
      if (match != null) {
        return Tr.t('notifMsgAddedSystemJson', lang, {'name': match.group(1)!});
      }
    }

    // "Refunded AMOUNT on Order #ID - CustomerName" (order returns)
    if (message.contains('on Order #') && message.contains('Refunded')) {
      final match = RegExp(
        r'Refunded (.*?) on Order #([a-zA-Z0-9\-]+)(?: - (.*))?',
      ).firstMatch(message);
      if (match != null) {
        final amt = match.group(1)!;
        final id = match.group(2)!;
        final customer = match.group(3);

        if (customer != null && customer.isNotEmpty) {
          return Tr.t('notifMsgReturnProcessedWithCustTxt', lang, {
            'amt': amt,
            'customer': _translateWalkIn(customer, lang),
            'id': id,
          });
        }

        return Tr.t('notifMsgReturnProcessedTxt', lang, {'amt': amt, 'id': id});
      }
    }

    // "Refunded AMOUNT on Purchase #ID" (purchase returns)
    if (message.contains('on Purchase #') && message.contains('Refunded')) {
      final match = RegExp(
        r'Refunded (.*?) on Purchase #([a-zA-Z0-9\-]+)(?: from (.*))?',
      ).firstMatch(message);
      if (match != null) {
        final amt = match.group(1)!;
        final id = match.group(2)!;
        final supplier = match.group(3);

        if (supplier != null && supplier.isNotEmpty) {
          return Tr.t('notifMsgPurchaseReturnWithSupplierTxt', lang, {
            'amt': amt,
            'id': id,
            'supplier': supplier,
          });
        }

        return Tr.t('notifMsgPurchaseReturnTxt', lang, {'amt': amt, 'id': id});
      }
    }

    // "N items purchased for AMOUNT" (purchase saved)
    if (message.contains('items purchased for')) {
      final match = RegExp(
        r'(\d+) items purchased for (.+)',
      ).firstMatch(message);
      if (match != null) {
        return Tr.t('notifMsgPurchaseSavedTxt', lang, {
          'count': match.group(1)!,
          'amt': match.group(2)!,
        });
      }
    }

    return message;
  }
}
