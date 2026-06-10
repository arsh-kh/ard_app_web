import 'dart:convert';
import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/pdf_invoice_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/heavy_ios_button.dart';
import '../../core/utils/order_status_utils.dart';
import '../../core/widgets/pdf_preview_screen.dart';
import '../../core/providers/locale_provider.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import '../../domain/enums.dart';
import '../../core/utils/feedback_utils.dart';
import 'order_report_dialog.dart';
import 'order_return_screen.dart';

// Thin proxy — delegates to Tr which has properly encoded Kurdish & Arabic.
class _LocalTranslations {
  // Expanded message templates (placeholders preserved)
  static const _msgTemplates = {
    'en': {
      'rejectOrderMsg': 'This will cancel order #{orderId} for {client}. This action cannot be undone.',
      'orderRejectedMsg': 'Order #{orderId} for {client} was rejected.',
      'approveOrderMsg': 'Approve order #{orderId} for {client}?\n\nStock will be deducted from inventory.',
      'orderApprovedMsg': 'Order #{orderId} for {client} approved. Stock deducted.',
      'markDeliveredMsg': 'This will mark order #{orderId} as delivered and add {amount} to {client}\'s debt ledger.',
      'orderDeliveredMsg': 'Order #{orderId} delivered. Customer debt ledger updated.',
      'errorGeneratingInvoice': 'Error generating invoice: {error}',
    },
    'ku': {
      'rejectOrderMsg': 'ئەم داواکاری #{orderId} بۆ {client} هەڵدەوەشێنرێتەوە. ئەم کارە ناگەڕێتەوە.',
      'orderRejectedMsg': 'داواکاری #{orderId} بۆ {client} ڕەتکرایەوە.',
      'approveOrderMsg': 'داواکاری #{orderId} بۆ {client} پەسەند دەکەیت؟\n\nکاڵا لە کۆگا کەم دەکرێتەوە.',
      'orderApprovedMsg': 'داواکاری #{orderId} بۆ {client} پەسەندکرا. کاڵا کەمکرایەوە.',
      'markDeliveredMsg': 'ئەم داواکاری #{orderId} وەک گەیەنراو دیاری دەکات و {amount} دەخاتە سەر قەرزی {client}.',
      'orderDeliveredMsg': 'داواکاری #{orderId} گەیەنرا. قەرزی کڕیار نوێکرایەوە.',
      'errorGeneratingInvoice': 'هەڵە لە دروستکردنی پسووڵە: {error}',
    },
    'ar': {
      'rejectOrderTitle': 'رفض الطلب؟',
      'rejectOrderMsg': 'سيؤدي هذا إلى إلغاء الطلب #{orderId} لـ {client}. لا يمكن التراجع عن هذا الإجراء.',
      'orderRejectedTitle': 'تم رفض الطلب',
      'orderRejectedMsg': 'تم رفض الطلب #{orderId} Ù„Ù„عÙ…ÙŠÙ„ {client}.',
      'orderRejectedInfo': 'تم رفض الطلب',
      'approveOrderTitle': 'الموافقة على الطلب؟',
      'approveOrderMsg': 'هل توافق على الطلب #{orderId} لـ {client}؟\n\nسيتم خصم المخزون من المستودع.',
      'orderApprovedTitle': 'تمت الموافقة على الطلب',
      'orderApprovedMsg': 'تمت الموافقة على الطلب #{orderId} Ù„Ù€ {client}. تÙ… خصÙ… اÙ„Ù…خزÙˆÙ†.',
      'orderApprovedSuccess': 'تمت الموافقة على الطلب!',
      'markDeliveredTitle': 'تحديد كمسلم؟',
      'markDeliveredMsg': 'سيؤدي هذا إلى تحديد الطلب #{orderId} كمسلم وإضافة {amount} إلى سجل ديون {client}.',
      'orderDeliveredTitle': 'تم توصيل الطلب',
      'orderDeliveredMsg': 'تم توصيل الطلب #{orderId}. تم تحديث سجل ديون العميل.',
      'orderDeliveredSuccess': 'تم تحديد الطلب كمسلم!',
      'errorGeneratingInvoice': 'خطأ في إنشاء الفاتورة: {error}',
    }
  };

