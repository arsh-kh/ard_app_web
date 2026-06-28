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
import '../../core/utils/focus_utils.dart';
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
import '../../core/utils/app_translations.dart';

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
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.address != null &&
                          customer.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.address!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.8),
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
                icon: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  context.push(Routes.customerForm, extra: customer);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(Tr.t('deleteCustomer', langCode)),
                      content: Text(Tr.t('deleteCustomerConfirm', langCode)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(Tr.t('cancelBtn', langCode)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            Tr.t('delete', langCode),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(customerRepositoryProvider)
                        .deleteCustomer(customer.id);
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
                      label: Tr.t('callBtn', langCode),
                      color: theme.colorScheme.primary,
                      onTap: () => _callCustomer(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      icon: Icons.edit_note,
                      label: Tr.t('editProfileBtn', langCode),
                      color: Theme.of(context).colorScheme.primary,
                      onTap: () =>
                          context.push(Routes.customerForm, extra: customer),
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: customer.debtBalance > 0
                        ? Colors.amber.withValues(alpha: 0.3)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.03),
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
                                : theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            customer.debtBalance > 0
                                ? Icons.account_balance_wallet
                                : Icons.check_circle,
                            color: customer.debtBalance > 0
                                ? Colors.amber.shade700
                                : theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Tr.t('outstandingDebtDetail', langCode),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(customer.debtBalance),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: customer.debtBalance > 0
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (customer.debtBalance > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              Tr.t('unpaidBadge', langCode),
                              style: TextStyle(
                                color: Colors.amber.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Text(
                              Tr.t('clearBadge', langCode),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
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
                          onPressed: () => _showSettleDebtDialog(
                            context,
                            ref,
                            customer,
                            langCode,
                          ),
                          icon: Icon(Icons.payment),
                          label: Text(Tr.t('settlePayment', langCode)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
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
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Tr.t('contactInfo', langCode),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.phone_outlined,
                      Tr.t('phoneLabel', langCode),
                      customer.phone ?? Tr.t('notProvided', langCode),
                      isDark,
                      isLtr: true,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      context,
                      Icons.location_on_outlined,
                      Tr.t('addressLabel', langCode),
                      customer.address ?? Tr.t('notProvided', langCode),
                      isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      context,
                      Icons.badge_outlined,
                      Tr.t('customerIdLabel', langCode),
                      customer.id.substring(0, 8).toUpperCase(),
                      isDark,
                      isLtr: true,
                    ),
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
                Tr.t('recentOrders', langCode),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // History list (Orders & Payments)
          FutureBuilder<List<Object>>(
            future:
                Future.wait([
                  orderRepo.getOrdersByCustomer(customer.id),
                  ref
                      .read(paymentRepositoryProvider)
                      .getPaymentsByCustomer(customer.id),
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
                        Icon(
                          Icons.history_toggle_off,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          Tr.t('noHistory', langCode),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Take last 15 items, sorted by date descending
              final recentItems = items
                ..sort((a, b) {
                  final dateA = a is OrderEntity
                      ? a.orderDate
                      : (a as PaymentEntity).paymentDate;
                  final dateB = b is OrderEntity
                      ? b.orderDate
                      : (b as PaymentEntity).paymentDate;
                  return dateB.compareTo(dateA);
                });
              final displayItems = recentItems.take(15).toList();

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = displayItems[index];

                  if (item is OrderEntity) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final query =
                              item.orderNumber?.toString() ??
                              item.id.substring(0, 8);
                          context.push('${Routes.adminOrders}?search=$query');
                        },
                        child: Ink(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: OrderStatusUtils.getStatusColor(
                                    item.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  OrderStatusUtils.getStatusIcon(item.status),
                                  color: OrderStatusUtils.getStatusColor(
                                    item.status,
                                  ),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${Tr.t('orderLabel', langCode)} #${item.orderNumber?.toString() ?? item.id.substring(0, 6).toUpperCase()}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy',
                                      ).format(item.orderDate),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(item.totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  OrderStatusUtils.buildStatusBadge(
                                    item.status,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
                    );
                  } else if (item is PaymentEntity) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.payments,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Tr.t('paymentReceived', langCode),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(item.paymentDate),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+ ${CurrencyFormatter.format(item.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms),
                    );
                  }
                  return const SizedBox();
                }, childCount: displayItems.length),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleDebtDialog(
    BuildContext context,
    WidgetRef ref,
    CustomerEntity customer,
    String langCode,
  ) {
    final controller = TextEditingController();
    if (customer.debtBalance > 0) {
      controller.text = customer.debtBalance.toInt().toString();
    }
    final focusNode = SelectAllFocusNode(controller: controller);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(Tr.t('settleDebtFor', langCode) + customer.businessName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Tr.t('currentDebtPrefix', langCode) +
                    CurrencyFormatter.format(customer.debtBalance),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  ArabicToEnglishFormatter(),
                  CurrencyInputFormatter(),
                ],
                autofocus: true,
                decoration: InputDecoration(
                  labelText: Tr.t('amountPaid', langCode),
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                  hintText: '0',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(Tr.t('cancelBtn', langCode)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(
                  controller.text.replaceAll(',', ''),
                );
                if (amount != null && amount > 0) {
                  // Use PaymentRepositoryImpl for atomic payment + debt reduction
                  await ref
                      .read(paymentRepositoryProvider)
                      .recordPayment(customerId: customer.id, amount: amount);

                  if (context.mounted) {
                    Navigator.pop(context);
                    AppFeedback.showSuccess(
                      context,
                      Tr.t('paymentApplied', langCode),
                    );
                  }
                } else {
                  AppFeedback.showError(
                    context,
                    Tr.t('enterValidAmount', langCode),
                  );
                }
              },
              child: Text(Tr.t('confirmPayment', langCode)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark, {
    bool isLtr = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              value,
              textDirection: isLtr ? TextDirection.ltr : null,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _callCustomer(BuildContext context, WidgetRef ref) async {
    final langCode = ref.read(localeProvider).languageCode;
    final phone = customer.phone;
    if (phone == null || phone.isEmpty) {
      AppFeedback.showError(context, Tr.t('noPhoneAvailable', langCode));
      return;
    }
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        AppFeedback.showError(context, Tr.t('couldNotDialPhone', langCode));
      }
    }
  }
}
