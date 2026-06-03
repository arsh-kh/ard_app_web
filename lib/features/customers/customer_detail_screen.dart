import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/order_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/order_status_utils.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/local_database/database.dart';
import '../../data/local_database/tables.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/notification_providers.dart';
import 'package:drift/drift.dart' as drift;

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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
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
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            customer.businessName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.businessName,
                        style: const TextStyle(
                          color: Colors.white,
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
                              Icon(Icons.location_on, size: 14, color: Colors.white.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                customer.address!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
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
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                onPressed: () {
                  context.push(Routes.customerForm, extra: customer);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(langCode == 'ku' ? 'سڕینەوەی کڕیار' : langCode == 'ar' ? 'حذف العميل' : 'Delete Customer'),
                      content: Text(langCode == 'ku' ? 'دڵنیای لە سڕینەوەی ئەم کڕیارە؟' : langCode == 'ar' ? 'هل أنت متأكد من حذف هذا العميل؟' : 'Are you sure you want to delete this customer?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(langCode == 'ku' ? 'نەخێر' : langCode == 'ar' ? 'لا' : 'Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(langCode == 'ku' ? 'سڕینەوە' : langCode == 'ar' ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
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
                      label: 'Call',
                      color: Colors.green,
                      onTap: () => _callCustomer(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.edit_note,
                      label: 'Edit Profile',
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
                        ? Colors.amber.withOpacity(0.3)
                        : isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
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
                                ? Colors.amber.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
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
                                'Outstanding Debt',
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
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Text(
                              langCode == 'ku' ? 'نەدراوە' : langCode == 'ar' ? 'غير مدفوع' : 'UNPAID',
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
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Text(
                              langCode == 'ku' ? 'پاکە' : langCode == 'ar' ? 'مسدد' : 'CLEAR',
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
                          label: Text(langCode == 'ku' ? 'پارەدان' : langCode == 'ar' ? 'تسديد الدفعة' : 'Settle Payment'),
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
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
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
                    _buildInfoRow(Icons.phone_outlined, 'Phone', customer.phone ?? 'Not provided', isDark),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on_outlined, 'Address', customer.address ?? 'Not provided', isDark),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.badge_outlined, 'Customer ID', customer.id.substring(0, 8).toUpperCase(), isDark),
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
              ref.read(customerRepositoryProvider).getPaymentsForCustomer(customer.id),
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
                    child: Center(child: CircularProgressIndicator()),
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
                          langCode == 'ku' ? 'هیچ زانیارییەک نییە' : langCode == 'ar' ? 'لا يوجد تاريخ' : 'No history yet for this customer',
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
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: OrderStatusUtils.getStatusColor(item.status).withOpacity(0.1),
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
                                      DateFormat('MMM dd, yyyy • HH:mm').format(item.orderDate),
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
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
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
                                      DateFormat('MMM dd, yyyy • HH:mm').format(item.paymentDate),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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
          title: Text(langCode == 'ku' ? 'پارەدان بۆ ${customer.businessName}' : langCode == 'ar' ? 'تسديد الدفعة لـ ${customer.businessName}' : 'Settle Debt for ${customer.businessName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text((langCode == 'ku' ? 'قەرزی ئێستا: ' : langCode == 'ar' ? 'الدين الحالي: ' : 'Current Debt: ') + CurrencyFormatter.format(customer.debtBalance)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [CurrencyInputFormatter()],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: langCode == 'ku' ? 'بڕی پارە' : langCode == 'ar' ? 'المبلغ المدفوع' : 'Amount Paid',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langCode == 'ku' ? 'پاشگەزبوونەوە' : langCode == 'ar' ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(controller.text.replaceAll(',', ''));
                if (amount != null && amount > 0) {
                  final repo = ref.read(customerRepositoryProvider);
                  final newDebt = customer.debtBalance - amount;
                  
                  await repo.updateCustomer(
                    CustomersCompanion(
                      id: drift.Value(customer.id),
                      businessName: drift.Value(customer.businessName),
                      address: drift.Value(customer.address),
                      debtBalance: drift.Value(newDebt >= 0 ? newDebt : 0),
                      syncStatus: const drift.Value(SyncStatus.pendingSync),
                    ),
                  );
                  
                  // Insert Payment
                  final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
                  await repo.addPayment(
                    PaymentsCompanion(
                      id: drift.Value(paymentId),
                      customerId: drift.Value(customer.id),
                      amount: drift.Value(amount),
                      syncStatus: const drift.Value(SyncStatus.pendingSync),
                    ),
                  );
                  
                  await ref.read(notificationProvider.notifier).addNotification(
                    title: 'Payment Received',
                    message: '${CurrencyFormatter.format(amount)} received from ${customer.businessName}',
                    type: 'sync',
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(context, langCode == 'ku' ? 'بە سەرکەوتووی درا' : langCode == 'ar' ? 'تم الدفع بنجاح' : 'Payment applied successfully');
                  }
                } else {
                  AppFeedback.showError(context, langCode == 'ku' ? 'بڕێکی دروست بنووسە' : langCode == 'ar' ? 'أدخل مبلغ صحيح' : 'Please enter a valid amount');
                }
              },
              child: Text(langCode == 'ku' ? 'پەسەندکردن' : langCode == 'ar' ? 'تأكيد' : 'Confirm Payment'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
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
            ),
          ],
        ),
      ],
    );
  }

  void _callCustomer(BuildContext context) async {
    if (customer.phone == null || customer.phone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number registered for this customer')),
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
