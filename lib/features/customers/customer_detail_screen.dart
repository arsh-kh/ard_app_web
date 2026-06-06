import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/order_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/order_status_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/payment_entity.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/payment_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/notification_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final CustomerEntity customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final orderRepo = ref.watch(orderRepositoryProvider);
    final langCode = ref.watch(localeProvider).languageCode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Stylish App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Avatar
                      Hero(
                        tag: 'customer_${customer.id}',
                        child: InitialsAvatar(
                          text: customer.businessName,
                          imageUrl: customer.imageUrl,
                          radius: 36,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.businessName,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.address != null && customer.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on, size: 14, color: theme.colorScheme.onPrimary.withValues(alpha: 0.7)),
                              const SizedBox(width: 4),
                              Text(
                                customer.address!,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                                  fontSize: 12,
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
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onPrimary),
                onPressed: () {
                  context.push(Routes.customerForm, extra: customer);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.onPrimary),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(langCode == 'ku' ? 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ú©Ú•ÛŒØ§Ø±' : langCode == 'ar' ? 'Ø­Ø°Ù Ø§Ù„Ø¹Ù…ÙŠÙ„' : 'Delete Customer'),
                      content: Text(langCode == 'ku' ? 'Ø¯ÚµÙ†ÛŒØ§ÛŒ Ù„Û• Ø³Ú•ÛŒÙ†Û•ÙˆÛ•ÛŒ Ø¦Û•Ù… Ú©Ú•ÛŒØ§Ø±Û•ØŸ' : langCode == 'ar' ? 'Ù‡Ù„ Ø£Ù†Øª Ù…ØªØ£ÙƒØ¯ Ù…Ù† Ø­Ø°Ù Ù‡Ø°Ø§ Ø§Ù„Ø¹Ù…ÙŠÙ„ØŸ' : 'Are you sure you want to delete this customer?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(langCode == 'ku' ? 'Ù†Û•Ø®ÛŽØ±' : langCode == 'ar' ? 'Ù„Ø§' : 'Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(langCode == 'ku' ? 'Ø³Ú•ÛŒÙ†Û•ÙˆÛ•' : langCode == 'ar' ? 'Ø­Ø°Ù' : 'Delete', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(customerRepositoryProvider).deleteCustomer(customer.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),

          // Quick Actions Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.phone_outlined,
                      label: langCode == 'ku' ? 'Ù¾Û•ÛŒÙˆÛ•Ù†Ø¯ÛŒÚ©Ø±Ø¯Ù†' : langCode == 'ar' ? 'Ø§ØªØµØ§Ù„' : 'Call',
                      color: Colors.green,
                      onTap: () => _callCustomer(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.edit_note,
                      label: langCode == 'ku' ? 'Ú¯Û†Ú•ÛŒÙ†ÛŒ Ù¾Ú•Û†ÙØ§ÛŒÙ„' : langCode == 'ar' ? 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ù…Ù„Ù' : 'Edit Profile',
                      color: theme.colorScheme.primary,
                      onTap: () => context.push(Routes.customerForm, extra: customer),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            ),
          ),

          // Debt Balance Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: customer.debtBalance > 0
                        ? Colors.amber.withValues(alpha: 0.3)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: customer.debtBalance > 0
                                ? Colors.amber.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            customer.debtBalance > 0
                                ? Icons.account_balance_wallet
                                : Icons.check_circle,
                            color: customer.debtBalance > 0 ? Colors.amber.shade700 : Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                langCode == 'ku' ? 'Ù‚Û•Ø±Ø²ÛŒ Ù…Ø§ÙˆÛ•' : langCode == 'ar' ? 'Ø§Ù„Ø¯ÙŠÙˆÙ† Ø§Ù„Ù…ØªØ¨Ù‚ÙŠØ©' : 'Outstanding Debt',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(customer.debtBalance),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: customer.debtBalance > 0 ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (customer.debtBalance > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              langCode == 'ku' ? 'Ù†Û•Ø¯Ø±Ø§ÙˆÛ•' : langCode == 'ar' ? 'ØºÙŠØ± Ù…Ø¯ÙÙˆØ¹' : 'UNPAID',
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              langCode == 'ku' ? 'Ù¾Ø§Ú©Û•' : langCode == 'ar' ? 'Ù…Ø³Ø¯Ø¯' : 'CLEAR',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (customer.debtBalance > 0) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showSettleDebtDialog(context, ref, customer, langCode),
                          icon: const Icon(Icons.payment),
                          label: Text(langCode == 'ku' ? 'Ù¾Ø§Ø±Û•Ø¯Ø§Ù†' : langCode == 'ar' ? 'ØªØ³Ø¯ÙŠØ¯ Ø§Ù„Ø¯ÙØ¹Ø©' : 'Settle Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
            ),
          ),

          // Contact Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.phone_outlined, 'Phone', customer.phone ?? 'Not provided', isDark, isLtr: true),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on_outlined, 'Address', customer.address ?? 'Not provided', isDark),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.badge_outlined, 'Customer ID', customer.id.substring(0, 8).toUpperCase(), isDark, isLtr: true),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            ),
          ),

          // Recent Orders Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recent Orders',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),

          // History list (Orders & Payments)
          FutureBuilder<List<Object>>(
            future: Future.wait([
              orderRepo.getOrdersByCustomer(customer.id),
              ref.read(paymentRepositoryProvider).getPaymentsByCustomer(customer.id),
            ]).then((results) {
              final List<Object> history = [];
              history.addAll(results[0] as List<OrderEntity>);
              history.addAll(results[1] as List<PaymentEntity>);
              return history;
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CustomLoader()),
                  ),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          langCode == 'ku' ? 'Ù‡ÛŒÚ† Ø²Ø§Ù†ÛŒØ§Ø±ÛŒÛŒÛ•Ú© Ù†ÛŒÛŒÛ•' : langCode == 'ar' ? 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ ØªØ§Ø±ÙŠØ®' : 'No history yet for this customer',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Take last 15 items, sorted by date descending
              final recentItems = items..sort((a, b) {
                final dateA = a is OrderEntity ? a.orderDate : (a as PaymentEntity).paymentDate;
                final dateB = b is OrderEntity ? b.orderDate : (b as PaymentEntity).paymentDate;
                return dateB.compareTo(dateA);
              });
              final displayItems = recentItems.take(15).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = displayItems[index];
                    
                    if (item is OrderEntity) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: OrderStatusUtils.getStatusColor(item.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  OrderStatusUtils.getStatusIcon(item.status),
                                  color: OrderStatusUtils.getStatusColor(item.status),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order #${item.id.substring(0, 8).toUpperCase()}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd/MM/yyyy â€¢ HH:mm').format(item.orderDate),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(item.totalAmount),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  OrderStatusUtils.buildStatusBadge(item.status),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
                      );
                    } else if (item is PaymentEntity) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.payments,
                                  color: Colors.green,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Received',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd/MM/yyyy â€¢ HH:mm').format(item.paymentDate),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '+ ${CurrencyFormatter.format(item.amount)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
                      );
                    }
                    return const SizedBox();
                  },
                  childCount: displayItems.length,
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showSettleDebtDialog(BuildContext context, WidgetRef ref, CustomerEntity customer, String langCode) {
    final controller = TextEditingController();
    if (customer.debtBalance > 0) {
      controller.text = customer.debtBalance.toInt().toString();
    }
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(langCode == 'ku' ? 'Ù¾Ø§Ø±Û•Ø¯Ø§Ù† Ø¨Û† ${customer.businessName}' : langCode == 'ar' ? 'ØªØ³Ø¯ÙŠØ¯ Ø§Ù„Ø¯ÙØ¹Ø© Ù„Ù€ ${customer.businessName}' : 'Settle Debt for ${customer.businessName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text((langCode == 'ku' ? 'Ù‚Û•Ø±Ø²ÛŒ Ø¦ÛŽØ³ØªØ§: ' : langCode == 'ar' ? 'Ø§Ù„Ø¯ÙŠÙ† Ø§Ù„Ø­Ø§Ù„ÙŠ: ' : 'Current Debt: ') + CurrencyFormatter.format(customer.debtBalance)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: langCode == 'ku' ? 'Ø¨Ú•ÛŒ Ù¾Ø§Ø±Û•' : langCode == 'ar' ? 'Ø§Ù„Ù…Ø¨Ù„Øº Ø§Ù„Ù…Ø¯ÙÙˆØ¹' : 'Amount Paid',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langCode == 'ku' ? 'Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•' : langCode == 'ar' ? 'Ø¥Ù„ØºØ§Ø¡' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text.replaceAll(',', ''));
                if (amount != null && amount > 0) {
                  // Use PaymentRepositoryImpl for atomic payment + debt reduction
                  await ref.read(paymentRepositoryProvider).recordPayment(
                    customerId: customer.id,
                    amount: amount,
                  );

                  await ref.read(notificationProvider.notifier).addNotification(
                    title: 'Payment Received',
                    message: '${CurrencyFormatter.format(amount)} received from ${customer.businessName}',
                    type: 'sync',
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(context, langCode == 'ku' ? 'Ø¨Û• Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆÛŒ Ø¯Ø±Ø§' : langCode == 'ar' ? 'ØªÙ… Ø§Ù„Ø¯ÙØ¹ Ø¨Ù†Ø¬Ø§Ø­' : 'Payment applied successfully');
                  }
                } else {
                  AppFeedback.showError(context, langCode == 'ku' ? 'Ø¨Ú•ÛŽÚ©ÛŒ Ø¯Ø±ÙˆØ³Øª Ø¨Ù†ÙˆÙˆØ³Û•' : langCode == 'ar' ? 'Ø£Ø¯Ø®Ù„ Ù…Ø¨Ù„Øº ØµØ­ÙŠØ­' : 'Please enter a valid amount');
                }
              },
              child: Text(langCode == 'ku' ? 'Ù¾Û•Ø³Û•Ù†Ø¯Ú©Ø±Ø¯Ù†' : langCode == 'ar' ? 'ØªØ£ÙƒÙŠØ¯' : 'Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark, {bool isLtr = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textDirection: isLtr ? TextDirection.rtl : null,
            ),
          ],
        ),
      ],
    );
  }

  void _callCustomer(BuildContext context, WidgetRef ref) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(localeProvider).languageCode == 'ku' ? 'Ù‡ÛŒÚ† Ú˜Ù…Ø§Ø±Û•ÛŒÛ•Ú©ÛŒ ØªÛ•Ù„Û•ÙÛ†Ù† ØªÛ†Ù…Ø§Ø± Ù†Û•Ú©Ø±Ø§ÙˆÛ• Ø¨Û† Ø¦Û•Ù… Ú©Ú•ÛŒØ§Ø±Û•' : ref.read(localeProvider).languageCode == 'ar' ? 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø±Ù‚Ù… Ù‡Ø§ØªÙ Ù…Ø³Ø¬Ù„ Ù„Ù‡Ø°Ø§ Ø§Ù„Ø¹Ù…ÙŠÙ„' : 'No phone number registered for this customer')),
      );
      return;
    }
    final uri = Uri.parse('tel:${customer.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // Status helpers now live in OrderStatusUtils (core/utils/order_status_utils.dart)
}


