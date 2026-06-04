import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/services/pdf_invoice_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/order_status_utils.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local_database/database.dart';
import '../../domain/enums.dart' hide SyncStatus;

class _LocalTranslations {
  static const _data = {
    'en': {
      'incomingOrders': 'Incoming Orders',
      'pendingTab': 'Pending',
      'pastOrdersTab': 'Past Orders',
      'noActiveOrders': 'No active pending orders.',
      'noOrderHistory': 'No order history found.',
      'loadingClient': 'Loading Client...',
      'orderNo': 'Order #',
      'noAddress': 'No address registered',
      'orderedProducts': 'Ordered Products:',
      'unknownProduct': 'Unknown Product',
      'reject': 'Reject',
      'approve': 'Approve',
      'markDelivered': 'Mark Delivered',
      'printInvoice': 'Print Invoice',
      'rejectOrderTitle': 'Reject Order?',
      'rejectOrderMsg': 'This will cancel order #{orderId} for {client}. This action cannot be undone.',
      'orderRejectedTitle': 'Order Rejected',
      'orderRejectedMsg': 'Order #{orderId} for {client} was rejected.',
      'orderRejectedInfo': 'Order rejected',
      'approveOrderTitle': 'Approve Order?',
      'approveOrderMsg': 'Approve order #{orderId} for {client}?\n\nStock will be deducted from inventory.',
      'orderApprovedTitle': 'Order Approved',
      'orderApprovedMsg': 'Order #{orderId} for {client} approved. Stock deducted.',
      'orderApprovedSuccess': 'Order approved!',
      'markDeliveredTitle': 'Mark as Delivered?',
      'markDeliveredMsg': 'This will mark order #{orderId} as delivered and add {amount} to {client}\'s debt ledger.',
      'orderDeliveredTitle': 'Order Delivered',
      'orderDeliveredMsg': 'Order #{orderId} delivered. Customer debt ledger updated.',
      'orderDeliveredSuccess': 'Order marked as delivered!',
      'errorGeneratingInvoice': 'Error generating invoice: {error}',
    },
    'ku': {
      'incomingOrders': 'داواکارییە هاتووەکان',
      'pendingTab': 'چاوەڕێکراو',
      'pastOrdersTab': 'داواکارییەکانی پێشوو',
      'noActiveOrders': 'هیچ داواکارییەکی چاوەڕێکراو نییە.',
      'noOrderHistory': 'هیچ مێژوویەکی داواکاری نەدۆزرایەوە.',
      'loadingClient': 'بارکردنی کڕیار...',
      'orderNo': 'داواکاری #',
      'noAddress': 'هیچ ناونیشانێک تۆمارنەکراوە',
      'orderedProducts': 'بەرهەمە داواکراوەکان:',
      'unknownProduct': 'کاڵای نەناسراو',
      'reject': 'ڕەتکردنەوە',
      'approve': 'پەسەندکردن',
      'markDelivered': 'گەیەنرا',
      'printInvoice': 'چاپکردنی پسووڵە',
      'rejectOrderTitle': 'ڕەتکردنەوەی داواکاری؟',
      'rejectOrderMsg': 'ئەمە داواکاری #{orderId} بۆ {client} هەڵدەوەشێنێتەوە. ئەمە ناتوانرێت بگەڕێندرێتەوە.',
      'orderRejectedTitle': 'داواکاری ڕەتکرایەوە',
      'orderRejectedMsg': 'داواکاری #{orderId} بۆ {client} ڕەتکرایەوە.',
      'orderRejectedInfo': 'داواکاری ڕەتکرایەوە',
      'approveOrderTitle': 'پەسەندکردنی داواکاری؟',
      'approveOrderMsg': 'داواکاری #{orderId} بۆ {client} پەسەند دەکەیت؟\n\nکاڵا لە کۆگا کەم دەکرێتەوە.',
      'orderApprovedTitle': 'داواکاری پەسەندکرا',
      'orderApprovedMsg': 'داواکاری #{orderId} بۆ {client} پەسەندکرا. کاڵا کەمکرایەوە.',
      'orderApprovedSuccess': 'داواکاری پەسەندکرا!',
      'markDeliveredTitle': 'وەک گەیەنراو دیاری بکە؟',
      'markDeliveredMsg': 'ئەمە داواکاری #{orderId} وەک گەیەنراو دیاری دەکات و بڕی {amount} دەخاتە سەر قەرزی {client}.',
      'orderDeliveredTitle': 'داواکاری گەیەنرا',
      'orderDeliveredMsg': 'داواکاری #{orderId} گەیەنرا. قەرزی کڕیار نوێکرایەوە.',
      'orderDeliveredSuccess': 'داواکاری وەک گەیەنراو دیاریکرا!',
      'errorGeneratingInvoice': 'هەڵە لە دروستکردنی پسووڵە: {error}',
    },
    'ar': {
      'incomingOrders': 'الطلبات الواردة',
      'pendingTab': 'قيد الانتظار',
      'pastOrdersTab': 'الطلبات السابقة',
      'noActiveOrders': 'لا توجد طلبات قيد الانتظار.',
      'noOrderHistory': 'لم يتم العثور على سجل طلبات.',
      'loadingClient': 'جاري تحميل العميل...',
      'orderNo': 'طلب #',
      'noAddress': 'لا يوجد عنوان مسجل',
      'orderedProducts': 'المنتجات المطلوبة:',
      'unknownProduct': 'منتج غير معروف',
      'reject': 'رفض',
      'approve': 'موافقة',
      'markDelivered': 'تم التوصيل',
      'printInvoice': 'طباعة الفاتورة',
      'rejectOrderTitle': 'رفض الطلب؟',
      'rejectOrderMsg': 'سيؤدي هذا إلى إلغاء الطلب #{orderId} لـ {client}. لا يمكن التراجع عن هذا الإجراء.',
      'orderRejectedTitle': 'تم رفض الطلب',
      'orderRejectedMsg': 'تم رفض الطلب #{orderId} للعميل {client}.',
      'orderRejectedInfo': 'تم رفض الطلب',
      'approveOrderTitle': 'الموافقة على الطلب؟',
      'approveOrderMsg': 'هل توافق على الطلب #{orderId} لـ {client}؟\n\nسيتم خصم المخزون من المستودع.',
      'orderApprovedTitle': 'تمت الموافقة على الطلب',
      'orderApprovedMsg': 'تمت الموافقة على الطلب #{orderId} لـ {client}. تم خصم المخزون.',
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
    final langMap = _data[langCode] ?? _data['en']!;
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
    String t(String key) => _LocalTranslations.get(key, langCode);

    final orderRepo = ref.watch(orderRepositoryProvider);
    final ordersStream = orderRepo.watchAllOrders();

    final body = StreamBuilder<List<OrderEntity>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allOrders = snapshot.data ?? [];
        final pastOrders = allOrders.where((o) => o.status == OrderStatus.delivered.value || o.status == OrderStatus.cancelled.value).toList();

        if (widget.isEmbedded) {
          return _buildOrdersList(context, ref, pastOrders, t('noOrderHistory'), t);
        }

        final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending.value).toList();

        return TabBarView(
          children: [
            _buildOrdersList(context, ref, pendingOrders, t('noActiveOrders'), t),
            _buildOrdersList(context, ref, pastOrders, t('noOrderHistory'), t),
          ],
        );
      },
    );

    if (widget.isEmbedded) {
      return body;
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
      ),
    );
  }

  Widget _buildOrdersList(
    BuildContext context,
    WidgetRef ref,
    List<OrderEntity> orders,
    String emptyMessage,
    String Function(String) t,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final customerRepo = ref.read(customerRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);

    return ListView.builder(
      itemCount: orders.length,
      padding: EdgeInsets.only(top: 12, bottom: widget.isEmbedded ? 120 : 24),
      itemBuilder: (context, index) {
        final order = orders[index];

        return FutureBuilder<CustomerEntity?>(
          future: customerRepo.getCustomer(order.customerId),
          builder: (context, customerSnapshot) {
            final customer = customerSnapshot.data;
            final customerName = customer?.businessName ?? t('loadingClient');

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade200,
                ),
              ),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: OrderStatusUtils.getStatusColor(order.status).withOpacity(0.1),
                  child: Icon(OrderStatusUtils.getStatusIcon(order.status), color: OrderStatusUtils.getStatusColor(order.status), size: 20),
                ),
                title: Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  '${t('orderNo')}${order.orderNumber ?? "..."} • ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    OrderStatusUtils.buildStatusBadge(order.status),
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
                              return const Center(child: LinearProgressIndicator());
                            }
                            final items = itemsSnapshot.data ?? [];
                            return Column(
                              children: items.map((item) {
                                return FutureBuilder<ProductEntity?>(
                                  future: inventoryRepo.getProduct(item.productId),
                                  builder: (context, prodSnapshot) {
                                    final prodName = prodSnapshot.data?.name ?? t('unknownProduct');
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$prodName x ${item.quantity.toInt()} ${prodSnapshot.data?.unitType ?? ""}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                          Text(
                                            CurrencyFormatter.format(item.quantity * item.unitPrice),
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                                      title: '${AppConstants.appName} - Order Rejected',
                                      message: 'Order #${order.id.substring(0, 8).toUpperCase()} for $customerName was rejected.',
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
                                      title: '${AppConstants.appName} - Order Delivered',
                                      message: 'Order #${order.id.substring(0, 8).toUpperCase()} delivered. Customer debt ledger updated.',
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
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.print),
                                  onPressed: () => _printInvoice(context, ref, order, t),
                                  label: Text(t('printInvoice')),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final confirmed = await AppFeedback.showConfirmDialog(
                                      context,
                                      title: 'Delete Order',
                                      message: 'Are you sure you want to completely delete this order?',
                                      confirmLabel: 'Delete',
                                      confirmColor: Colors.red,
                                      icon: Icons.warning,
                                    );
                                    if (confirmed) {
                                      await orderRepo.deleteOrder(order.id);
                                    }
                                  },
                                  label: const Text('Delete'),
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

      final customer = await customerRepo.getCustomer(order.customerId);
      final items = await orderRepo.getOrderItems(order.id);
      final products = await inventoryRepo.getAllProducts();

      // Dismiss loading dialog safely
      if (context.mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }
      
      if (customer == null) throw Exception('Customer not found');

      final pdfBytes = await PdfInvoiceService.generateInvoice(
        order: order,
        customer: customer,
        items: items,
        products: products,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Invoice_${order.id.substring(0, 8)}.pdf',
      );
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
