import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../core/providers/inventory_providers.dart';
import '../../core/providers/cart_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../data/local_database/database.dart';
import '../../domain/enums.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';

final posCustomersProvider = FutureProvider<List<CustomerEntity>>((ref) {
  return ref.watch(customerRepositoryProvider).getAllCustomers();
});

class BakeryCatalogScreen extends ConsumerStatefulWidget {
  const BakeryCatalogScreen({super.key});

  @override
  ConsumerState<BakeryCatalogScreen> createState() => _BakeryCatalogScreenState();
}

class _BakeryCatalogScreenState extends ConsumerState<BakeryCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCheckoutSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryRepo = ref.watch(inventoryRepositoryProvider);
    final productsStream = inventoryRepo.watchAllProducts();
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Localization
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final title = isKurdish ? 'کەتەلۆگ و فرۆشتن' : isArabic ? 'الكتالوج والبيع' : 'Catalog & POS';
    final searchHint = isKurdish ? 'گەڕان بۆ بەرهەم...' : isArabic ? 'البحث عن منتجات...' : 'Search products...';
    final allProducts = isKurdish ? 'هەموو بەرهەمەکان' : isArabic ? 'كل المنتجات' : 'All Products';
    final bag = localizations.bag;
    final kg = localizations.kg;
    final ton = localizations.ton;
    final outOfStock = localizations.outOfStock;
    final addToCartStr = localizations.add;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 26),
                onPressed: () {
                  if (cartItems.isNotEmpty) {
                    _showCheckoutSheet(context, ref);
                  } else {
                    AppFeedback.showError(context, 'Cart is empty!');
                  }
                },
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().shake(duration: 400.ms),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Box
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Categories chips row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildCategoryChip(allProducts, 'all'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(bag, 'bag'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(kg, 'kg'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(ton, 'ton'),
                    const SizedBox(width: 8),
                    _buildCategoryChip(isKurdish ? 'کارتۆن' : isArabic ? 'صندوق' : 'Box', 'box'),
                  ],
                ),
              ),

              // Product Grid
              Expanded(
                child: StreamBuilder<List<ProductEntity>>(
                  stream: productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final products = snapshot.data ?? [];

                    // Filter products locally
                    final filtered = products.where((p) {
                      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesCategory = _selectedCategory == 'all' ||
                          p.unitType.toLowerCase() == _selectedCategory.toLowerCase();
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              localizations.noData,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, cartItems.isNotEmpty ? 100 : 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final cartItem = cartItems.firstWhereOrNull((item) => item.product.id == product.id);
                        final quantityInCart = cartItem?.quantity ?? 0.0;

                        final stockRatio = product.stockQuantity / 100.0; 
                        final clampedRatio = stockRatio.clamp(0.0, 1.0);
                        Color stockColor = Colors.green;
                        if (product.stockQuantity < 10.0) {
                          stockColor = Colors.red;
                        } else if (product.stockQuantity < 40.0) {
                          stockColor = Colors.amber;
                        }

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: quantityInCart > 0
                                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade200,
                              width: quantityInCart > 0 ? 2 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.unitType.toUpperCase(),
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (product.stockQuantity <= 0)
                                      Text(
                                        outOfStock.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                  ],
                                ),
                                const Spacer(),
                                Center(
                                  child: Icon(
                                    Icons.bakery_dining_outlined,
                                    size: 48,
                                    color: quantityInCart > 0
                                        ? theme.colorScheme.primary
                                        : Colors.grey.shade400,
                                  ).animate(target: quantityInCart > 0 ? 1 : 0).scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.15, 1.15),
                                        duration: 200.ms,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: clampedRatio,
                                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                          color: stockColor,
                                          minHeight: 4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${product.stockQuantity.toInt()}',
                                      style: TextStyle(fontSize: 10, color: stockColor, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  CurrencyFormatter.format(product.sellPrice),
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 36,
                                  width: double.infinity,
                                  child: quantityInCart > 0
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            _buildQuantityButton(
                                              icon: Icons.remove,
                                              onPressed: () => cartNotifier.addProduct(product, -1.0),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                _showQuantityInputDialog(context, product, quantityInCart, cartNotifier);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text('${quantityInCart.toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                              ),
                                            ),
                                            _buildQuantityButton(
                                              icon: Icons.add,
                                              onPressed: () {
                                                if (quantityInCart < product.stockQuantity) {
                                                  cartNotifier.addProduct(product, 1.0);
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      : ElevatedButton(
                                          onPressed: product.stockQuantity <= 0 ? null : () => cartNotifier.addProduct(product, 1.0),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 0),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: Text(addToCartStr, style: const TextStyle(fontSize: 12)),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(duration: 200.ms).slideY(begin: 0.05, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Sticky Bottom Cart Panel
          if (cartItems.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => _showCheckoutSheet(context, ref),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${cartItems.length}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.totalAmount,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                              ),
                              Text(
                                CurrencyFormatter.format(cartNotifier.totalCartPrice),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            isKurdish ? 'پارەدان' : isArabic ? 'الدفع' : 'Checkout',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                        ],
                      )
                    ],
                  ),
                ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String categoryId) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == categoryId;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = categoryId;
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: theme.colorScheme.primary),
      ),
    );
  }

  void _showQuantityInputDialog(BuildContext context, ProductEntity product, double currentQty, CartNotifier cartNotifier) {
    final controller = TextEditingController(text: currentQty > 0 ? currentQty.toInt().toString() : '');
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
          title: Text('Enter Quantity for ${product.name}'),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Quantity',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = double.tryParse(controller.text);
                if (newQty != null && newQty >= 0 && newQty <= product.stockQuantity) {
                  cartNotifier.removeProduct(product.id);
                  if (newQty > 0) {
                    cartNotifier.addProduct(product, newQty);
                  }
                  Navigator.pop(context);
                } else {
                  // Assuming AppFeedback exists in project scope
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity or not enough stock')));
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

class _CheckoutSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCustomerId;
  CustomerEntity? _selectedCustomer;

  void _processCheckout(WidgetRef ref, List<CartItem> cartItems, double totalAmount, bool isQuickSell) async {
    final customerName = isQuickSell ? 'Walk-In Customer' : (_selectedCustomer?.businessName ?? 'Client');
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';

    final confirmOrderStr = isKurdish ? 'داواکاری بسەلمێنە' : isArabic ? 'تأكيد الطلب' : 'Confirm Order';

    final confirmBody = isKurdish 
      ? 'دەتەوێت داواکاری بە بڕی ${CurrencyFormatter.format(totalAmount)} بۆ $customerName تۆمار بکەیت؟\n\nئەمە لە کۆگا کەم دەکرێتەوە.' 
      : isArabic 
        ? 'هل تريد تقديم طلب بقيمة ${CurrencyFormatter.format(totalAmount)} لـ $customerName؟\n\nهذا سيخصم من المخزون.' 
        : 'Place order of ${CurrencyFormatter.format(totalAmount)} for $customerName?\n\nThis will deduct stock.';
        
    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: confirmOrderStr,
      message: confirmBody,
      confirmLabel: localizations.confirm,
      confirmColor: Colors.green,
      icon: Icons.shopping_cart_checkout,
    );

    if (!confirmed) return;
    
    String finalCustomerId = _selectedCustomerId ?? 'walk-in';
    final customerRepo = ref.read(customerRepositoryProvider);
    final orderRepo = ref.read(orderRepositoryProvider);

    if (isQuickSell) {
      // Check if walk-in exists, if not create it silently
      final allCustomers = await customerRepo.watchAllCustomers().first;
      final walkInExists = allCustomers.any((c) => c.id == 'walk-in');
      if (!walkInExists) {
        await customerRepo.addCustomer(
          CustomersCompanion(
            id: drift.Value('walk-in'),
            businessName: drift.Value('Walk-In Customer'),
            phone: drift.Value('N/A'),
            debtBalance: drift.Value(0),
          ),
        );
      }
    }

    final orderId = const Uuid().v4();
    final order = OrdersCompanion(
      id: drift.Value(orderId),
      customerId: drift.Value(finalCustomerId),
      status: drift.Value(OrderStatus.delivered.value),
      totalAmount: drift.Value(totalAmount),
    );

    final items = cartItems.map((item) => OrderItemsCompanion(
      id: drift.Value(const Uuid().v4()),
      orderId: drift.Value(orderId),
      productId: drift.Value(item.product.id),
      quantity: drift.Value(item.quantity),
      unitPrice: drift.Value(item.customPrice), // Use custom price
    )).toList();

    await orderRepo.createOrder(order, items);
    
    // If walk-in, pay immediately
    if (isQuickSell) {
      await customerRepo.addPayment(
        PaymentsCompanion(
          id: drift.Value(const Uuid().v4()),
          customerId: drift.Value(finalCustomerId),
          amount: drift.Value(totalAmount),
          paymentDate: drift.Value(DateTime.now()),
        )
      );
    }

    await ref.read(notificationProvider.notifier).addNotification(
      title: '${AppConstants.appName} - Order Approved',
      message: 'Order of ${CurrencyFormatter.format(totalAmount)} for $customerName delivered.',
      type: 'order',
    );

    ref.read(cartProvider.notifier).clearCart();
    if (context.mounted) {
      AppFeedback.showSuccess(context, localizations.success);
      context.pop(); // Close sheet
    }
  }

  void _editPrice(BuildContext context, CartItem item, WidgetRef ref) {
    final controller = TextEditingController(text: item.customPrice.toInt().toString());
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Price'),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Price per unit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text.replaceAll(',', ''));
              if (newPrice != null && newPrice >= 0) {
                ref.read(cartProvider.notifier).updateProductPrice(item.product, newPrice);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final customersAsync = ref.watch(posCustomersProvider);
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';

    final assignCustomerStr = isKurdish ? 'کڕیار دیاری بکە' : isArabic ? 'تحديد العميل' : 'Assign Customer';
    final totalStr = localizations.totalAmount;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isKurdish ? 'سەبەتە' : isArabic ? 'عربة التسوق' : 'Cart Review',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Items List
                      ...cartItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('${item.quantity}x ${item.product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            InkWell(
                              onTap: () => _editPrice(context, item, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.colorScheme.primary),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(CurrencyFormatter.format(item.customPrice), style: TextStyle(color: theme.colorScheme.primary)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 14, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: Text(CurrencyFormatter.format(item.totalPrice), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )),
                      const Divider(height: 24),

                      // Customer Dropdown Picker
                      customersAsync.when(
                        data: (customers) {
                          return DropdownButtonFormField<String>(
                            value: _selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: assignCustomerStr,
                              prefixIcon: const Icon(Icons.person_outline),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            hint: const Text('Select a registered customer'),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.businessName} (Debt: ${CurrencyFormatter.format(c.debtBalance)})', style: const TextStyle(fontSize: 13)),
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
                        error: (err, _) => Text('Error: $err', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(height: 12),

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
                              Expanded(child: Text('Debt: ${CurrencyFormatter.format(_selectedCustomer!.debtBalance)}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(totalStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(CurrencyFormatter.format(cartNotifier.totalCartPrice), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _processCheckout(ref, cartItems, cartNotifier.totalCartPrice, true),
                              icon: const Icon(Icons.bolt, color: Colors.white),
                              label: Text(isKurdish ? 'فرۆشتنی خێرا' : isArabic ? 'بيع سريع' : 'Quick Sell (Cash)', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade500,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _processCheckout(ref, cartItems, cartNotifier.totalCartPrice, false);
                                }
                              },
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: Text(isKurdish ? 'سەلماندن' : isArabic ? 'تأكيد للعميل' : 'Checkout to Client', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

