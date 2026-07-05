import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/inventory_providers.dart';
import '../../core/providers/cart_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/bouncing_widget.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/keep_alive_wrapper.dart';
import '../../core/widgets/universal_image.dart';
import '../../core/widgets/animated_segmented_pill.dart';
import '../../core/utils/feedback_utils.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/payment_entity.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/widgets/premium_sort_dropdown.dart';
import '../../core/providers/sort_preferences_provider.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode = SelectAllFocusNode(
    controller: _searchController,
  );
  final ScrollController _catalogScrollController = ScrollController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isCatalogScrolled = false;

  // Cart / Checkout State
  String? _selectedCustomerId;
  CustomerEntity? _selectedCustomer;
  bool _payCashImmediately = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _catalogScrollController.addListener(() {
      final isScrolled =
          _catalogScrollController.hasClients &&
          _catalogScrollController.offset > 50;
      if (isScrolled != _isCatalogScrolled) {
        setState(() {
          _isCatalogScrolled = isScrolled;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _catalogScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentLocale = ref.watch(localeProvider);
    final lang = currentLocale.languageCode;
    final title = Tr.t('posTitle', lang);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: Directionality.of(context).name == 'rtl',
          hasBackButton: Navigator.canPop(context),
          searchButton: _isCatalogScrolled
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_catalogScrollController.hasClients) {
                      _catalogScrollController.animateTo(
                        0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      );
                    }
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  },
                ).animate().fadeIn(duration: 200.ms)
              : null,
        ),
        actions: CustomTopBarHelper.buildActions(
          context: context,
          isRtl: Directionality.of(context).name == 'rtl',
          hasBackButton: Navigator.canPop(context),
          searchButton: _isCatalogScrolled
              ? IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_catalogScrollController.hasClients) {
                      _catalogScrollController.animateTo(
                        0,
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      );
                    }
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  },
                ).animate().fadeIn(duration: 200.ms)
              : null,
          extraActions: [
            Consumer(
              builder: (context, ref, child) {
                final cartItems = ref.watch(cartProvider);
                if (cartItems.isEmpty) return const SizedBox.shrink();

                final langCode = ref.watch(localeProvider).languageCode;
                final clearMsg = Tr.t('auto_ClearCartMessage', langCode);

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.remove_shopping_cart,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      final confirmed = await AppFeedback.showConfirmDialog(
                        context,
                        title: Tr.t('auto_Cancel', langCode),
                        message: clearMsg,
                        confirmLabel: Tr.t('yesBtn', langCode),
                        confirmColor: Colors.red,
                        icon: Icons.delete_sweep,
                      );
                      if (confirmed) {
                        ref.read(cartProvider.notifier).clearCart();
                        setState(() {
                          _selectedCustomerId = null;
                          _selectedCustomer = null;
                          _payCashImmediately = false;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          if (isLargeScreen) {
            // Split Screen Layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCartRegister(
                    context,
                    isDark,
                    lang,
                    isMobile: false,
                  ),
                ),
                Container(
                  width: 1,
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade300,
                ),
                Expanded(
                  flex: 5,
                  child: _buildProductCatalog(context, isDark, lang),
                ),
              ],
            );
          } else {
            // Single Column Layout for small screens (Stack with slide-up register)
            return Stack(
              children: [
                _buildProductCatalog(context, isDark, lang),
                _buildMobileCartOverlay(context, isDark, lang),
              ],
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // CATALOG SECTION (LEFT COLUMN)
  // ==========================================
  Widget _buildProductCatalog(BuildContext context, bool isDark, String lang) {
    final productsAsync = ref.watch(productsStreamProvider);
    final selectedSort =
        ref.watch(sortPreferencesProvider)['pos'] ?? SortOptionType.nameAsc;
    final searchHint = Tr.t('searchProducts', lang);
    final allProducts = Tr.t('allProducts', lang);

    return CustomScrollView(
      controller: _catalogScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Search Box
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AnimatedSegmentedPill<String>(
                        items: const ['all', 'bag', 'kg', 'ton', 'box'],
                        selectedValue: _selectedCategory,
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                        },
                        labelBuilder: (val) => val == 'all'
                            ? allProducts
                            : Tr.localiseUnit(val, lang),
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
                        .setSort('pos', newSort);
                  },
                ),
              ],
            ),
          ),
        ),

        // Product Grid
        productsAsync.when(
          loading: () => const SliverFillRemaining(child: ListSkeleton()),
          error: (error, stack) => SliverFillRemaining(
            child: Center(child: Text('${Tr.t('errorPrefix', lang)}$error')),
          ),
          data: (products) {
            final filtered = products.where((p) {
              final matchesSearch = p.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
              final matchesCat =
                  _selectedCategory == 'all' || p.unitType == _selectedCategory;
              return matchesSearch && matchesCat;
            }).toList();

            filtered.sort((a, b) {
              switch (selectedSort) {
                case SortOptionType.nameAsc:
                  return a.name.compareTo(b.name);
                case SortOptionType.nameDesc:
                  return b.name.compareTo(a.name);
                case SortOptionType.priceAsc:
                  return a.sellPrice.compareTo(b.sellPrice);
                case SortOptionType.priceDesc:
                  return b.sellPrice.compareTo(a.sellPrice);
                case SortOptionType.stockAsc:
                  return a.stockQuantity.compareTo(b.stockQuantity);
                case SortOptionType.stockDesc:
                  return b.stockQuantity.compareTo(a.stockQuantity);
                default:
                  return 0;
              }
            });

            if (filtered.isEmpty) {
              return SliverFillRemaining(
                child: AnimatedEmptyState(
                  title: AppLocalizations.of(context)!.noData,
                  icon: Icons.inventory_2_outlined,
                  subtitle: searchHint,
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom:
                    190, // Extra padding to scroll past the mobile cart overlay and nav bar
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filtered[index];
                  return KeepAliveWrapper(
                    child: _buildProductCard(context, product, isDark, lang),
                  );
                }, childCount: filtered.length),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    ProductEntity product,
    bool isDark,
    String lang,
  ) {
    final theme = Theme.of(context);
    final outOfStockStr = AppLocalizations.of(context)!.outOfStock;
    final isOutOfStock = product.stockQuantity <= 0;

    return BouncingWidget(
      onTap: () {
        if (isOutOfStock) {
          AppFeedback.showError(context, outOfStockStr);
          return;
        }
        _showQuantityInputDialog(
          context,
          product,
          ref.read(cartProvider.notifier),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: product.imageUrl != null
                        ? UniversalImage(product.imageUrl!, fit: BoxFit.cover)
                        : Container(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(product.sellPrice)} / ${Tr.localiseUnit(product.unitType, lang)}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isOutOfStock
                                  ? outOfStockStr
                                  : Tr.t('pos_inStock', lang, {
                                      'count': product.stockQuantity
                                          .toInt()
                                          .toString(),
                                    }),
                              style: TextStyle(
                                color: isOutOfStock
                                    ? Colors.red
                                    : Colors.grey.shade500,
                                fontSize: 10,
                                fontWeight: isOutOfStock
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isOutOfStock)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuantityInputDialog(
    BuildContext context,
    ProductEntity product,
    CartNotifier cartNotifier,
  ) {
    final controller = TextEditingController();
    final focusNode = SelectAllFocusNode(controller: controller);

    final langCode = ref.read(localeProvider).languageCode;
    final title = Tr.t('auto_EnterQuantityFor', langCode, {
      'name': product.name,
    });
    final hint = Tr.t('auto_Quantity', langCode);
    final cancelText = Tr.t('auto_Cancel', langCode);
    final addText = Tr.t('auto_Update', langCode);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              ArabicToEnglishFormatter(),
              CurrencyInputFormatter(),
            ],
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: '0',
              labelText: hint,
            ),
            onSubmitted: (val) {
              final newQty = CurrencyFormatter.tryParse(val);
              if (newQty != null &&
                  newQty > 0 &&
                  newQty <= product.stockQuantity) {
                cartNotifier.addProduct(product, newQty);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                final newQty = CurrencyFormatter.tryParse(controller.text);
                if (newQty != null &&
                    newQty > 0 &&
                    newQty <= product.stockQuantity) {
                  cartNotifier.addProduct(product, newQty);
                  Navigator.pop(context);
                } else {
                  AppFeedback.showError(context, Tr.t('auto_Invalidquantity', langCode));
                }
              },
              child: Text(addText),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // REGISTER SECTION (RIGHT COLUMN)
  // ==========================================
  Widget _buildCartRegister(
    BuildContext context,
    bool isDark,
    String lang, {
    bool isMobile = false,
  }) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final assignCustomerStr = Tr.t('auto_AssignCustomer', lang);

    return Container(
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Column(
        mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Header - Customer Selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: InkWell(
              onTap: () async {
                final selected = await context.push<CustomerEntity?>(
                  Routes.customerSelection,
                );
                if (selected != null) {
                  setState(() {
                    _selectedCustomerId = selected.id;
                    _selectedCustomer = selected;
                  });
                } else {
                  setState(() {
                    _selectedCustomerId = null;
                    _selectedCustomer = null;
                    _payCashImmediately = false;
                  });
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignCustomerStr,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedCustomerId == null
                                ? Tr.t('selectCustomer', lang)
                                : Tr.localiseCustomerName(
                                    _selectedCustomer?.businessName,
                                    lang,
                                  ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          // Debt Warning
          if (_selectedCustomer != null && _selectedCustomer!.debtBalance > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              color: Colors.amber.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${Tr.t('auto_Debt', lang)}: ${CurrencyFormatter.format(_selectedCustomer!.debtBalance)}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Cart Items List
          if (isMobile)
            Flexible(
              child: cartItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Tr.t('cartEmpty', lang),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _buildCartItemTile(context, cartItems[index], theme),
                    ),
            )
          else
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Tr.t('cartEmpty', lang),
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: cartItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _buildCartItemTile(context, cartItems[index], theme),
                    ),
            ),

          // Totals & Actions (Bottom)
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.totalAmount,
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.format(cartNotifier.totalCartPrice),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCustomerId != null &&
                      !(_selectedCustomerId!.startsWith('walk-in-')))
                    StatefulBuilder(
                      builder:
                          (BuildContext context, StateSetter setStateCheckbox) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                Tr.t('auto_PayCashImmediately', lang),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              value: _payCashImmediately,
                              onChanged: (val) {
                                setStateCheckbox(() {
                                  _payCashImmediately = val ?? false;
                                });
                              },
                              activeColor: theme.colorScheme.primary,
                            );
                          },
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_selectedCustomerId == null) {
                                final selected = await GoRouter.of(context)
                                    .push<CustomerEntity?>(
                                  Routes.customerSelection,
                                );
                                if (selected != null) {
                                  setState(() {
                                    _selectedCustomerId = selected.id;
                                    _selectedCustomer = selected;
                                  });
                                } else {
                                  return; // User backed out without selecting
                                }
                              }
                              setState(() => _isSubmitting = true);
                              try {
                                await _processCheckout(
                                  ref,
                                  cartItems,
                                  cartNotifier.totalCartPrice,
                                  _selectedCustomerId?.startsWith('walk-in-') ?? false,
                                  _payCashImmediately,
                                );
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                }
                              }
                            },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.onPrimary,
                            ),
                      label: Text(
                        Tr.t('auto_Checkout', lang),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemTile(
    BuildContext context,
    CartItem item,
    ThemeData theme,
  ) {
    return Dismissible(
      key: ValueKey(item.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        color: Colors.red,
        padding: const EdgeInsetsDirectional.only(end: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(cartProvider.notifier).removeProduct(item.product.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${item.quantity}x ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: Text(
                      item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BouncingWidget(
              onTap: () => _editPrice(context, item, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      CurrencyFormatter.format(item.customPrice),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CurrencyFormatter.format(item.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.end,
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Overlay showing a mini summary that opens the register
  Widget _buildMobileCartOverlay(
    BuildContext context,
    bool isDark,
    String lang,
  ) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    if (cartItems.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 16,
      right: 16,
      bottom:
          MediaQuery.of(context).padding.bottom +
          110, // Avoid overlapping with main nav bar (height 95)
      child: BouncingWidget(
        onTap: () {
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141414) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Flexible(
                      child: _buildCartRegister(
                        context,
                        isDark,
                        lang,
                        isMobile: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child:
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
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
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cartItems.length}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.totalAmount,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              cartNotifier.totalCartPrice,
                            ),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        Tr.t('auto_Checkout', lang),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().slideY(
              begin: 1,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            ),
      ),
    );
  }

  // ==========================================
  // HELPERS
  // ==========================================
  void _editPrice(BuildContext context, CartItem item, WidgetRef ref) {
    final langCode = ref.read(localeProvider).languageCode;
    final formatter = NumberFormat('#,###');
    final controller = TextEditingController(
      text: formatter.format(item.customPrice),
    );
    final focusNode = SelectAllFocusNode(controller: controller);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Tr.t('auto_EditPrice', langCode)),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            ArabicToEnglishFormatter(),
            CurrencyInputFormatter(),
          ],
          autofocus: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: Tr.t('auto_Priceperunit', langCode),
            hintText: '0',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(Tr.t('auto_Cancel', langCode)),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = CurrencyFormatter.tryParse(controller.text);
              if (newPrice != null && newPrice >= 0) {
                ref
                    .read(cartProvider.notifier)
                    .updateProductPrice(item.product, newPrice);
                Navigator.pop(ctx);
              }
            },
            child: Text(Tr.t('auto_Save', langCode)),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout(
    WidgetRef ref,
    List<CartItem> cartItems,
    double totalAmount,
    bool isQuickSell,
    bool payCashImmediately,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);
    final lang = currentLocale.languageCode;

    final customerName = _selectedCustomerId == null
        ? Tr.t('selectCustomer', lang)
        : Tr.localiseCustomerName(_selectedCustomer?.businessName, lang);
    final confirmOrderStr = Tr.t('auto_ConfirmOrder', lang);

    final confirmBody = Tr.t('auto_ConfirmOrderBody', lang, {
      'amount': CurrencyFormatter.format(totalAmount),
      'customerName': customerName,
    });

    final confirmed = await AppFeedback.showConfirmDialog(
      context,
      title: confirmOrderStr,
      message: confirmBody,
      confirmLabel: localizations.confirm,
      icon: Icons.shopping_cart_checkout,
    );

    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final String finalCustomerId = _selectedCustomerId ?? 'walk-in-anonymous';
      final orderRepo = ref.read(orderRepositoryProvider);

      final orderId = const Uuid().v4();
      double totalCogs = 0;
      for (final item in cartItems) {
        totalCogs += item.product.buyPrice * item.quantity;
      }

      final order = OrderEntity(
        id: orderId,
        customerId: finalCustomerId,
        totalAmount: totalAmount,
        totalCogs: totalCogs,
        orderDate: DateTime.now(),
      );

      final items = cartItems
          .map(
            (item) => OrderItemEntity(
              id: const Uuid().v4(),
              orderId: orderId,
              productId: item.product.id,
              quantity: item.quantity,
              unitPrice: item.customPrice,
            ),
          )
          .toList();

      if (isQuickSell || payCashImmediately) {
        final payment = PaymentEntity(
          id: const Uuid().v4(),
          customerId: finalCustomerId,
          amount: totalAmount,
          paymentDate: DateTime.now(),
        );
        await orderRepo.createOrderWithPayment(order, items, payment);
      } else {
        await orderRepo.createOrder(order, items);
      }

      await ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'order_submitted',
            message:
                'Order for ${_selectedCustomer?.businessName ?? 'Walk-In'} submitted successfully.',
            type: 'order',
            route: '${Routes.adminOrders}?search=${orderId.substring(0, 8)}',
          );

      ref.read(cartProvider.notifier).clearCart();

      // reset customer
      setState(() {
        _selectedCustomerId = null;
        _selectedCustomer = null;
        _payCashImmediately = false;
      });

      if (mounted) {
        AppFeedback.showSuccess(context, localizations.success);
        if (MediaQuery.of(context).size.width <= 800) {
          // if we were in the bottom sheet
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