  static String get(String key, String langCode) {
    final langMap = _msgTemplates[langCode] ?? _msgTemplates['en']!;
    return langMap[key] ?? key;
  }
}

class AdminOrdersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const AdminOrdersScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    // Falls back to Tr.t() so ALL translation keys resolve — not just the local message templates.
    String t(String key) {
      final local = _LocalTranslations.get(key, langCode);
      // _LocalTranslations.get() returns the key itself when not found.
      return local == key ? Tr.t(key, langCode) : local;
    }

    final orderRepo = ref.watch(orderRepositoryProvider);
    final ordersStream = orderRepo.watchAllOrders();

    final body = StreamBuilder<List<OrderEntity>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListSkeleton();
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        final pastOrders = allOrders.where((o) => o.status == OrderStatus.delivered.value || o.status == OrderStatus.cancelled.value).toList();

        if (widget.isEmbedded) {
          return _buildOrdersList(context, ref, pastOrders, t('noOrderHistory'), t, isPastOrdersTab: true);
        }

        final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending.value).toList();

        return TabBarView(
          children: [
            _buildOrdersList(context, ref, pendingOrders, t('noActiveOrders'), t, isPastOrdersTab: false),
            _buildOrdersList(context, ref, pastOrders, t('noOrderHistory'), t, isPastOrdersTab: true),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: body,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 96.0),
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const OrderReportDialog(),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            tooltip: t('printInvoice'),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('incomingOrders')),
          bottom: TabBar(
            tabs: [
              Tab(text: t('pendingTab'), icon: const Icon(Icons.access_time, size: 20)),
              Tab(text: t('pastOrdersTab'), icon: const Icon(Icons.history, size: 20)),
            ],
          ),
        ),
        body: body,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => const OrderReportDialog(),
            );
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          tooltip: t('printInvoice'),
          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<OrderEntity> orders,
    String emptyMessage,
    String Function(String) t, {
    required bool isPastOrdersTab,
  }) {
    final langCode = ref.watch(localeProvider).languageCode;

    final reportButton = isPastOrdersTab
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: HeavyIOSButton(
              label: Tr.t('auto_InvoicesReport', langCode),
              icon: Icons.picture_as_pdf_rounded,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const OrderReportDialog(),
                );
              },
            ),
          )
        : const SizedBox.shrink();

    if (orders.isEmpty) {
      return Column(
        children: [
          reportButton,
          Expanded(
            child: AnimatedEmptyState(
              title: emptyMessage,
              icon: Icons.receipt_long_outlined,
            ),
          ),
        ],
      );
    }

    final customerRepo = ref.read(customerRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);

    return ListView.builder(
      itemCount: orders.length,
      padding: EdgeInsets.only(top: 4, bottom: widget.isEmbedded ? 120 : 100),
      itemBuilder: (context, index) {
        final order = orders[index];

        return FutureBuilder<CustomerEntity?>(
          future: customerRepo.getCustomerById(order.customerId),
          builder: (context, customerSnapshot) {
            final customer = customerSnapshot.data;
            final customerName = customer?.businessName ?? t('loadingClient');

            final isWalkIn = order.customerId == 'walk-in' || order.customerId == 'walk-in-customer-id';
            final displayName = isWalkIn ? '🛒 Walk-In (POS)' : '👤 $customerName';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade200,
                ),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: OrderStatusUtils.getStatusColor(order.status).withValues(alpha: 0.1),
                  child: Icon(OrderStatusUtils.getStatusIcon(order.status), color: OrderStatusUtils.getStatusColor(order.status), size: 20),
                ),
                title: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📦 Order #${order.orderNumber ?? "..."}  •  ⏳ ${DateFormat('MMM d, HH:mm').format(order.orderDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      OrderStatusUtils.buildStatusBadge(order.status),
                    ],
                  ),
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: order.hasReturn ? 12 : 16,
                        decoration: order.hasReturn ? TextDecoration.lineThrough : null,
                        color: order.hasReturn ? Colors.grey : null,
                      ),
                    ),
                    if (order.hasReturn)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          CurrencyFormatter.format(order.totalAmount - order.totalReturnedAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orange),
                        ),
                      ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        // Header info
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer?.address ?? t('noAddress'),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Order items list title
                        Text(
                          t('orderedProducts'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        // Fetching line items dynamically
                        FutureBuilder<List<OrderItemEntity>>(
                          future: orderRepo.getOrderItems(order.id),
                          builder: (context, itemsSnapshot) {
                            if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final items = itemsSnapshot.data ?? [];
                            return Column(
                              children: items.map((item) {
                                return FutureBuilder<ProductEntity?>(
                                  future: inventoryRepo.getProductById(item.productId),
                                  builder: (context, prodSnapshot) {
                                    final prodName = prodSnapshot.data?.name ?? t('unknownProduct');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$prodName x ${item.quantity.toInt()} ${langCode == 'ku' ? ((prodSnapshot.data?.unitType ?? "") == 'bag' ? 'فەردە' : (prodSnapshot.data?.unitType ?? "") == 'kg' ? 'کیلۆگرام' : (prodSnapshot.data?.unitType ?? "") == 'ton' ? 'تۆن' : (prodSnapshot.data?.unitType ?? "") == 'box' ? 'کارتۆن' : (prodSnapshot.data?.unitType ?? "")) : langCode == 'ar' ? ((prodSnapshot.data?.unitType ?? "") == 'bag' ? 'كيس' : (prodSnapshot.data?.unitType ?? "") == 'kg' ? 'كيلوغرام' : (prodSnapshot.data?.unitType ?? "") == 'ton' ? 'طن' : (prodSnapshot.data?.unitType ?? "") == 'box' ? 'صندوق' : (prodSnapshot.data?.unitType ?? "")) : (prodSnapshot.data?.unitType ?? "")}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    decoration: item.returnedQuantity > 0 ? TextDecoration.lineThrough : null,
                                                    color: item.returnedQuantity > 0 ? Colors.grey : null,
                                                  ),
                                                ),
                                                if (item.returnedQuantity > 0)
                                                  Text(
                                                    '↩️ ${item.returnedQuantity.toInt()} $prodName',
                                                    style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                CurrencyFormatter.format(item.quantity * item.unitPrice),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600, 
                                                  fontSize: item.returnedQuantity > 0 ? 11 : 13,
                                                  decoration: item.returnedQuantity > 0 ? TextDecoration.lineThrough : null,
                                                  color: item.returnedQuantity > 0 ? Colors.grey : null,
                                                ),
                                              ),
                                              if (item.returnedQuantity > 0)
                                                Text(
                                                  CurrencyFormatter.format((item.quantity - item.returnedQuantity) * item.unitPrice),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Actions Bar
                        if (order.status == OrderStatus.pending.value) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  onPressed: () async {
                                    final confirmed = await AppFeedback.showConfirmDialog(
                                      context,
                                      title: t('rejectOrderTitle'),
                                      message: t('rejectOrderMsg')
                                          .replaceFirst('{orderId}', order.id.substring(0, 8).toUpperCase())
                                          .replaceFirst('{client}', customerName),
                                      confirmLabel: t('reject'),
                                      confirmColor: Colors.red,
                                      icon: Icons.cancel_outlined,
                                    );
                                    if (!confirmed) return;
                                    await orderRepo.updateOrderStatus(order.id, OrderStatus.cancelled.value);
                                    await ref.read(notificationProvider.notifier).addNotification(
                                      title: 'order_rejected',
                                      message: jsonEncode({'id': order.orderNumber?.toString() ?? order.id.substring(0, 8).toUpperCase(), 'customer': customerName}),
                                      type: 'order',
                                    );
                                    if (context.mounted) AppFeedback.showInfo(context, t('orderRejectedInfo'));
                                  },
                                  child: Text(t('reject')),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final confirmed = await AppFeedback.showConfirmDialog(
                                      context,
                                      title: t('markDeliveredTitle'),
                                      message: t('markDeliveredMsg')
                                          .replaceFirst('{orderId}', order.id.substring(0, 8).toUpperCase())
                                          .replaceFirst('{amount}', CurrencyFormatter.format(order.totalAmount))
                                          .replaceFirst('{client}', customerName),
                                      confirmLabel: t('markDelivered'),
                                      confirmColor: Colors.green,
                                      icon: Icons.local_shipping,
                                    );
                                    if (!confirmed) return;
                                    await orderRepo.markOrderDelivered(order.id);
                                    
                                    await ref.read(notificationProvider.notifier).addNotification(
                                      title: 'order_delivered',
                                      message: jsonEncode({'id': order.orderNumber?.toString() ?? order.id.substring(0, 8).toUpperCase(), 'customer': customerName}),
                                      type: 'order',
                                    );
                                    if (context.mounted) AppFeedback.showSuccess(context, t('orderDeliveredSuccess'));
                                  },
                                  child: Text(t('markDelivered')),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order.status == OrderStatus.delivered.value || order.status == OrderStatus.cancelled.value) ...[
                          // ── Delivered: Invoice / Return / Delete ──────
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                                  onPressed: () => _printInvoice(context, ref, order, t),
                                  label: Text(
                                    t('printInvoice'),
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              if (order.status == OrderStatus.delivered.value) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                    ),
                                    icon: const Icon(Icons.replay_rounded, size: 16),
                                    label: Text(Tr.t('processReturn', langCode), style: const TextStyle(fontSize: 12)),
                                    onPressed: () async {
                                      // Load all needed data before opening screen
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (_) => const Center(child: CircularProgressIndicator()),
                                      );
                                      try {
                                        final items = await orderRepo.getOrderItems(order.id);
                                        final products = await inventoryRepo.getAllProducts();
                                        final customer = await customerRepo.getCustomerById(order.customerId);
                                        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                        if (context.mounted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => OrderReturnScreen(
                                                order: order,
                                                items: items,
                                                customer: customer,
                                                products: products,
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
                                        if (context.mounted) AppFeedback.showError(context, 'Error: $e');
                                      }
                                    },
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  onPressed: () async {
                                    final confirmed = await AppFeedback.showConfirmDialog(
                                      context,
                                      title: Tr.t('deleteOrder', langCode),
                                      message: Tr.t('deleteOrderMsg', langCode),
                                      confirmLabel: Tr.t('deleteBtn', langCode),
                                      confirmColor: Colors.red,
                                      icon: Icons.warning,
                                    );
                                    if (confirmed) {
                                      await orderRepo.deleteOrder(order.id);
                                    }
                                  },
                                  label: Text(Tr.t('deleteBtn', langCode), style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  )
                ],
              ),
            ).animate().fade(duration: 200.ms).slideY(begin: 0.05, end: 0);
          },
        );
      },
    );
  }

  Future<void> _printInvoice(BuildContext context, WidgetRef ref, OrderEntity order, String Function(String) t) async {
    bool isDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);

      final customer = await customerRepo.getCustomerById(order.customerId);
      final items = await orderRepo.getOrderItems(order.id);
      final products = await inventoryRepo.getAllProducts();

      // Dismiss loading dialog safely
      if (context.mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }
      
      if (customer == null) throw Exception('Customer not found');

      final currentLocale = ref.read(localeProvider);
      final authState = ref.read(authProvider);
      final adminPhone = authState.user?.phone;
      final pdfBytes = await PdfInvoiceService.generateInvoice(
        order: order,
        customer: customer,
        items: items,
        products: products,
        isKurdish: currentLocale.languageCode == 'ku',
        isArabic: currentLocale.languageCode == 'ar',
        adminPhone: adminPhone,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(
              title: 'Invoice_${order.orderNumber?.toString() ?? order.id.substring(0, 8)}',
              pdfBytes: pdfBytes,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }
      if (context.mounted) {
        AppFeedback.showError(context, t('errorGeneratingInvoice').replaceFirst('{error}', e.toString()));
      }
    }
  }

  // Status helpers now live in OrderStatusUtils (core/utils/order_status_utils.dart)
}


