import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/cart_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/app_translations.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../domain/enums.dart';



class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  CustomerEntity? _selectedCustomer;
  double _discount = 0.0;
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final orderRepo = ref.watch(orderRepositoryProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final totalAmount = (cartNotifier.totalCartPrice - _discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Text(Tr.t('reviewCart', currentLocale.languageCode)),
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Tr.t('cartEmpty', currentLocale.languageCode),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(Tr.t('browseProducts', currentLocale.languageCode)),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return Dismissible(
                          key: ValueKey(item.product.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsetsDirectional.only(end: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
                          ),
                          onDismissed: (_) {
                            final removedItem = item;
                            cartNotifier.removeProduct(item.product.id);
                            AppFeedback.showUndo(
                              context,
                              message: Tr.t('itemRemoved', currentLocale.languageCode),
                              undoLabel: Tr.t('undoBtn', currentLocale.languageCode),
                              onUndo: () {
                                cartNotifier.addProduct(removedItem.product, removedItem.quantity);
                              },
                            );
                          },
                          child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                              child: Icon(Icons.bakery_dining, color: theme.colorScheme.primary),
                            ),
                            title: Text(
                              item.product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${item.quantity.toInt()} ${Tr.t(item.product.unitType, currentLocale.languageCode)} x ${CurrencyFormatter.format(item.product.sellPrice)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.totalPrice),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_left, color: Colors.grey.shade400, size: 18),
                              ],
                            ),
                          ),
                        ).animate().fade(duration: 150.ms).slideX(begin: 0.05, end: 0),
                        );
                      },
                    ),
                  ),

                  // Bottom panel with customer selection and receipt summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111111) : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        )
                      ],
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Customer Selection Button
                          InkWell(
                            onTap: () async {
                              final selected = await context.push<CustomerEntity?>(Routes.customerSelection);
                              if (selected != null) {
                                setState(() {
                                  _selectedCustomerId = selected.id;
                                  _selectedCustomer = selected;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, color: theme.colorScheme.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          Tr.t('assignCustomer', currentLocale.languageCode),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedCustomer?.businessName ?? Tr.t('selectCustomerHint', currentLocale.languageCode),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: _selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                                            color: _selectedCustomer != null ? theme.colorScheme.onSurface : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Customer Debt Warning Banner
                          if (_selectedCustomer != null && _selectedCustomer!.debtBalance > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${Tr.t('outstandingDebtWarning', currentLocale.languageCode)}: ${CurrencyFormatter.format(_selectedCustomer!.debtBalance)}',
                                      style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(duration: 200.ms),

                          const SizedBox(height: 16),

                          // Receipt Summary Box
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF000000) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(Tr.t('itemsCount', currentLocale.languageCode), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text('${cartItems.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(Tr.t('subtotal', currentLocale.languageCode), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text(CurrencyFormatter.format(cartNotifier.totalCartPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(Tr.t('discount', currentLocale.languageCode), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    SizedBox(
                                      width: 120,
                                      height: 36,
                                      child: TextFormField(
                                        controller: _discountController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                          hintText: '0',
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _discount = double.tryParse(val.replaceAll(',', '')) ?? 0.0;
                                          });
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Dotted divider representation
                                Row(
                                  children: List.generate(
                                    30,
                                    (index) => Expanded(
                                      child: Container(
                                        color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade400,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Tr.t('orderTotal', currentLocale.languageCode),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(totalAmount),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Checkout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_selectedCustomer == null) {
                                  AppFeedback.showError(context, 'Please assign a customer');
                                  return;
                                }
                                  // Show confirmation dialog
                                  final customerName = _selectedCustomer?.businessName ?? 'Client';
                                  final confirmed = await AppFeedback.showConfirmDialog(
                                    context,
                                    title: Tr.t('confirmOrder', currentLocale.languageCode),
                                    message: '${Tr.t('placeOrderOf', currentLocale.languageCode)} ${CurrencyFormatter.format(totalAmount)} ${Tr.t('forClient', currentLocale.languageCode)} $customerName?\n\n${Tr.t('deductStockWarning', currentLocale.languageCode)}',
                                    confirmLabel: Tr.t('placeOrderBtn', currentLocale.languageCode),
                                    confirmColor: Colors.green,
                                    icon: Icons.shopping_cart_checkout,
                                  );

                                  if (!confirmed) return;

                                  final orderId = const Uuid().v4();
                                  
                                  final order = OrderEntity(
                                    id: orderId,
                                    customerId: _selectedCustomerId!,
                                    status: OrderStatus.delivered.value,
                                    totalAmount: totalAmount,
                                    discount: _discount,
                                    orderDate: DateTime.now(),
                                  );

                                  final items = cartItems.map((item) => OrderItemEntity(
                                    id: const Uuid().v4(),
                                    orderId: orderId,
                                    productId: item.product.id,
                                    quantity: item.quantity,
                                    unitPrice: item.product.sellPrice,
                                  )).toList();

                                  // Save order
                                  await orderRepo.createOrder(order, items);
                                  
                                  await ref.read(notificationProvider.notifier).addNotification(
                                    title: 'order_delivered',
                                    message: jsonEncode({'amount': totalAmount, 'customer': customerName}),
                                    type: 'order',
                                  );

                                  cartNotifier.clearCart();
                                  
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(context, Tr.t('orderPlacedSuccess', currentLocale.languageCode));
                                    context.pop();
                                  }
                              },
                              child: Text(Tr.t('placeOrderBtn', currentLocale.languageCode)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}


