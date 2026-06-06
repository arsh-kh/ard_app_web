import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/heavy_ios_button.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/formatters.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_entity.dart';
import '../../l10n/app_localizations.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showRestockDialog(ProductEntity product) async {
    final qtyCtrl = TextEditingController();
    final costCtrl = TextEditingController(text: CurrencyFormatter.formatNumber(product.buyPrice));
    
    final currentLocale = ref.read(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final title = isKurdish ? 'Ø²ÛŒØ§Ø¯Ú©Ø±Ø¯Ù†ÛŒ Ú©Û†Ú¯Ø§' : isArabic ? 'Ø¥Ø¶Ø§ÙØ© Ù…Ø®Ø²ÙˆÙ†' : 'Add Stock';
    final qtyLbl = isKurdish ? 'Ø¨Ú•' : isArabic ? 'Ø§Ù„ÙƒÙ…ÙŠØ©' : 'Quantity';
    final costLbl = isKurdish ? 'ØªÛŽÚ†ÙˆÙˆÛŒ Ú¯Ø´ØªÛŒ' : isArabic ? 'Ø§Ù„ØªÙƒÙ„ÙØ© Ø§Ù„Ø¥Ø¬Ù…Ø§Ù„ÙŠØ©' : 'Total Cost';
    final cancelLbl = isKurdish ? 'Ù¾Ø§Ø´Ú¯Û•Ø²Ø¨ÙˆÙˆÙ†Û•ÙˆÛ•' : isArabic ? 'Ø¥Ù„ØºØ§Ø¡' : 'Cancel';
    final addLbl = isKurdish ? 'Ø²ÛŒØ§Ø¯Ú©Ø±Ø¯Ù†' : isArabic ? 'Ø¥Ø¶Ø§ÙØ©' : 'Add';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: qtyLbl,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.add_box),
                ),
                onChanged: (val) {
                  final q = double.tryParse(val) ?? 0;
                  costCtrl.text = CurrencyFormatter.formatNumber(q * product.buyPrice);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [ArabicToEnglishFormatter(), CurrencyInputFormatter()],
                decoration: InputDecoration(
                  labelText: costLbl,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments_outlined),
                  suffixText: ' ${AppConstants.currencySymbol}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelLbl),
            ),
            ElevatedButton(
              onPressed: () {
                final q = double.tryParse(qtyCtrl.text) ?? 0;
                if (q > 0) {
                  ref.read(inventoryRepositoryProvider).restockProduct(
                    product.id,
                    q,
                  );
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isKurdish ? 'Ø³Û•Ø±Ú©Û•ÙˆØªÙˆÙˆ Ø¨ÙˆÙˆ' : isArabic ? 'Ù†Ø¬Ø§Ø­' : 'Stock Added Successfully'),
                      backgroundColor: Colors.green,
                    )
                  );
                }
              },
              child: Text(addLbl),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryRepo = ref.watch(inventoryRepositoryProvider);
    final productsStream = inventoryRepo.watchAllProducts();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';

    final title = localizations.inventory;
    final searchHint = localizations.searchInventory;
    final allProducts = localizations.all;
    final lowStockWarnings = localizations.lowStock;
    final noData = localizations.noData;
    final lowLabel = isKurdish ? 'کەم ماوە' : isArabic ? 'كمية قليلة' : 'LOW';
    final registerFirst = isKurdish ? 'یەکەم بەرهەم تۆمار بکە' : isArabic ? 'سجل منتجك الأول' : 'Register Your First Product';
    final newProductLabel = isKurdish ? 'بەرهەمی نوێ' : isArabic ? 'منتج جديد' : 'New Product';

    return StreamBuilder<List<ProductEntity>>(
      stream: productsStream,
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final hasProducts = products.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          floatingActionButton: hasProducts
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 96.0),
                  child: HeavyIOSButton(
                    onTap: () => context.push(Routes.productForm),
                    label: newProductLabel,
                    icon: Icons.add_box,
                  ),
                )
              : null,
      body: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(allProducts),
                  selected: _selectedFilter == 'all',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'all');
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'all' ? theme.colorScheme.primary : Colors.grey.shade600,
                    fontWeight: _selectedFilter == 'all' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(lowStockWarnings),
                  selected: _selectedFilter == 'low',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'low');
                  },
                  selectedColor: Colors.red.withValues(alpha: 0.1),
                  checkmarkColor: Colors.red,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'low' ? Colors.red : Colors.grey.shade600,
                    fontWeight: _selectedFilter == 'low' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoader());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // Use the products from the outer snapshot

                final filtered = products.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesFilter = _selectedFilter == 'all' ||
                      (_selectedFilter == 'low' && p.stockQuantity < 10.0);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(noData, style: TextStyle(color: Colors.grey.shade500)),
                        if (products.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.push(Routes.productForm),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: Text(registerFirst),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 120),
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    final isLowStock = product.stockQuantity < 10.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isLowStock
                              ? (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5))
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.withValues(alpha: 0.1) : theme.colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: product.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(product.imageUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  isLowStock ? Icons.warning : Icons.inventory_2,
                                  color: isLowStock ? Colors.red : theme.colorScheme.primary,
                                ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Text(
                                CurrencyFormatter.formatQuantity(product.stockQuantity, isKurdish ? (product.unitType == 'bag' ? 'فەردە' : product.unitType == 'kg' ? 'کیلۆگرام' : product.unitType == 'ton' ? 'تۆن' : product.unitType == 'box' ? 'کارتۆن' : product.unitType) : isArabic ? (product.unitType == 'bag' ? 'كيس' : product.unitType == 'kg' ? 'كيلوغرام' : product.unitType == 'ton' ? 'طن' : product.unitType == 'box' ? 'صندوق' : product.unitType) : product.unitType),
                                style: TextStyle(
                                  color: isLowStock ? Colors.red : Colors.grey.shade600,
                                  fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              if (isLowStock) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    lowLabel,
                                    style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(product.sellPrice),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(height: 3),
                                Builder(builder: (_) {
                                  final margin = product.buyPrice > 0
                                      ? ((product.sellPrice - product.buyPrice) / product.buyPrice * 100)
                                      : 0.0;
                                  final marginColor = margin > 15
                                      ? Colors.green
                                      : margin > 0
                                          ? Colors.amber.shade700
                                          : Colors.red;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: marginColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${margin >= 0 ? '+' : ''}${margin.toStringAsFixed(0)}%',
                                      style: TextStyle(color: marginColor, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(Icons.add_shopping_cart, color: theme.colorScheme.primary),
                              onPressed: () => _showRestockDialog(product),
                              tooltip: isKurdish ? 'Ø²ÛŒØ§Ø¯Ú©Ø±Ø¯Ù†ÛŒ Ú©Û†Ú¯Ø§' : isArabic ? 'Ø¥Ø¶Ø§ÙØ© Ù…Ø®Ø²ÙˆÙ†' : 'Add Stock',
                            ),
                          ],
                        ),
                        onTap: () {
                          context.push(Routes.productForm, extra: product);
                        },
                      ),
                    ).animate().slideY(begin: 0.1, end: 0, duration: 200.ms, delay: (index * 20).ms);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  });
  }
}


