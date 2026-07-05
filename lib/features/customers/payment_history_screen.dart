import 'package:flutter/material.dart';
import '../../core/utils/pdf_interceptor.dart';

import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/providers/payment_providers.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/widgets/async_value_widget.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/premium_sort_dropdown.dart';
import '../../domain/enums.dart';
import '../payments/payment_report_dialog.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/models/payment_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/app_date_range_picker.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/widgets/animated_segmented_pill.dart';
import '../../core/services/html_generator_service.dart';
import '../../core/providers/auth_provider.dart';

import '../../core/widgets/heavy_ios_button.dart';
import 'history_hub_screen.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  final bool isEmbedded;
  final String? initialSearchQuery;

  const PaymentHistoryScreen({
    super.key,
    this.isEmbedded = false,
    this.initialSearchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(allPaymentsStreamProvider);
    final lang = ref.watch(localeProvider).languageCode;

    return Scaffold(
      backgroundColor: isEmbedded ? Colors.transparent : null,
      body: AsyncValueWidget(
        value: paymentsAsync,
        data: (payments) => _PaymentsBody(
          key: const ValueKey('payments_body'),
          payments: payments,
          lang: lang,
          isEmbedded: isEmbedded,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }
}

class _PaymentsBody extends ConsumerStatefulWidget {
  final List<PaymentEntity> payments;
  final String lang;
  final bool isEmbedded;
  final String? initialSearchQuery;

  const _PaymentsBody({
    super.key,
    required this.payments,
    required this.lang,
    required this.isEmbedded,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<_PaymentsBody> createState() => _PaymentsBodyState();
}

class _PaymentsBodyState extends ConsumerState<_PaymentsBody> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final FocusNode _searchFocusNode = SelectAllFocusNode(
    controller: _searchCtrl,
  );
  final ScrollController _scrollCtrl = ScrollController();

  String _searchQuery = '';
  String _selectedPeriod = 'all';
  DateTimeRange? _customRange;
  bool _isScrolled = false;
  SortOptionType _selectedSort = SortOptionType.dateDesc;
  final Map<String, String> _paymentIdToCustomerNames = {};

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
    final customerRepo = ref.read(customerRepositoryProvider);
    try {
      final customers = await customerRepo.getAllCustomers();
      final customerMap = {
        for (var c in customers) c.id: c.businessName.toLowerCase(),
      };

      for (final p in widget.payments) {
        final name = customerMap[p.customerId] ?? '';
        _paymentIdToCustomerNames[p.id] = name;
      }
    } catch (e) {
      // Ignore errors for search cache
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

  List<PaymentEntity> _applyFilters(List<PaymentEntity> payments) {
    return payments.where((p) {
      if (!_matchesPeriod(p.paymentDate)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = _paymentIdToCustomerNames[p.id] ?? '';

        if (!name.contains(q) && !p.id.toLowerCase().contains(q)) return false;
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

  Future<void> _deletePayment(PaymentEntity payment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(Tr.t('delete', widget.lang)),
        content: Text(
          Tr.t('deletePaymentConfirm', widget.lang),
        ), // We need to add this if not present
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(Tr.t('cancelBtn', widget.lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(Tr.t('delete', widget.lang)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(paymentRepositoryProvider).deletePayment(payment.id);
      if (mounted) {
        AppFeedback.showSuccess(context, Tr.t('paymentDeleted', widget.lang));
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    }
  }

  Future<void> _printReceipt(PaymentEntity payment) async {
    bool isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CustomLoader()),
    ).ignore();

    try {
      final customerRepo = ref.read(customerRepositoryProvider);
      final customer = await customerRepo.getCustomerById(payment.customerId);



      // For walk-in payments, create a placeholder customer entity
      final resolvedCustomer = customer ??
          CustomerEntity(
            id: payment.customerId,
            businessName: Tr.t('walkIn', widget.lang),
            debtBalance: 0,
          );

      final authState = ref.read(authProvider);
      final adminPhone = authState.user?.phone;
      if (!context.mounted) return;
      final pdfIntercept = await PdfInterceptor.checkAndNavigate(context);
      if (!pdfIntercept) return;

      await HtmlGeneratorService.generateAndLaunchPaymentReceipt(
        payment: payment,
        customer: resolvedCustomer,
        isKurdish: widget.lang == 'ku',
        isArabic: widget.lang == 'ar',
        adminPhone: adminPhone,
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted && isDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        isDialogOpen = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = widget.lang;

    if (widget.isEmbedded) {
      ref.listen(historySearchTriggerProvider, (previous, next) {
        if (next != null) {
          final tabCtrl = DefaultTabController.maybeOf(context);
          if (tabCtrl != null && tabCtrl.index == 1) {
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

    final filtered = _applyFilters(widget.payments);

    filtered.sort((a, b) {
      switch (_selectedSort) {
        case SortOptionType.nameAsc:
          final nameA = _paymentIdToCustomerNames[a.id] ?? '';
          final nameB = _paymentIdToCustomerNames[b.id] ?? '';
          return nameA.compareTo(nameB);
        case SortOptionType.nameDesc:
          final nameA = _paymentIdToCustomerNames[a.id] ?? '';
          final nameB = _paymentIdToCustomerNames[b.id] ?? '';
          return nameB.compareTo(nameA);
        case SortOptionType.dateAsc:
          return a.paymentDate.compareTo(b.paymentDate);
        case SortOptionType.dateDesc:
          return b.paymentDate.compareTo(a.paymentDate);
        case SortOptionType.priceAsc:
          return a.amount.compareTo(b.amount);
        case SortOptionType.priceDesc:
          return b.amount.compareTo(a.amount);
        default:
          return b.paymentDate.compareTo(a.paymentDate);
      }
    });

    final totalAmount = filtered.fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : null,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              automaticallyImplyLeading: false,
              title: Text(Tr.t('auto_PaymentHistory', lang)),
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
              preferredSize: const Size.fromHeight(68),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: Tr.t('searchPayments', lang),
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
                    fillColor: theme.colorScheme.surfaceContainerHighest,
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
                  const SizedBox(width: 8),
                  PremiumSortDropdown<SortOptionType>(
                    selectedValue: _selectedSort,
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
                        labelKey: 'sortNameAsc',
                        icon: Icons.sort_by_alpha,
                        value: SortOptionType.nameAsc,
                      ),
                      SortOption(
                        labelKey: 'sortNameDesc',
                        icon: Icons.sort_by_alpha,
                        value: SortOptionType.nameDesc,
                      ),
                    ],
                    onSelected: (val) => setState(() => _selectedSort = val),
                  ),
                ],
              ),
            ),
          ),

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
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        Tr.t('summaryPayments', lang, {
                          'count': filtered.length.toString(),
                          'total': CurrencyFormatter.format(totalAmount),
                        }),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => const PaymentReportDialog(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
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
                              color: theme.colorScheme.surface,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Tr.t('auto_PaymentReport', lang),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.surface,
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

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: AnimatedEmptyState(
                icon: Icons.payments,
                title: _searchQuery.isNotEmpty || _selectedPeriod != 'all'
                    ? Tr.t('noResults', lang)
                    : Tr.t('noPaymentHistory', lang),
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
                  (context, index) => _PaymentCard(
                    payment: filtered[index],
                    index: index,
                    lang: lang,
                    isDark: isDark,
                    customerRepo: ref.read(customerRepositoryProvider),
                    onDelete: () => _deletePayment(filtered[index]),
                    onPrint: () => _printReceipt(filtered[index]),
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

class _PaymentCard extends StatelessWidget {
  final PaymentEntity payment;
  final int index;
  final String lang;
  final bool isDark;
  final CustomerRepository customerRepo;
  final VoidCallback onDelete;
  final VoidCallback onPrint;

  const _PaymentCard({
    required this.payment,
    required this.index,
    required this.lang,
    required this.isDark,
    required this.customerRepo,
    required this.onDelete,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CustomerEntity?>(
      future: customerRepo.getCustomerById(payment.customerId),
      builder: (context, snapshot) {
        final customerName =
            snapshot.data?.businessName ?? Tr.t('unknownCustomer', lang);
        final theme = Theme.of(context);
        return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  title: Text(
                    customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      DateFormat('dd/MM • HH:mm').format(payment.paymentDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  trailing: Text(
                    CurrencyFormatter.format(payment.amount),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: [
                              HeavyIOSButton(
                                label: Tr.t('auto_Print', lang),
                                icon: Icons.print_rounded,
                                onTap: onPrint,
                              ),
                              HeavyIOSButton(
                                label: Tr.t('deleteBtn', lang),
                                icon: Icons.delete_outline,
                                color: Colors.red,
                                onTap: onDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: (20 * index.clamp(0, 15)).ms)
            .slideX(begin: 0.05);
      },
    );
  }
}
