import '../../core/utils/app_translations.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/order_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/routing/routes.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/pdf_invoice_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/widgets/shimmer_list_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/heavy_ios_button.dart';
import '../../core/widgets/pdf_preview_screen.dart';
import '../../core/providers/locale_provider.dart';
import '../../data/models/order_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import '../../core/widgets/animated_segmented_pill.dart';
import '../../core/widgets/premium_sort_dropdown.dart';
import '../../domain/enums.dart';
import '../../core/providers/sort_preferences_provider.dart';
import '../../core/utils/feedback_utils.dart';
import 'order_report_dialog.dart';
import 'order_return_screen.dart';
import '../../core/utils/app_date_range_picker.dart';
import '../customers/history_hub_screen.dart';
import '../../core/utils/focus_utils.dart';

class _LocalTranslations {
  static const _msgTemplates = {
    'en': {
      'rejectOrderMsg':
          'This will cancel order #{orderId} for {client}. This action cannot be undone.',
      'orderRejectedMsg': 'Order #{orderId} for {client} was rejected.',
      'approveOrderMsg':
          'Approve order #{orderId} for {client}?\n\nStock will be deducted from inventory.',
      'orderApprovedMsg':
          'Order #{orderId} for {client} approved. Stock deducted.',
      'markDeliveredMsg':
          'This will mark order #{orderId} as delivered and add {amount} to {client}\'s debt ledger.',
      'orderDeliveredMsg':
          'Order #{orderId} delivered. Customer debt ledger updated.',
      'errorGeneratingInvoice': 'Error generating invoice: {error}',
    },
    'ku': {
      'rejectOrderMsg':
          'ئەم داواکاری #{orderId} بۆ {client} هەڵدەوەشێنرێتەوە. ئەم کارە ناگەڕێتەوە.',
      'orderRejectedMsg': 'داواکاری #{orderId} بۆ {client} ڕەتکرایەوە.',
      'approveOrderMsg':
          'داواکاری #{orderId} بۆ {client} پەسەند دەکەیت؟\n\nکاڵا لە کۆگا کەم دەکرێتەوە.',
      'orderApprovedMsg':
          'داواکاری #{orderId} بۆ {client} پەسەندکرا. کاڵا کەمکرایەوە.',
      'markDeliveredMsg':
          'ئەم داواکاری #{orderId} وەک گەیەنراو دیاری دەکات و {amount} دەخاتە سەر قەرزی {client}.',
      'orderDeliveredMsg':
          'داواکاری #{orderId} گەیەنرا. قەرزی کڕیار نوێکرایەوە.',
      'errorGeneratingInvoice': 'هەڵە لە دروستکردنی پسووڵە: {error}',
    },
    'ar': {
      'rejectOrderTitle': 'رفض الطلب؟',
      'rejectOrderMsg':
          'سيؤدي هذا إلى إلغاء الطلب #{orderId} لـ {client}. لا يمكن التراجع عن هذا الإجراء.',
      'orderRejectedTitle': 'تم رفض الطلب',
      'orderRejectedMsg': 'تم رفض الطلب #{orderId} للعميل {client}.',
      'orderRejectedInfo': 'تم رفض الطلب',
      'approveOrderTitle': 'الموافقة على الطلب؟',
      'approveOrderMsg':
          'هل توافق على الطلب #{orderId} لـ {client}?\n\nسيتم خصم المخزون من المستودع.',
      'orderApprovedTitle': 'تمت الموافقة على الطلب',
      'orderApprovedMsg':
          'تمت الموافقة على الطلب #{orderId} لـ {client}. تم خصم المخزون.',
      'orderApprovedSuccess': 'تمت الموافقة على الطلب!',
      'markDeliveredTitle': 'تحديد كمسلم؟',
      'markDeliveredMsg':
          'سيؤدي هذا إلى تحديد الطلب #{orderId} كمسلم وإضافة {amount} إلى سجل ديون {client}.',
      'orderDeliveredTitle': 'تم توصيل الطلب',
      'orderDeliveredMsg':
          'تم توصيل الطلب #{orderId}. تم تحديث سجل ديون العميل.',
      'orderDeliveredSuccess': 'تم تحديد الطلب كمسلم!',
      'errorGeneratingInvoice': 'خطأ في إنشاء الفاتورة: {error}',
    },
  };

