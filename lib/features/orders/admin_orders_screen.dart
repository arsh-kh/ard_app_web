import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/services/pdf_invoice_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/order_status_utils.dart';
import '../../core/widgets/pdf_preview_screen.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import '../../domain/enums.dart';
import '../../core/widgets/heavy_ios_button.dart';
import 'order_report_dialog.dart';

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
      'printInvoice': 'Export PDF',
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
      'incomingOrders': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ• Ù‡Ø§ØªÙˆÙˆÛ•Ú©Ø§Ù†',
      'pendingTab': 'Ú†Ø§ÙˆÛ•Ú•ÛŽÚ©Ø±Ø§Ùˆ',
      'pastOrdersTab': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ•Ú©Ø§Ù†ÛŒ Ù¾ÛŽØ´ÙˆÙˆ',
      'noActiveOrders': 'Ù‡ÛŒÚ† Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ•Ú©ÛŒ Ú†Ø§ÙˆÛ•Ú•ÛŽÚ©Ø±Ø§Ùˆ Ù†ÛŒÛŒÛ•.',
      'noOrderHistory': 'Ù‡ÛŒÚ† Ù…ÛŽÚ˜ÙˆÙˆÛŒÛ•Ú©ÛŒ Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ù†Û•Ø¯Û†Ø²Ø±Ø§ÛŒÛ•ÙˆÛ•.',
      'loadingClient': 'Ø¨Ø§Ø±Ú©Ø±Ø¯Ù†ÛŒ Ú©Ú•ÛŒØ§Ø±...',
      'orderNo': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #',
      'noAddress': 'Ù‡ÛŒÚ† Ù†Ø§ÙˆÙ†ÛŒØ´Ø§Ù†ÛŽÚ© ØªÛ†Ù…Ø§Ø±Ù†Û•Ú©Ø±Ø§ÙˆÛ•',
      'orderedProducts': 'Ø¨Û•Ø±Ù‡Û•Ù…Û• Ø¯Ø§ÙˆØ§Ú©Ø±Ø§ÙˆÛ•Ú©Ø§Ù†:',
      'unknownProduct': 'Ú©Ø§ÚµØ§ÛŒ Ù†Û•Ù†Ø§Ø³Ø±Ø§Ùˆ',
      'reject': 'Ú•Û•ØªÚ©Ø±Ø¯Ù†Û•ÙˆÛ•',
      'approve': 'Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø¯Ù†',
      'markDelivered': 'Ú¯Û•ÛŒÛ•Ù†Ø±Ø§',
      'printInvoice': 'Ù‡Û•Ù†Ø§Ø±Ø¯Û•Ú©Ø±Ø¯Ù†ÛŒ PDF',
      'rejectOrderTitle': 'Ú•Û•ØªÚ©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒØŸ',
      'rejectOrderMsg': 'Ø¦Û•Ù…Û• Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} Ø¨Û† {client} Ù‡Û•ÚµØ¯Û•ÙˆÛ•Ø´ÛŽÙ†ÛŽØªÛ•ÙˆÛ•. Ø¦Û•Ù…Û• Ù†Ø§ØªÙˆØ§Ù†Ø±ÛŽØª Ø¨Ú¯Û•Ú•ÛŽÙ†Ø¯Ø±ÛŽØªÛ•ÙˆÛ•.',
      'orderRejectedTitle': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ú•Û•ØªÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•',
      'orderRejectedMsg': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} Ø¨Û† {client} Ú•Û•ØªÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•.',
      'orderRejectedInfo': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ú•Û•ØªÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•',
      'approveOrderTitle': 'Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø¯Ù†ÛŒ Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒØŸ',
      'approveOrderMsg': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} Ø¨Û† {client} Ù¾Û•Ø³Û•Ù†Ø¯ Ø¯Û•Ú©Û•ÛŒØªØŸ\n\nÚ©Ø§ÚµØ§ Ù„Û• Ú©Û†Ú¯Ø§ Ú©Û•Ù… Ø¯Û•Ú©Ø±ÛŽØªÛ•ÙˆÛ•.',
      'orderApprovedTitle': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø§',
      'orderApprovedMsg': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} Ø¨Û† {client} Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø§. Ú©Ø§ÚµØ§ Ú©Û•Ù…Ú©Ø±Ø§ÛŒÛ•ÙˆÛ•.',
      'orderApprovedSuccess': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø§!',
      'markDeliveredTitle': 'ÙˆÛ•Ú© Ú¯Û•ÛŒÛ•Ù†Ø±Ø§Ùˆ Ø¯ÛŒØ§Ø±ÛŒ Ø¨Ú©Û•ØŸ',
      'markDeliveredMsg': 'Ø¦Û•Ù…Û• Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} ÙˆÛ•Ú© Ú¯Û•ÛŒÛ•Ù†Ø±Ø§Ùˆ Ø¯ÛŒØ§Ø±ÛŒ Ø¯Û•Ú©Ø§Øª Ùˆ Ø¨Ú•ÛŒ {amount} Ø¯Û•Ø®Ø§ØªÛ• Ø³Û•Ø± Ù‚Û•Ø±Ø²ÛŒ {client}.',
      'orderDeliveredTitle': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ú¯Û•ÛŒÛ•Ù†Ø±Ø§',
      'orderDeliveredMsg': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ #{orderId} Ú¯Û•ÛŒÛ•Ù†Ø±Ø§. Ù‚Û•Ø±Ø²ÛŒ Ú©Ú•ÛŒØ§Ø± Ù†ÙˆÛŽÚ©Ø±Ø§ÛŒÛ•ÙˆÛ•.',
      'orderDeliveredSuccess': 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ ÙˆÛ•Ú© Ú¯Û•ÛŒÛ•Ù†Ø±Ø§Ùˆ Ø¯ÛŒØ§Ø±ÛŒÚ©Ø±Ø§!',
      'errorGeneratingInvoice': 'Ù‡Û•ÚµÛ• Ù„Û• Ø¯Ø±ÙˆØ³ØªÚ©Ø±Ø¯Ù†ÛŒ Ù¾Ø³ÙˆÙˆÚµÛ•: {error}',
    },
    'ar': {
      'incomingOrders': 'Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„ÙˆØ§Ø±Ø¯Ø©',
      'pendingTab': 'Ù‚ÙŠØ¯ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø±',
      'pastOrdersTab': 'Ø§Ù„Ø·Ù„Ø¨Ø§Øª Ø§Ù„Ø³Ø§Ø¨Ù‚Ø©',
      'noActiveOrders': 'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø·Ù„Ø¨Ø§Øª Ù‚ÙŠØ¯ Ø§Ù„Ø§Ù†ØªØ¸Ø§Ø±.',
      'noOrderHistory': 'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ø³Ø¬Ù„ Ø·Ù„Ø¨Ø§Øª.',
      'loadingClient': 'Ø¬Ø§Ø±ÙŠ ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¹Ù…ÙŠÙ„...',
      'orderNo': 'Ø·Ù„Ø¨ #',
      'noAddress': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø¹Ù†ÙˆØ§Ù† Ù…Ø³Ø¬Ù„',
      'orderedProducts': 'Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª Ø§Ù„Ù…Ø·Ù„ÙˆØ¨Ø©:',
      'unknownProduct': 'Ù…Ù†ØªØ¬ ØºÙŠØ± Ù…Ø¹Ø±ÙˆÙ',
      'reject': 'Ø±ÙØ¶',
      'approve': 'Ù…ÙˆØ§ÙÙ‚Ø©',
      'markDelivered': 'ØªÙ… Ø§Ù„ØªÙˆØµÙŠÙ„',
      'printInvoice': 'ØªØµØ¯ÙŠØ± PDF',
      'rejectOrderTitle': 'Ø±ÙØ¶ Ø§Ù„Ø·Ù„Ø¨ØŸ',
      'rejectOrderMsg': 'Ø³ÙŠØ¤Ø¯ÙŠ Ù‡Ø°Ø§ Ø¥Ù„Ù‰ Ø¥Ù„ØºØ§Ø¡ Ø§Ù„Ø·Ù„Ø¨ #{orderId} Ù„Ù€ {client}. Ù„Ø§ ÙŠÙ…ÙƒÙ† Ø§Ù„ØªØ±Ø§Ø¬Ø¹ Ø¹Ù† Ù‡Ø°Ø§ Ø§Ù„Ø¥Ø¬Ø±Ø§Ø¡.',
      'orderRejectedTitle': 'ØªÙ… Ø±ÙØ¶ Ø§Ù„Ø·Ù„Ø¨',
      'orderRejectedMsg': 'ØªÙ… Ø±ÙØ¶ Ø§Ù„Ø·Ù„Ø¨ #{orderId} Ù„Ù„Ø¹Ù…ÙŠÙ„ {client}.',
      'orderRejectedInfo': 'ØªÙ… Ø±ÙØ¶ Ø§Ù„Ø·Ù„Ø¨',
      'approveOrderTitle': 'Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø·Ù„Ø¨ØŸ',
      'approveOrderMsg': 'Ù‡Ù„ ØªÙˆØ§ÙÙ‚ Ø¹Ù„Ù‰ Ø§Ù„Ø·Ù„Ø¨ #{orderId} Ù„Ù€ {client}ØŸ\n\nØ³ÙŠØªÙ… Ø®ØµÙ… Ø§Ù„Ù…Ø®Ø²ÙˆÙ† Ù…Ù† Ø§Ù„Ù…Ø³ØªÙˆØ¯Ø¹.',
      'orderApprovedTitle': 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø·Ù„Ø¨',
      'orderApprovedMsg': 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø·Ù„Ø¨ #{orderId} Ù„Ù€ {client}. ØªÙ… Ø®ØµÙ… Ø§Ù„Ù…Ø®Ø²ÙˆÙ†.',
      'orderApprovedSuccess': 'ØªÙ…Øª Ø§Ù„Ù…ÙˆØ§ÙÙ‚Ø© Ø¹Ù„Ù‰ Ø§Ù„Ø·Ù„Ø¨!',
      'markDeliveredTitle': 'ØªØ­Ø¯ÙŠØ¯ ÙƒÙ…Ø³Ù„Ù…ØŸ',
      'markDeliveredMsg': 'Ø³ÙŠØ¤Ø¯ÙŠ Ù‡Ø°Ø§ Ø¥Ù„Ù‰ ØªØ­Ø¯ÙŠØ¯ Ø§Ù„Ø·Ù„Ø¨ #{orderId} ÙƒÙ…Ø³Ù„Ù… ÙˆØ¥Ø¶Ø§ÙØ© {amount} Ø¥Ù„Ù‰ Ø³Ø¬Ù„ Ø¯ÙŠÙˆÙ† {client}.',
      'orderDeliveredTitle': 'ØªÙ… ØªÙˆØµÙŠÙ„ Ø§Ù„Ø·Ù„Ø¨',
      'orderDeliveredMsg': 'ØªÙ… ØªÙˆØµÙŠÙ„ Ø§Ù„Ø·Ù„Ø¨ #{orderId}. ØªÙ… ØªØ­Ø¯ÙŠØ« Ø³Ø¬Ù„ Ø¯ÙŠÙˆÙ† Ø§Ù„Ø¹Ù…ÙŠÙ„.',
      'orderDeliveredSuccess': 'ØªÙ… ØªØ­Ø¯ÙŠØ¯ Ø§Ù„Ø·Ù„Ø¨ ÙƒÙ…Ø³Ù„Ù…!',
      'errorGeneratingInvoice': 'Ø®Ø·Ø£ ÙÙŠ Ø¥Ù†Ø´Ø§Ø¡ Ø§Ù„ÙØ§ØªÙˆØ±Ø©: {error}',
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
          return const Center(child: CustomLoader());
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
    final isKurdish = langCode == 'ku';
    final isArabic = langCode == 'ar';

    final reportButton = isPastOrdersTab
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: HeavyIOSButton(
              label: isKurdish ? 'Ú•Ø§Ù¾Û†Ø±ØªÛŒ Ù¾Ø³ÙˆÙˆÚµÛ•Ú©Ø§Ù†' : isArabic ? 'ØªÙ‚Ø±ÙŠØ± Ø§Ù„ÙÙˆØ§ØªÙŠØ±' : 'Invoices Report',
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
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
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  '${t('orderNo')}${order.orderNumber ?? "..."} â€¢ ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}',
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
                              return const Center(child: CustomLoader());
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
                                          Text(
                                            '$prodName x ${item.quantity.toInt()} ${langCode == 'ku' ? ((prodSnapshot.data?.unitType ?? "") == 'bag' ? 'ÙÛ•Ø±Ø¯Û•' : (prodSnapshot.data?.unitType ?? "") == 'kg' ? 'Ú©ÛŒÙ„Û†Ú¯Ø±Ø§Ù…' : (prodSnapshot.data?.unitType ?? "") == 'ton' ? 'ØªÛ†Ù†' : (prodSnapshot.data?.unitType ?? "") == 'box' ? 'Ú©Ø§Ø±ØªÛ†Ù†' : (prodSnapshot.data?.unitType ?? "")) : langCode == 'ar' ? ((prodSnapshot.data?.unitType ?? "") == 'bag' ? 'ÙƒÙŠØ³' : (prodSnapshot.data?.unitType ?? "") == 'kg' ? 'ÙƒÙŠÙ„ÙˆØºØ±Ø§Ù…' : (prodSnapshot.data?.unitType ?? "") == 'ton' ? 'Ø·Ù†' : (prodSnapshot.data?.unitType ?? "") == 'box' ? 'ØµÙ†Ø¯ÙˆÙ‚' : (prodSnapshot.data?.unitType ?? "")) : (prodSnapshot.data?.unitType ?? "")}',
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
                                  icon: const Icon(Icons.picture_as_pdf),
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
                                      title: ref.read(localeProvider).languageCode == 'ku' ? 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ' : ref.read(localeProvider).languageCode == 'ar' ? 'Ø­Ø°Ù Ø§Ù„Ø·Ù„Ø¨' : 'Delete Order',
                                      message: ref.read(localeProvider).languageCode == 'ku' ? 'Ø¯ÚµÙ†ÛŒØ§ÛŒØª Ø¯Û•ØªÛ•ÙˆÛŽØª Ø¦Û•Ù… Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ• Ø¨Ø³Ú•ÛŒØªÛ•ÙˆÛ•ØŸ' : ref.read(localeProvider).languageCode == 'ar' ? 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ø£Ù†Ùƒ ØªØ±ÙŠØ¯ Ø­Ø°Ù Ù‡Ø°Ø§ Ø§Ù„Ø·Ù„Ø¨ ØªÙ…Ø§Ù…Ù‹Ø§ØŸ' : 'Are you sure you want to completely delete this order?',
                                      confirmLabel: ref.read(localeProvider).languageCode == 'ku' ? 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•' : ref.read(localeProvider).languageCode == 'ar' ? 'Ø­Ø°Ù' : 'Delete',
                                      confirmColor: Colors.red,
                                      icon: Icons.warning,
                                    );
                                    if (confirmed) {
                                      await orderRepo.deleteOrder(order.id);
                                    }
                                  },
                                  label: Text(ref.read(localeProvider).languageCode == 'ku' ? 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•' : ref.read(localeProvider).languageCode == 'ar' ? 'Ø­Ø°Ù' : 'Delete'),
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
      builder: (_) => const Center(child: CustomLoader()),
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
      final pdfBytes = await PdfInvoiceService.generateInvoice(
        order: order,
        customer: customer,
        items: items,
        products: products,
        isKurdish: currentLocale.languageCode == 'ku',
        isArabic: currentLocale.languageCode == 'ar',
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(
              title: 'Invoice_${order.id.substring(0, 8)}',
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


