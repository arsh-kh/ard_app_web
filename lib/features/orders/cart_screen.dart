import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:collection/collection.dart';
import '../../core/providers/cart_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../domain/enums.dart';
import '../../core/constants/app_constants.dart';

final cartCustomersProvider = FutureProvider<List<CustomerEntity>>((ref) {
  return ref.watch(customerRepositoryProvider).getAllCustomers();
});

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  CustomerEntity? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final orderRepo = ref.watch(orderRepositoryProvider);
    final customersAsync = ref.watch(cartCustomersProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(localeProvider).languageCode == 'ku' ? 'پێداچوونەوەی سەبەتە' : ref.watch(localeProvider).languageCode == 'ar' ? 'مراجعة سلة التسوق' : 'Review Shopping Cart'),
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
                    ref.watch(localeProvider).languageCode == 'ku' ? 'سەبەتەکەت خاڵییە' : ref.watch(localeProvider).languageCode == 'ar' ? 'سلة التسوق فارغة' : 'Your cart is empty',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(ref.watch(localeProvider).languageCode == 'ku' ? 'گەڕان بەدوای کاڵاکان' : ref.watch(localeProvider).languageCode == 'ar' ? 'تصفح المنتجات' : 'Browse Products'),
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
                              message: ref.read(localeProvider).languageCode == 'ku' ? 'کاڵا سڕایەوە' : ref.read(localeProvider).languageCode == 'ar' ? 'تم حذف العنصر' : 'Item removed',
                              undoLabel: ref.read(localeProvider).languageCode == 'ku' ? 'پاشگەزبوونەوە' : ref.read(localeProvider).languageCode == 'ar' ? 'تراجع' : 'UNDO',
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
                                '${item.quantity.toInt()} ${item.product.unitType} x ${CurrencyFormatter.format(item.product.sellPrice)}',
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
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                          // Customer Dropdown Picker
                          customersAsync.when(
                            data: (customers) {
                              return DropdownButtonFormField<String>(
                                initialValue: _selectedCustomerId,
                                decoration: InputDecoration(
                                  labelText: ref.watch(localeProvider).languageCode == 'ku' ? 'دیاریکردنی کڕیار' : ref.watch(localeProvider).languageCode == 'ar' ? 'تعيين عميل' : 'Assign Customer',
                                  prefixIcon: Icon(Icons.person_outline),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                ),
                                hint: const Text('Select customer...'),
                                items: customers.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text(
                                      '${c.businessName} (Debt: ${CurrencyFormatter.format(c.debtBalance)})',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCustomerId = val;
                                    _selectedCustomer = customers.firstWhereOrNull((c) => c.id == val);
                                  });
                                },
                                validator: (value) => value == null ? 'Please assign a customer' : null,
                                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Text('Error loading customers: $err', style: const TextStyle(color: Colors.red)),
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
                                      'Customer has outstanding debt: ${CurrencyFormatter.format(_selectedCustomer!.debtBalance)}',
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
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
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
                                    Text('Items Count:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text('${cartItems.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal:', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                    Text(CurrencyFormatter.format(cartNotifier.totalCartPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                    const Text(
                                      'Order Total:',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(cartNotifier.totalCartPrice),
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
                                if (_formKey.currentState!.validate()) {
                                  // Show confirmation dialog
                                  final customerName = _selectedCustomer?.businessName ?? 'Client';
                                  final confirmed = await AppFeedback.showConfirmDialog(
                                    context,
                                    title: 'Confirm Order',
                                    message: 'Place order of ${CurrencyFormatter.format(cartNotifier.totalCartPrice)} for $customerName?\n\nThis will deduct stock from inventory.',
                                    confirmLabel: 'Place Order',
                                    confirmColor: Colors.green,
                                    icon: Icons.shopping_cart_checkout,
                                  );

                                  if (!confirmed) return;

                                  final orderId = const Uuid().v4();
                                  
                                  final order = OrderEntity(
                                    id: orderId,
                                    customerId: _selectedCustomerId!,
                                    status: OrderStatus.delivered.value,
                                    totalAmount: cartNotifier.totalCartPrice,
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
                                  
                                  // Log local in-app alert notification
                                  await ref.read(notificationProvider.notifier).addNotification(
                                    title: '${AppConstants.appName} - Order Approved',
                                    message: 'Order of ${CurrencyFormatter.format(cartNotifier.totalCartPrice)} for $customerName delivered.',
                                    type: 'order',
                                  );

                                  cartNotifier.clearCart();
                                  
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(context, 'Order placed successfully!');
                                    context.pop();
                                  }
                                }
                              },
                              child: Text(ref.watch(localeProvider).languageCode == 'ku' ? 'ناردنی داواکاری' : ref.watch(localeProvider).languageCode == 'ar' ? 'إرسال الطلب' : 'Place Order'),
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

