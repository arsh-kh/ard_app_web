import 'package:flutter/material.dart';
import '../../core/utils/pdf_interceptor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/providers/purchase_providers.dart';

import '../../core/providers/inventory_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/purchase_entity.dart';
import '../../data/models/purchase_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../../core/widgets/heavy_ios_button.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/services/html_generator_service.dart';
import 'purchase_return_screen.dart';
import '../../core/utils/app_date_range_picker.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/widgets/animated_segmented_pill.dart';
import '../../core/widgets/premium_sort_dropdown.dart';
import '../../domain/enums.dart';
import '../../core/providers/sort_preferences_provider.dart';
import 'purchase_report_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Outer shell — loads data only; filter state lives in _PurchasesBody
// ─────────────────────────────────────────────────────────────────────────────
class PurchasesScreen extends ConsumerWidget {
  final bool isEmbedded;
  final String? initialSearchQuery;
  const PurchasesScreen({
    super.key,
    this.isEmbedded = false,
    this.initialSearchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return purchasesAsync.when(
      loading: () =>
          const Scaffold(resizeToAvoidBottomInset: false, body: ListSkeleton()),
      error: (err, _) => Scaffold(
        body: Center(child: Text('${Tr.t('errorPrefix', lang)}$err')),
      ),
      data: (purchases) => Scaffold(
        backgroundColor: isEmbedded ? Colors.transparent : null,
        body: _PurchasesBody(
          // Stable key: preserves scroll/filter state when provider refreshes
          key: const ValueKey('purchases_body'),
          purchases: purchases,
          lang: lang,
          isEmbedded: isEmbedded,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PurchasesBody — owns all filter/search/scroll state
// setState here never causes purchasesProvider to reload
// ─────────────────────────────────────────────────────────────────────────────
class _PurchasesBody extends ConsumerStatefulWidget {
  final List<PurchaseEntity> purchases;
  final String lang;
  final bool isEmbedded;
  final String? initialSearchQuery;

  const _PurchasesBody({
    super.key,
    required this.purchases,
    required this.lang,
    required this.isEmbedded,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<_PurchasesBody> createState() => _PurchasesBodyState();
}

class _PurchasesBodyState extends ConsumerState<_PurchasesBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final FocusNode _searchFocusNode = SelectAllFocusNode(
    controller: _searchCtrl,
  );
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery = '';
  String _selectedPeriod = 'all'; // all | today | week | month | custom
  DateTimeRange? _customRange;
  bool _isScrolled = false;
  final Map<String, String> _purchaseIdToProductNames = {};

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.hasClients && _scrollCtrl.offset > 60;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchCtrl.text = _searchQuery;
    }
    Future.microtask(_loadSearchData);
  }

  Future<void> _loadSearchData() async {
    final purchaseRepo = ref.read(purchaseRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);
    try {
      final products = await inventoryRepo.getAllProducts();
      final productMap = {for (var p in products) p.id: p.name.toLowerCase()};

      final allItems = await purchaseRepo.getAllPurchaseItems();
      final Map<String, List<PurchaseItemEntity>> itemsByPurchase = {};
      for (final item in allItems) {
        itemsByPurchase.putIfAbsent(item.purchaseId, () => []).add(item);
      }

      for (final p in widget.purchases) {
        final items = itemsByPurchase[p.id] ?? [];
        final names = items.map((i) => productMap[i.productId] ?? '').join(' ');
        _purchaseIdToProductNames[p.id] = names;
      }
    } catch (e) {
      // Ignore errors silently for search cache
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return date.isAfter(
          DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day,
          ).subtract(const Duration(seconds: 1)),
        );
      case 'month':
        return date.year == now.year && date.month == now.month;
      case 'custom':
        if (_customRange == null) return true;
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      default:
        return true;
    }
  }

  List<PurchaseEntity> _applyFilters(List<PurchaseEntity> purchases) {
    return purchases.where((p) {
      if (!_matchesPeriod(p.purchaseDate)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final names = _purchaseIdToProductNames[p.id]?.toLowerCase() ?? '';
        final number = (p.purchaseNumber?.toString() ?? p.id.substring(0, 8))
            .toLowerCase();

        if (!names.contains(q) && !number.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      langCode: widget.lang,
      initialDateRange: _customRange,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedPeriod = 'custom';
      });
    }
  }

  String _customRangeLabel() {
    if (_customRange == null) return Tr.t('periodCustom', widget.lang);
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(_customRange!.start)} – ${fmt.format(_customRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.lang;
    final selectedSort =
        ref.watch(sortPreferencesProvider)['purchases'] ??
        SortOptionType.dateDesc;

    final filtered = _applyFilters(widget.purchases);

    filtered.sort((a, b) {
      switch (selectedSort) {
        case SortOptionType.dateDesc:
          return b.purchaseDate.compareTo(a.purchaseDate);
        case SortOptionType.dateAsc:
          return a.purchaseDate.compareTo(b.purchaseDate);
        case SortOptionType.amountDesc:
          return b.totalAmount.compareTo(a.totalAmount);
        case SortOptionType.amountAsc:
          return a.totalAmount.compareTo(b.totalAmount);
        default:
          return 0;
      }
    });

    final totalAmount = filtered.fold<double>(
      0,
      (sum, p) => sum + (p.totalAmount - p.totalReturnedAmount),
    );

    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : null,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(Tr.t('purchaseHistory', lang)),
        centerTitle: true,
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: Directionality.of(context).name == 'rtl',
          hasBackButton: Navigator.canPop(context),
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
      body: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            floating: false,
            snap: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: Tr.t('searchPurchases', lang),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: AnimatedSegmentedPill<String>(
                          items: const [
                            'all',
                            'today',
                            'week',
                            'month',
                            'custom',
                          ],
                          selectedValue: _selectedPeriod,
                          onChanged: (val) {
                            if (val == 'custom') {
                              _pickCustomRange();
                            } else {
                              setState(() {
                                _selectedPeriod = val;
                                _customRange = null;
                              });
                            }
                          },
                          labelBuilder: (val) {
                            switch (val) {
                              case 'all':
                                return Tr.t('periodAll', lang);
                              case 'today':
                                return Tr.t('periodToday', lang);
                              case 'week':
                                return Tr.t('periodThisWeek', lang);
                              case 'month':
                                return Tr.t('periodThisMonth', lang);
                              case 'custom':
                                return _customRangeLabel();
                              default:
                                return '';
                            }
                          },
                          iconBuilder: (val) =>
                              val == 'custom' ? Icons.date_range_rounded : null,
                        ),
                      ),
                    ),
                  ),
                  PremiumSortDropdown<SortOptionType>(
                    selectedValue: selectedSort,
                    options: const [
                      SortOption(
                        labelKey: 'sortDateDesc',
                        icon: Icons.access_time,
                        value: SortOptionType.dateDesc,
                      ),
                      SortOption(
                        labelKey: 'sortDateAsc',
                        icon: Icons.history,
                        value: SortOptionType.dateAsc,
                      ),
                      SortOption(
                        labelKey: 'sortAmountDesc',
                        icon: Icons.arrow_downward,
                        value: SortOptionType.amountDesc,
                      ),
                      SortOption(
                        labelKey: 'sortAmountAsc',
                        icon: Icons.arrow_upward,
                        value: SortOptionType.amountAsc,
                      ),
                    ],
                    onSelected: (newSort) async {
                      await ref
                          .read(sortPreferencesProvider.notifier)
                          .setSort('purchases', newSort);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Summary Bar ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              Tr.t('summaryPurchases', lang, {
                                'count': filtered.length.toString(),
                                'total': CurrencyFormatter.format(totalAmount),
                              }),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const PurchaseReportDialog(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0xFF4D4D4D)
                                  : Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.print_rounded,
                              size: 14,
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Tr.t('auto_PurchasesReport', lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.surface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: AnimatedEmptyState(
                icon: Icons.receipt_long,
                title: _searchQuery.isNotEmpty || _selectedPeriod != 'all'
                    ? Tr.t('noResults', lang)
                    : Tr.t('noPurchasesYet', lang),
                subtitle: _searchQuery.isNotEmpty
                    ? Tr.t('tryDifferentKeywords', lang)
                    : null,
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: widget.isEmbedded ? 140 : 100,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PurchaseCard(
                    purchase: filtered[index],
                    index: index,
                    lang: lang,
                    isDark: isDark,
                    isEmbedded: widget.isEmbedded,
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Card
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseCard extends ConsumerWidget {
  final PurchaseEntity purchase;
  final int index;
  final String lang;
  final bool isDark;
  final bool isEmbedded;

  const _PurchaseCard({
    required this.purchase,
    required this.index,
    required this.lang,
    required this.isDark,
    required this.isEmbedded,
  });

  Color _statusColor() {
    switch (purchase.status) {
      case 'received':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _statusIcon() {
    switch (purchase.status) {
      case 'received':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time_filled;
      default:
        return Icons.inventory;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseRepo = ref.read(purchaseRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);
    final statusColor = _statusColor();
    final statusIcon = _statusIcon();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          '${Tr.t('purchaseLabel', lang)} #${purchase.purchaseNumber ?? index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(purchase.purchaseDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  Tr.t('status_${purchase.status}', lang).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(purchase.totalAmount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: purchase.hasReturn ? 12 : 16,
                decoration: purchase.hasReturn
                    ? TextDecoration.lineThrough
                    : null,
                color: purchase.hasReturn
                    ? Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5)
                    : null,
              ),
            ),
            if (purchase.hasReturn)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  CurrencyFormatter.format(
                    purchase.totalAmount - purchase.totalReturnedAmount,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E2E2E)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1C1C1E)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        Tr.t('purchasedItems', lang),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<PurchaseItemEntity>>(
                        future: purchaseRepo.getPurchaseItems(purchase.id),
                        builder: (context, itemsSnapshot) {
                          if (itemsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          final items = itemsSnapshot.data ?? [];
                          if (items.isEmpty) {
                            return Text(Tr.t('noItemsFound', lang));
                          }

                          double sumOfItems = 0;
                          for (final i in items) {
                            sumOfItems += i.quantity * i.unitPrice;
                          }
                          final double correctionRatio = (sumOfItems > 0 && sumOfItems != purchase.totalAmount) 
                              ? (purchase.totalAmount / sumOfItems) 
                              : 1.0;

                          return Column(
                            children: items.map((item) {
                              final rawItemGross = item.quantity * item.unitPrice;
                              final itemGross = rawItemGross * correctionRatio;
                              
                              final rawItemReturn = item.returnedQuantity * item.unitPrice;
                              final itemReturnDeduction = rawItemReturn * correctionRatio;
                              
                              final itemNet = itemGross - itemReturnDeduction;

                              return FutureBuilder<ProductEntity?>(
                                future: inventoryRepo.getProductById(
                                  item.productId,
                                ),
                                builder: (context, prodSnapshot) {
                                  final prodName =
                                      prodSnapshot.data?.name ??
                                      Tr.t('unknownProduct', lang);
                                  final unit =
                                      prodSnapshot.data?.unitType ?? '';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: item.returnedQuantity == 0
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '$prodName x ${item.quantity.toInt()} ${Tr.localiseUnit(unit, lang)}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.format(itemGross),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$prodName x ${item.quantity.toInt()} ${Tr.localiseUnit(unit, lang)}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    CurrencyFormatter.format(itemGross),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '- ${item.returnedQuantity.toInt()} ${Tr.t('retPrefix', lang)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.redAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '- ${CurrencyFormatter.format(itemReturnDeduction)}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.redAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (item.returnedQuantity <
                                                  item.quantity) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '= ${(item.quantity - item.returnedQuantity).toInt()} ${Tr.localiseUnit(unit, lang)}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                    Text(
                                                      CurrencyFormatter.format(itemNet),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<PurchaseItemEntity>>(
                  future: purchaseRepo.getPurchaseItems(purchase.id),
                  builder: (context, itemsSnapshot) {
                    if (!itemsSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    final items = itemsSnapshot.data!;
                    return Row(
                      children: [
                        Expanded(
                          child: HeavyIOSButton(
                            label: Tr.t('print', lang),
                            icon: Icons.print_rounded,
                            onTap: () async {
                              final products = <ProductEntity>[];
                              for (final item in items) {
                                final p = await inventoryRepo.getProductById(
                                  item.productId,
                                );
                                if (p != null) products.add(p);
                              }
                              if (!context.mounted) return;
                              if (!await PdfInterceptor.checkAndNavigate(context)) return;
                              await HtmlGeneratorService.generateAndLaunchPurchaseInvoice(
                                purchase: purchase,
                                items: items,
                                products: products,
                                isKurdish: lang == 'ku',
                                isArabic: lang == 'ar',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (purchase.status == 'received' &&
                            (purchase.totalAmount -
                                    purchase.totalReturnedAmount) >
                                0) ...[
                          Expanded(
                            child: HeavyIOSButton(
                              label: Tr.t('processReturn', lang),
                              icon: Icons.replay_rounded,
                              onTap: () async {
                                final products = <ProductEntity>[];
                                for (final item in items) {
                                  final p = await inventoryRepo.getProductById(
                                    item.productId,
                                  );
                                  if (p != null) products.add(p);
                                }
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PurchaseReturnScreen(
                                      purchase: purchase,
                                      items: items,
                                      products: products,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: HeavyIOSButton(
                            label: Tr.t('delete', lang),
                            icon: Icons.delete_outline,
                            color: Colors.red,
                            onTap: () async {
                              final confirmed =
                                  await AppFeedback.showConfirmDialog(
                                    context,
                                    title: Tr.t('deletePurchase', lang),
                                    message: Tr.t('deletePurchaseWarning', lang),
                                    confirmLabel: Tr.t('delete', lang),
                                  );
                              if (confirmed == true) {
                                try {
                                  final purchaseRepoW = ref.read(
                                    purchaseRepositoryProvider,
                                  );
                                  await purchaseRepoW.deletePurchase(purchase.id);
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(
                                      context,
                                      Tr.t('purchaseDeleted', lang),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    AppFeedback.showError(
                                      context,
                                      '${Tr.t('errorPrefix', lang)}$e',
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (20 * index.clamp(0, 15)).ms).slideX(begin: 0.05);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
