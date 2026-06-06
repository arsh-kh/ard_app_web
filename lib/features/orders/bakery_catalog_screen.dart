import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/inventory_providers.dart';
import '../../core/providers/cart_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/payment_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/feedback_utils.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryRepo = ref.watch(inventoryRepositoryProvider);
    final productsStream = inventoryRepo.watchAllProducts();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Localization
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final title = isKurdish ? 'ÙØ±Û†Ø´ØªÙ†' : isArabic ? 'Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª' : 'POS';
    final searchHint = isKurdish ? 'Ú¯Û•Ú•Ø§Ù† Ø¨Û† Ø¨Û•Ø±Ù‡Û•Ù…...' : isArabic ? 'Ø§Ù„Ø¨Ø­Ø« Ø¹Ù† Ù…Ù†ØªØ¬Ø§Øª...' : 'Search products...';
    final allProducts = isKurdish ? 'Ù‡Û•Ù…ÙˆÙˆ Ø¨Û•Ø±Ù‡Û•Ù…Û•Ú©Ø§Ù†' : isArabic ? 'ÙƒÙ„ Ø§Ù„Ù…Ù†ØªØ¬Ø§Øª' : 'All Products';
    final bag = localizations.bag;
    final kg = localizations.kg;
    final ton = localizations.ton;
    final outOfStock = localizations.outOfStock;
    final addToCartStr = localizations.add;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final cartItems = ref.watch(cartProvider);
              return Stack(
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
              );
            }
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
                    _buildCategoryChip(isKurdish ? 'Ú©Ø§Ø±ØªÛ†Ù†' : isArabic ? 'ØµÙ†Ø¯ÙˆÙ‚' : 'Box', 'box'),
                  ],
                ),
              ),

              // Product Grid
              Expanded(
                child: StreamBuilder<List<ProductEntity>>(
                  stream: productsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CustomLoader());
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 200),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final product = filtered[index];

                        return Consumer(
                          builder: (context, ref, child) {
                            final cartItems = ref.watch(cartProvider);
                            final cartNotifier = ref.read(cartProvider.notifier);
                            final cartItem = cartItems.firstWhereOrNull((item) => item.product.id == product.id);
                            final quantityInCart = cartItem?.quantity ?? 0.0;

                            Color stockColor = Colors.green;
                            if (product.stockQuantity < 10.0) {
                              stockColor = Colors.red;
                            } else if (product.stockQuantity < 40.0) {
                              stockColor = Colors.amber;
                            }

                            String displayUnit = product.unitType;
                            if (isKurdish) {
                              if (displayUnit == 'bag') displayUnit = 'ÙÛ•Ø±Ø¯Û•';
                              if (displayUnit == 'kg') displayUnit = 'Ú©ÛŒÙ„Û†Ú¯Ø±Ø§Ù…';
                              if (displayUnit == 'ton') displayUnit = 'ØªÛ†Ù†';
                              if (displayUnit == 'box') displayUnit = 'Ú©Ø§Ø±ØªÛ†Ù†';
                            } else if (isArabic) {
                              if (displayUnit == 'bag') displayUnit = 'ÙƒÙŠØ³';
                              if (displayUnit == 'kg') displayUnit = 'ÙƒÙŠÙ„ÙˆØºØ±Ø§Ù…';
                              if (displayUnit == 'ton') displayUnit = 'Ø·Ù†';
                              if (displayUnit == 'box') displayUnit = 'ØµÙ†Ø¯ÙˆÙ‚';
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Full-width Cover Image Area
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image Background
                                      Container(
                                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                        child: product.imageUrl != null
                                            ? Image.file(
                                                File(product.imageUrl!),
                                                fit: BoxFit.cover,
                                                color: quantityInCart == 0 ? Colors.black.withValues(alpha: 0.05) : null,
                                                colorBlendMode: quantityInCart == 0 ? BlendMode.darken : null,
                                              ).animate(target: quantityInCart > 0 ? 1 : 0).scale(
                                                begin: const Offset(1, 1),
                                                end: const Offset(1.1, 1.1),
                                                duration: 200.ms,
                                              )
                                            : Icon(
                                                Icons.bakery_dining_outlined,
                                                size: 48,
                                                color: quantityInCart > 0
                                                    ? theme.colorScheme.primary
                                                    : Colors.grey.shade400,
                                              ),
                                      ),
                                      
                                      // Top Badges Overlay
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        right: 8,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Unit Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                displayUnit.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            // Out of stock Badge
                                            if (product.stockQuantity <= 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  outOfStock.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Bottom Details Area
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: CustomLoader(),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${product.stockQuantity.toInt()}',
                                          style: TextStyle(fontSize: 10, color: stockColor, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
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
                            ],
                          ),
                        ).animate().fade(duration: 200.ms).slideY(begin: 0.05, end: 0);
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Sticky Bottom Cart Panel
          Consumer(
            builder: (context, ref, child) {
              final cartItems = ref.watch(cartProvider);
              final cartNotifier = ref.read(cartProvider.notifier);
              if (cartItems.isEmpty) return const SizedBox.shrink();
              return Positioned(
                left: 16,
                right: 16,
                bottom: 130,
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
                                color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${cartItems.length}',
                                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.totalAmount,
                                  style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8), fontSize: 12),
                                ),
                                Text(
                                  CurrencyFormatter.format(cartNotifier.totalCartPrice),
                                  style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            isKurdish ? 'Ù¾Ø§Ø±Û•Ø¯Ø§Ù†' : isArabic ? 'Ø§Ù„Ø¯ÙØ¹' : 'Checkout',
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onPrimary, size: 16),
                        ],
                      )
                    ],
                  ),
                ).animate().slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic),
              ),
            );
          },
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
    
    // Localization
    final currentLocale = ref.read(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final title = isKurdish ? 'Ø¨Ú•ÛŒ ${product.name} Ø¯ÛŒØ§Ø±ÛŒ Ø¨Ú©Û•' : isArabic ? 'Ø£Ø¯Ø®Ù„ ÙƒÙ…ÙŠØ© ${product.name}' : 'Enter Quantity for ${product.name}';
    final hint = isKurdish ? 'Ø¨Ú•' : isArabic ? 'Ø§Ù„ÙƒÙ…ÙŠØ©' : 'Quantity';
    final cancelText = isKurdish ? 'Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•' : isArabic ? 'Ø¥Ù„ØºØ§Ø¡' : 'Cancel';
    final updateText = isKurdish ? 'Ù†ÙˆÛŽÚ©Ø±Ø¯Ù†Û•ÙˆÛ•' : isArabic ? 'ØªØ­Ø¯ÙŠØ«' : 'Update';
    final errorText = isKurdish ? 'Ø¨Ú•Û•Ú©Û• Ù‡Û•ÚµÛ•ÛŒÛ• ÛŒØ§Ù† Ú©Û†Ú¯Ø§ Ø¨Û•Ø´ Ù†Ø§Ú©Ø§Øª' : isArabic ? 'ÙƒÙ…ÙŠØ© ØºÙŠØ± ØµØ§Ù„Ø­Ø© Ø£Ùˆ Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ù…Ø®Ø²ÙˆÙ† ÙƒØ§ÙÙ' : 'Invalid quantity or not enough stock';

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [ArabicToEnglishFormatter()],
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorText)));
                }
              },
              child: Text(updateText),
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
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final walkInStr = isKurdish ? 'Ú©Ú•ÛŒØ§Ø±ÛŒ Ú©Ø§ØªÛŒ' : isArabic ? 'Ø¹Ù…ÙŠÙ„ Ø¹Ø§Ø¨Ø±' : 'Walk-In Customer';
    final customerName = isQuickSell ? walkInStr : (_selectedCustomer?.businessName ?? 'Client');

    final confirmOrderStr = isKurdish ? 'Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ø¨Ø³Û•Ù„Ù…ÛŽÙ†Û•' : isArabic ? 'ØªØ£ÙƒÙŠØ¯ Ø§Ù„Ø·Ù„Ø¨' : 'Confirm Order';

    final confirmBody = isKurdish 
      ? 'Ø¯Û•ØªÛ•ÙˆÛŽØª Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ Ø¨Û• Ø¨Ú•ÛŒ ${CurrencyFormatter.format(totalAmount)} Ø¨Û† $customerName ØªÛ†Ù…Ø§Ø± Ø¨Ú©Û•ÛŒØªØŸ\n\nØ¦Û•Ù…Û• Ù„Û• Ú©Û†Ú¯Ø§ Ú©Û•Ù… Ø¯Û•Ú©Ø±ÛŽØªÛ•ÙˆÛ•.' 
      : isArabic 
        ? 'Ù‡Ù„ ØªØ±ÙŠØ¯ ØªÙ‚Ø¯ÙŠÙ… Ø·Ù„Ø¨ Ø¨Ù‚ÙŠÙ…Ø© ${CurrencyFormatter.format(totalAmount)} Ù„Ù€ $customerNameØŸ\n\nÙ‡Ø°Ø§ Ø³ÙŠØ®ØµÙ… Ù…Ù† Ø§Ù„Ù…Ø®Ø²ÙˆÙ†.' 
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
    final orderRepo = ref.read(orderRepositoryProvider);

    if (isQuickSell) {
      // Walk-in orders are purely logged. No customer is created in the DB.
    }

    final orderId = const Uuid().v4();
    final order = OrderEntity(
      id: orderId,
      customerId: finalCustomerId,
      status: OrderStatus.delivered.value,
      totalAmount: totalAmount,
      orderDate: DateTime.now(),
    );

    final items = cartItems.map((item) => OrderItemEntity(
      id: const Uuid().v4(),
      orderId: orderId,
      productId: item.product.id,
      quantity: item.quantity,
      unitPrice: item.customPrice, // Use custom price
    )).toList();

    await orderRepo.createOrder(order, items);
    
    // If walk-in, pay immediately
    if (isQuickSell) {
      final paymentRepo = ref.read(paymentRepositoryProvider);
      await paymentRepo.recordPayment(
        customerId: finalCustomerId,
        amount: totalAmount,
      );
    }

    await ref.read(notificationProvider.notifier).addNotification(
      title: '${AppConstants.appName} - Order Approved',
      message: 'Order of ${CurrencyFormatter.format(totalAmount)} for $customerName delivered.',
      type: 'order',
    );

    ref.read(cartProvider.notifier).clearCart();
    if (mounted) {
      AppFeedback.showSuccess(context, localizations.success);
      context.pop(); // Close sheet
    }
  }

  void _editPrice(BuildContext context, CartItem item, WidgetRef ref) {
    final isKurdish = ref.watch(localeProvider).languageCode == 'ku';
    final isArabic = ref.watch(localeProvider).languageCode == 'ar';
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
        title: Text(isKurdish ? 'Ú¯Û†Ú•ÛŒÙ†ÛŒ Ù†Ø±Ø®' : isArabic ? 'ØªØ¹Ø¯ÙŠÙ„ Ø§Ù„Ø³Ø¹Ø±' : 'Edit Price'),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
          autofocus: true,
          decoration: InputDecoration(border: const OutlineInputBorder(), labelText: isKurdish ? 'Ù†Ø±Ø®ÛŒ ÛŒÛ•Ú© Ø¯Ø§Ù†Û•' : isArabic ? 'Ø§Ù„Ø³Ø¹Ø± Ù„Ù„ÙˆØ­Ø¯Ø©' : 'Price per unit'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isKurdish ? 'Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•' : isArabic ? 'Ø¥Ù„ØºØ§Ø¡' : 'Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text.replaceAll(',', ''));
              if (newPrice != null && newPrice >= 0) {
                ref.read(cartProvider.notifier).updateProductPrice(item.product, newPrice);
                Navigator.pop(ctx);
              }
            },
            child: Text(isKurdish ? 'Ù¾Ø§Ø´Û•Ú©Û•ÙˆØªÚ©Ø±Ø¯Ù†' : isArabic ? 'Ø­ÙØ¸' : 'Save'),
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

    final assignCustomerStr = isKurdish ? 'Ú©Ú•ÛŒØ§Ø± Ø¯ÛŒØ§Ø±ÛŒ Ø¨Ú©Û•' : isArabic ? 'ØªØ­Ø¯ÙŠØ¯ Ø§Ù„Ø¹Ù…ÙŠÙ„' : 'Assign Customer';
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
                        isKurdish ? 'Ø³Û•Ø¨Û•ØªÛ•' : isArabic ? 'Ø¹Ø±Ø¨Ø© Ø§Ù„ØªØ³ÙˆÙ‚' : 'Cart Review',
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
                            initialValue: _selectedCustomerId,
                            decoration: InputDecoration(
                              labelText: assignCustomerStr,
                              prefixIcon: const Icon(Icons.person_outline),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            hint: Text(isKurdish ? 'Ú©Ú•ÛŒØ§Ø±ÛŽÚ©ÛŒ ØªÛ†Ù…Ø§Ø±Ú©Ø±Ø§Ùˆ Ù‡Û•ÚµØ¨Ú˜ÛŽØ±Û•' : isArabic ? 'Ø§Ø®ØªØ± Ø¹Ù…ÙŠÙ„Ø§Ù‹ Ù…Ø³Ø¬Ù„Ø§Ù‹' : 'Select a registered customer'),
                            items: customers.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.businessName} (${isKurdish ? 'Ù‚Û•Ø±Ø²' : isArabic ? 'Ø¯ÙŠÙ†' : 'Debt'}: ${CurrencyFormatter.format(c.debtBalance)})', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCustomerId = val;
                                _selectedCustomer = customers.firstWhereOrNull((c) => c.id == val);
                              });
                            },
                            validator: (value) => value == null ? (isKurdish ? 'ØªÚ©Ø§ÛŒÛ• Ú©Ú•ÛŒØ§Ø±ÛŽÚ© Ø¯ÛŒØ§Ø±ÛŒ Ø¨Ú©Û•' : isArabic ? 'ÙŠØ±Ø¬Ù‰ ØªØ­Ø¯ÙŠØ¯ Ø¹Ù…ÙŠÙ„' : 'Please assign a customer') : null,
                          );
                        },
                        loading: () => const Center(child: CustomLoader()),
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
                              Expanded(child: Text('${isKurdish ? 'Ù‚Û•Ø±Ø²' : isArabic ? 'Ø¯ÙŠÙ†' : 'Debt'}: ${CurrencyFormatter.format(_selectedCustomer!.debtBalance)}', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold))),
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
                              label: Text(isKurdish ? 'ÙØ±Û†Ø´ØªÙ†ÛŒ Ø®ÛŽØ±Ø§' : isArabic ? 'Ø¨ÙŠØ¹ Ø³Ø±ÙŠØ¹' : 'Quick Sell (Cash)', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                              icon: Icon(Icons.check, color: theme.colorScheme.onPrimary),
                              label: Text(isKurdish ? 'Ø³Û•Ù„Ù…Ø§Ù†Ø¯Ù†' : isArabic ? 'ØªØ£ÙƒÙŠØ¯ Ù„Ù„Ø¹Ù…ÙŠÙ„' : 'Checkout to Client', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
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



