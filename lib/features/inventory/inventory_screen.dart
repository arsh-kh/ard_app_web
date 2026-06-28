import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/heavy_ios_button.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/universal_image.dart';
import '../../core/widgets/animated_segmented_pill.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../domain/enums.dart';
import '../../core/providers/sort_preferences_provider.dart';
import '../../core/widgets/premium_sort_dropdown.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const InventoryScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final isScrolled = _scrollCtrl.hasClients && _scrollCtrl.offset > 50;
      if (isScrolled != _isScrolled) {
        setState(() => _isScrolled = isScrolled);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsStreamProvider);
    final selectedSort =
        ref.watch(sortPreferencesProvider)['inventory'] ??
        SortOptionType.nameAsc;
    final products = productsAsync.valueOrNull ?? [];
    final theme = Theme.of(context);


    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;

    final title = Tr.t('inventory', langCode);
    final searchHint = Tr.t('searchProducts', langCode);
    final allProducts = Tr.t('allProducts', langCode);
    final lowStockWarnings = Tr.t('lowStock', langCode);
    final noData = Tr.t('noData', langCode);
    final lowLabel = Tr.t('lowLabel', langCode);
    final outOfStockLabel = Tr.t('outOfStock', langCode);
    final registerFirst = Tr.t('firstProduct', langCode);
    final newProductLabel = Tr.t('newProduct', langCode);

    final hasProducts = products.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title),
        centerTitle: true,
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: Directionality.of(context).name == 'rtl',
          hasBackButton: Navigator.canPop(context),
          historyButton: IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(Routes.purchases),
            tooltip: Tr.t('purchaseHistory', langCode),
          ),
          searchButton: _isScrolled
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  },
                ).animate().fadeIn(duration: 200.ms)
              : null,
        ),
        actions: CustomTopBarHelper.buildActions(
          context: context,
          isRtl: Directionality.of(context).name == 'rtl',
          hasBackButton: Navigator.canPop(context),
          historyButton: IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push(Routes.purchases),
            tooltip: Tr.t('purchaseHistory', langCode),
          ),
          searchButton: _isScrolled
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _scrollCtrl.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  },
                ).animate().fadeIn(duration: 200.ms)
              : null,
        ),
      ),
      floatingActionButtonLocation:
          Directionality.of(context) == TextDirection.rtl
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: hasProducts
          ? Padding(
              padding: EdgeInsets.only(bottom: widget.isEmbedded ? 96.0 : 0),
              child: HeavyIOSButton(
                onTap: () => context.push(Routes.productForm),
                label: newProductLabel,
                icon: Icons.add_box,
              ),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
              pinned: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(76),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: AnimatedSegmentedPill<String>(
                          items: const ['all', 'low'],
                          selectedValue: _selectedFilter,
                          onChanged: (val) {
                            setState(() => _selectedFilter = val);
                          },
                          labelBuilder: (val) =>
                              val == 'all' ? allProducts : lowStockWarnings,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PremiumSortDropdown<SortOptionType>(
                    selectedValue: selectedSort,
                    options: const [
                      SortOption(
                        labelKey: 'sortNameAsc',
                        icon: Icons.sort_by_alpha,
                        value: SortOptionType.nameAsc,
                      ),
                      SortOption(
                        labelKey: 'sortNameDesc',
                        icon: Icons.sort_by_alpha,
                        value: SortOptionType.nameDesc,
                      ),
                      SortOption(
                        labelKey: 'sortPriceDesc',
                        icon: Icons.arrow_downward,
                        value: SortOptionType.priceDesc,
                      ),
                      SortOption(
                        labelKey: 'sortPriceAsc',
                        icon: Icons.arrow_upward,
                        value: SortOptionType.priceAsc,
                      ),
                      SortOption(
                        labelKey: 'sortStockDesc',
                        icon: Icons.arrow_downward,
                        value: SortOptionType.stockDesc,
                      ),
                      SortOption(
                        labelKey: 'sortStockAsc',
                        icon: Icons.arrow_upward,
                        value: SortOptionType.stockAsc,
                      ),
                    ],
                    onSelected: (newSort) async {
                      await ref
                          .read(sortPreferencesProvider.notifier)
                          .setSort('inventory', newSort);
                    },
                  ),
                ],
              ),
            ),
          ),
          productsAsync.when(
            loading: () => const SliverFillRemaining(child: ListSkeleton()),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('${Tr.t('errorPrefix', langCode)}$error'),
              ),
            ),
            data: (_) {
              final filtered = products.where((p) {
                final matchesSearch = p.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
                final matchesFilter =
                    _selectedFilter == 'all' ||
                    (_selectedFilter == 'low' &&
                        p.stockQuantity <= (p.lowStockThreshold ?? 30.0));
                return matchesSearch && matchesFilter;
              }).toList();

              if (selectedSort == SortOptionType.nameAsc) {
                filtered.sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              } else if (selectedSort == SortOptionType.nameDesc) {
                filtered.sort(
                  (a, b) =>
                      b.name.toLowerCase().compareTo(a.name.toLowerCase()),
                );
              } else if (selectedSort == SortOptionType.priceAsc) {
                filtered.sort((a, b) => a.sellPrice.compareTo(b.sellPrice));
              } else if (selectedSort == SortOptionType.priceDesc) {
                filtered.sort((a, b) => b.sellPrice.compareTo(a.sellPrice));
              } else if (selectedSort == SortOptionType.stockAsc) {
                filtered.sort(
                  (a, b) => a.stockQuantity.compareTo(b.stockQuantity),
                );
              } else if (selectedSort == SortOptionType.stockDesc) {
                filtered.sort(
                  (a, b) => b.stockQuantity.compareTo(a.stockQuantity),
                );
              }

              if (!hasProducts) {
                return SliverFillRemaining(
                  child: AnimatedEmptyState(
                    title: noData,
                    icon: Icons.inventory_2_outlined,
                    subtitle: registerFirst,
                    actionLabel: newProductLabel,
                    onAction: () => context.push(Routes.productForm),
                  ),
                );
              }

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: AnimatedEmptyState(
                    title: Tr.t('noResults', langCode),
                    icon: Icons.search_off,
                    subtitle: Tr.t('tryDifferentKeywords', langCode),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = filtered[index];
                    final lowStockLimit = product.lowStockThreshold ?? 30.0;
                    final isLowStock =
                        product.stockQuantity > 0 &&
                        product.stockQuantity <= lowStockLimit;
                    final isOutOfStock = product.stockQuantity <= 0;
                    final isAlert = isLowStock || isOutOfStock;

                    return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isAlert
                                  ? (theme.colorScheme.onSurface.withValues(alpha: 0.5))
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isAlert
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: product.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: UniversalImage(
                                        product.imageUrl!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      isAlert
                                          ? Icons.warning
                                          : Icons.inventory_2,
                                      color: isAlert
                                          ? Colors.red
                                          : theme.colorScheme.primary,
                                    ),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    CurrencyFormatter.formatQuantity(
                                      product.stockQuantity,
                                      Tr.localiseUnit(
                                        product.unitType,
                                        langCode,
                                      ),
                                    ),
                                    style: TextStyle(
                                      color: isAlert
                                          ? Colors.red
                                          : Colors.grey.shade600,
                                      fontWeight: isAlert
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (isAlert)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isOutOfStock
                                            ? outOfStockLabel
                                            : lowLabel,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
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
                                      CurrencyFormatter.format(
                                        product.sellPrice,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Builder(
                                      builder: (_) {
                                        final profit =
                                            product.sellPrice -
                                            product.buyPrice;
                                        final profitColor = profit > 0
                                            ? Colors.green
                                            : profit < 0
                                            ? Colors.red
                                            : Colors.grey.shade600;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: profitColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            '${profit > 0 ? '+' : ''}${CurrencyFormatter.format(profit)}',
                                            style: TextStyle(
                                              color: profitColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push(Routes.productForm, extra: product);
                            },
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 300.ms,
                          delay: (20 * index.clamp(0, 15)).ms,
                        )
                        .slideX(begin: 0.05);
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