  static String get(String key, String langCode) {
    final langMap = _msgTemplates[langCode] ?? _msgTemplates['en']!;
    return langMap[key] ?? key;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Outer shell — only handles stream subscription + Scaffold wrapper
// Filter state lives in _OrdersBody so setState there never bubbles up here
// ─────────────────────────────────────────────────────────────────────────────
class AdminOrdersScreen extends ConsumerWidget {
  final bool isEmbedded;
  final String? initialSearchQuery;

  const AdminOrdersScreen({super.key, this.isEmbedded = false, this.initialSearchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    String t(String key) {
      final local = _LocalTranslations.get(key, langCode);
      return local == key ? Tr.t(key, langCode) : local;
    }

    final orderRepo = ref.watch(orderRepositoryProvider);

    return StreamBuilder<List<OrderEntity>>(
      stream: orderRepo.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(resizeToAvoidBottomInset: false,
      body: ShimmerListLoader());
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${Tr.t('errorPrefix', langCode)}${snapshot.error}'),
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        final pastOrders = allOrders
            .where(
              (o) =>
                  o.status == OrderStatus.delivered.value ||
                  o.status == OrderStatus.cancelled.value,
            )
            .toList();

        return Scaffold(
          backgroundColor: isEmbedded ? Colors.transparent : null,
          body: _OrdersBody(
            // Stable key ensures state (scroll, filters) is preserved
            // when the stream emits new data
            key: const ValueKey('admin_orders_body'),
            orders: pastOrders,
            langCode: langCode,
            t: t,
            isEmbedded: isEmbedded,
            onPrint: (order) => _printInvoice(context, ref, order, t),
            initialSearchQuery: initialSearchQuery,
          ),
        );
      },
    );
  }

  Future<void> _printInvoice(
    BuildContext context,
    WidgetRef ref,
    OrderEntity order,
    String Function(String) t,
  ) async {
    bool isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomLoader()),
    ).ignore();

    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final inventoryRepo = ref.read(inventoryRepositoryProvider);
      final orderRepo = ref.read(orderRepositoryProvider);

      final customer = await customerRepo.getCustomerById(order.customerId);
      final items = await orderRepo.getOrderItems(order.id);
      final products = await inventoryRepo.getAllProducts();

      if (context.mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }

      if (customer == null) throw Exception(t('error_customer_not_found'));

      final currentLocale = ref.read(localeProvider);
      final authState = ref.read(authProvider);
      final adminPhone = authState.user?.phone;
      final pdfBytes = await PdfInvoiceService.generateInvoice(
        order: order,
        customer: customer,
        items: items,
        products: products,
        isKurdish: currentLocale.languageCode == 'ku',
        isArabic: currentLocale.languageCode == 'ar',
        adminPhone: adminPhone,
      );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .push(
              MaterialPageRoute(
                builder: (_) => PdfPreviewScreen(
                  title:
                      'Invoice_${order.orderNumber?.toString() ?? order.id.substring(0, 8)}',
                  pdfBytes: pdfBytes,
                ),
              ),
            )
            .ignore();
      }
    } catch (e) {
      if (context.mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }
      if (context.mounted) {
        AppFeedback.showError(
          context,
          t('errorGeneratingInvoice').replaceFirst('{error}', e.toString()),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrdersBody — owns all filter/search/scroll state
// setState here never causes the StreamBuilder above to re-run
// ─────────────────────────────────────────────────────────────────────────────
class _OrdersBody extends ConsumerStatefulWidget {
  final List<OrderEntity> orders;
  final String langCode;
  final String Function(String) t;
  final bool isEmbedded;
  final void Function(OrderEntity) onPrint;
  final String? initialSearchQuery;

  const _OrdersBody({
    super.key,
    required this.orders,
    required this.langCode,
    required this.t,
    required this.isEmbedded,
    required this.onPrint,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends ConsumerState<_OrdersBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final FocusNode _searchFocusNode = SelectAllFocusNode(controller: _searchCtrl);
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery = '';
  String _selectedPeriod = 'all'; // all | today | week | month | custom
  DateTimeRange? _customRange;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
      _searchCtrl.text = _searchQuery;
    }
    _scrollCtrl.addListener(() {
      final scrolled = _scrollCtrl.hasClients && _scrollCtrl.offset > 60;
      if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
    });
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

  List<OrderEntity> _applyFilters(List<OrderEntity> orders) {
    return orders.where((o) {
      if (!_matchesPeriod(o.orderDate)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final orderNumStr = o.orderNumber?.toString().toLowerCase() ?? '';
        final idPrefix = o.id.substring(0, 8).toLowerCase();
        
        if (!orderNumStr.contains(q) && !idPrefix.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showAppDateRangePicker(
      context: context,
      langCode: widget.langCode,
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
    if (_customRange == null) return Tr.t('periodCustom', widget.langCode);
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(_customRange!.start)} – ${fmt.format(_customRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEmbedded) {
      ref.listen(historySearchTriggerProvider, (previous, next) {
        if (next != null) {
          final tabCtrl = DefaultTabController.maybeOf(context);
          if (tabCtrl != null && tabCtrl.index == 0) {
            _scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            FocusScope.of(context).requestFocus(_searchFocusNode);
          }
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.t;
    final langCode = widget.langCode;
    final selectedSort = ref.watch(sortPreferencesProvider)['orders'] ?? SortOptionType.dateDesc;

    final filtered = _applyFilters(widget.orders);
    
    filtered.sort((a, b) {
      switch (selectedSort) {
        case SortOptionType.dateDesc:
          return b.orderDate.compareTo(a.orderDate);
        case SortOptionType.dateAsc:
          return a.orderDate.compareTo(b.orderDate);
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
      (sum, o) => sum + (o.totalAmount - o.totalReturnedAmount),
    );

    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : null,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: Text(t('auto_OrderHistory')),
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
          // ── Collapsible AppBar ────────────────────────────────────────
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
            preferredSize: const Size.fromHeight(68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocusNode,
                onChanged: (v) => setState(() => _searchQuery = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: Tr.t('searchOrders', langCode),
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
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: AnimatedSegmentedPill<String>(
                        items: const ['all', 'today', 'week', 'month', 'custom'],
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
                            case 'all': return Tr.t('periodAll', langCode);
                            case 'today': return Tr.t('periodToday', langCode);
                            case 'week': return Tr.t('periodThisWeek', langCode);
                            case 'month': return Tr.t('periodThisMonth', langCode);
                            case 'custom': return _customRangeLabel();
                            default: return '';
                          }
                        },
                        iconBuilder: (val) => val == 'custom' ? Icons.date_range_rounded : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PremiumSortDropdown<SortOptionType>(
                  selectedValue: selectedSort,
                  options: const [
                    SortOption(labelKey: 'sortDateDesc', icon: Icons.access_time, value: SortOptionType.dateDesc),
                    SortOption(labelKey: 'sortDateAsc', icon: Icons.history, value: SortOptionType.dateAsc),
                    SortOption(labelKey: 'sortAmountDesc', icon: Icons.arrow_downward, value: SortOptionType.amountDesc),
                    SortOption(labelKey: 'sortAmountAsc', icon: Icons.arrow_upward, value: SortOptionType.amountAsc),
                  ],
                  onSelected: (newSort) async {
                    await ref.read(sortPreferencesProvider.notifier).setSort('orders', newSort);
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            Tr.t('summaryOrders', langCode, {
                              'count': filtered.length.toString(),
                              'total': CurrencyFormatter.format(totalAmount),
                            }),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                      builder: (_) => const OrderReportDialog(),
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
                            Icons.picture_as_pdf_rounded,
                            size: 14,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Tr.t('auto_InvoicesReport', langCode),
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

        // ── Orders List ───────────────────────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(
            child: AnimatedEmptyState(
              title: t('noOrderHistory'),
              icon: Icons.receipt_long_outlined,
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
                (context, index) => _OrderCard(
                  order: filtered[index],
                  index: index,
                  langCode: langCode,
                  t: t,
                  isDark: isDark,
                  onPrint: widget.onPrint,
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
// Individual Order Card
// ─────────────────────────────────────────────────────────────────────────────
class _OrderCard extends ConsumerWidget {
  final OrderEntity order;
  final int index;
  final String langCode;
  final String Function(String) t;
  final bool isDark;
  final void Function(OrderEntity) onPrint;

  const _OrderCard({
    required this.order,
    required this.index,
    required this.langCode,
    required this.t,
    required this.isDark,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerRepo = ref.read(customerRepositoryProvider);
    final theme = Theme.of(context);

    return FutureBuilder<CustomerEntity?>(
      future: customerRepo.getCustomerById(order.customerId),
      builder: (context, customerSnapshot) {
        final customer = customerSnapshot.data;
        final customerName = customer?.businessName ?? t('loadingClient');
        final isWalkIn =
            order.customerId == 'walk-in' ||
            order.customerId == 'walk-in-customer-id';
        final displayName = isWalkIn ? t('walkIn') : customerName;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              childrenPadding: EdgeInsets.zero,
              title: Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Row(
                  children: [
                    Text(
                      '${t('orderLabel')} #${order.orderNumber ?? index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM • HH:mm').format(order.orderDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: order.hasReturn ? 12 : 16,
                      decoration: order.hasReturn
                          ? TextDecoration.lineThrough
                          : null,
                      color: order.hasReturn ? Colors.grey : (Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  if (order.hasReturn)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        CurrencyFormatter.format(
                          order.totalAmount - order.totalReturnedAmount,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
              children: [
                _buildExpandedContent(
                  context,
                  ref,
                  customer,
                  customerName,
                  isWalkIn,
                ),
              ],
            ),
          ),
        ).animate()
          .fadeIn(duration: 300.ms, delay: (20 * index.clamp(0, 15)).ms)
          .slideX(begin: 0.05);
      },
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    WidgetRef ref,
    CustomerEntity? customer,
    String customerName,
    bool isWalkIn,
  ) {
    final orderRepo = ref.read(orderRepositoryProvider);
    final inventoryRepo = ref.read(inventoryRepositoryProvider);
    final customerRepo = ref.read(customerRepositoryProvider);
    final notifNotifier = ref.read(notificationProvider.notifier);
    final isDarkLocal = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: isDarkLocal
                ? const Color(0xFF2E2E2E)
                : Colors.grey.shade300,
          ),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customer?.address ?? t('noAddress'),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  t('orderedProducts'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<OrderItemEntity>>(
                  future: orderRepo.getOrderItems(order.id),
                  builder: (context, itemsSnapshot) {
                    if (itemsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CustomLoader(),
                      );
                    }
                    final items = itemsSnapshot.data ?? [];
                    return Column(
                      children: items.map((item) {
                        return FutureBuilder<ProductEntity?>(
                          future: inventoryRepo.getProductById(item.productId),
                          builder: (context, prodSnapshot) {
                            final prodName =
                                prodSnapshot.data?.name ?? t('unknownProduct');
                            final unit = prodSnapshot.data?.unitType ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.returnedQuantity == 0
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$prodName x ${item.quantity.toInt()} ${Tr.localiseUnit(unit, langCode)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.quantity * item.unitPrice),
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '$prodName x ${item.quantity.toInt()} ${Tr.localiseUnit(unit, langCode)}',
                                                style: const TextStyle(fontSize: 13, decoration: TextDecoration.lineThrough, color: Colors.grey),
                                              ),
                                            ),
                                            Text(
                                              CurrencyFormatter.format(item.quantity * item.unitPrice),
                                              style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '- ${item.returnedQuantity.toInt()} ${Tr.t('retPrefix', langCode)}',
                                              style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '- ${CurrencyFormatter.format(item.returnedQuantity * item.unitPrice)}',
                                              style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        if (item.returnedQuantity < item.quantity) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '= ${(item.quantity - item.returnedQuantity).toInt()} ${Tr.localiseUnit(unit, langCode)}',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
                                              ),
                                              Text(
                                                CurrencyFormatter.format((item.quantity - item.returnedQuantity) * item.unitPrice),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange),
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
          const SizedBox(height: 12),
          if (order.status == OrderStatus.pending.value) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      final confirmed = await AppFeedback.showConfirmDialog(
                        context,
                        title: t('rejectOrderTitle'),
                        message: t('rejectOrderMsg')
                            .replaceFirst(
                              '{orderId}',
                              order.id.substring(0, 8).toUpperCase(),
                            )
                            .replaceFirst('{client}', customerName),
                        confirmLabel: t('reject'),
                        confirmColor: Colors.red,
                        icon: Icons.cancel_outlined,
                      );
                      if (!confirmed) return;
                      await orderRepo.updateOrderStatus(
                        order.id,
                        OrderStatus.cancelled.value,
                      );
                      await notifNotifier.addNotification(
                        title: 'order_rejected',
                        message: 'Order of ${CurrencyFormatter.format(order.totalAmount)} for $customerName was rejected.',
                        type: 'order',
                        route: '${Routes.adminOrders}?search=${order.orderNumber ?? order.id.substring(0, 8)}',
                      );
                      if (context.mounted) {
                        AppFeedback.showInfo(context, t('orderRejectedInfo'));
                      }
                    },
                    child: Text(t('reject')),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirmed = await AppFeedback.showConfirmDialog(
                        context,
                        title: t('markDeliveredTitle'),
                        message: t('markDeliveredMsg')
                            .replaceFirst(
                              '{orderId}',
                              order.id.substring(0, 8).toUpperCase(),
                            )
                            .replaceFirst(
                              '{amount}',
                              CurrencyFormatter.format(order.totalAmount),
                            )
                            .replaceFirst('{client}', customerName),
                        confirmLabel: t('markDelivered'),
                        confirmColor: Colors.green,
                        icon: Icons.local_shipping,
                      );
                      if (!confirmed) return;
                      await orderRepo.markOrderDelivered(order.id);
                      await notifNotifier.addNotification(
                        title: 'order_delivered',
                        message: 'Order of ${CurrencyFormatter.format(order.totalAmount)} for $customerName delivered.',
                        type: 'order',
                        route: '${Routes.adminOrders}?search=${order.orderNumber ?? order.id.substring(0, 8)}',
                      );
                      if (context.mounted) {
                        AppFeedback.showSuccess(
                          context,
                          t('orderDeliveredSuccess'),
                        );
                      }
                    },
                    child: Text(t('markDelivered')),
                  ),
                ),
              ],
            ),
          ] else if (order.status == OrderStatus.delivered.value ||
              order.status == OrderStatus.cancelled.value) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (!isWalkIn)
                  HeavyIOSButton(
                    label: t('auto_Print'),
                    icon: Icons.print_rounded,
                    onTap: () => onPrint(order),
                  ),
                if (order.status == OrderStatus.delivered.value &&
                    (order.totalAmount - order.totalReturnedAmount) > 0)
                  HeavyIOSButton(
                    label: Tr.t('processReturn', langCode),
                    icon: Icons.replay_rounded,
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CustomLoader()),
                      ).ignore();
                      try {
                        final items = await orderRepo.getOrderItems(order.id);
                        final products = await inventoryRepo.getAllProducts();
                        final cust = await customerRepo.getCustomerById(
                          order.customerId,
                        );
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        if (context.mounted) {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) => OrderReturnScreen(
                                    order: order,
                                    items: items,
                                    customer: cust,
                                    products: products,
                                  ),
                                ),
                              )
                              .ignore();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop();
                        }
                        if (context.mounted) {
                          AppFeedback.showError(
                            context,
                            '${Tr.t('errorPrefix', langCode)}$e',
                          );
                        }
                      }
                    },
                  ),
                HeavyIOSButton(
                  label: Tr.t('deleteBtn', langCode),
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  onTap: () async {
                    final confirmed = await AppFeedback.showConfirmDialog(
                      context,
                      title: Tr.t('deleteOrder', langCode),
                      message: Tr.t('deleteOrderMsg', langCode),
                      confirmLabel: Tr.t('deleteBtn', langCode),
                      confirmColor: Colors.red,
                      icon: Icons.warning,
                    );
                    if (confirmed == true) {
                      await orderRepo.deleteOrder(order.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

