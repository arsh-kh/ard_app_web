import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/widgets/heavy_ios_button.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/app_translations.dart';
import '../../data/models/customer_entity.dart';
import '../../core/widgets/premium_sort_dropdown.dart';
import '../../domain/enums.dart';
import '../../core/providers/sort_preferences_provider.dart';

import '../../core/widgets/keep_alive_wrapper.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/utils/focus_utils.dart';
import '../../core/widgets/animated_segmented_pill.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final bool isSelectionMode;
  const CustomersScreen({
    super.key,
    this.isEmbedded = false,
    this.isSelectionMode = false,
  });

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode = SelectAllFocusNode(
    controller: _searchController,
  );
  final ScrollController _catalogScrollController = ScrollController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isCatalogScrolled = false;

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
    final currentLocale = ref.watch(localeProvider);
    final lang = currentLocale.languageCode;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customersAsync = ref.watch(allCustomersStreamProvider);
    final selectedSort =
        ref.watch(sortPreferencesProvider)['customers'] ??
        SortOptionType.nameAsc;

    final localizations = AppLocalizations.of(context)!;

    final baseTitle = Tr.t('customersTitle', lang);
    final title = widget.isSelectionMode
        ? Tr.t('selectCustomer', lang)
        : baseTitle;
    final searchHint = Tr.t('searchCustomers', lang);
    final allCustomers = localizations.all;
    final outstandingDebt = Tr.t('outstandingDebt', lang);
    final noData = localizations.noData;
    final registerFirst = Tr.t('addFirstCustomer', lang);
    final newClient = Tr.t('newClient', lang);
    final noAddress = Tr.t('noAddressReg', lang);
    final debtLabel = Tr.t('debtLabel', lang);
    final addCustomerLabel = localizations.addCustomer;

    return customersAsync.when(
      loading: () => Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: widget.isEmbedded ? null : AppBar(title: Text(title)),
        body: const ListSkeleton(),
      ),
      error: (err, stack) => Scaffold(
        appBar: widget.isEmbedded ? null : AppBar(title: Text(title)),
        body: Center(child: Text('${Tr.t('errorPrefix', lang)}$err')),
      ),
      data: (customers) {
        final hasCustomers = customers.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(title),
            centerTitle: true,
            leading: CustomTopBarHelper.buildLeading(
              context: context,
              isRtl: Directionality.of(context) == TextDirection.rtl,
              hasBackButton: Navigator.canPop(context),
              historyButton: widget.isSelectionMode
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () => context.push(Routes.historyHub),
                      tooltip: Tr.t('historyHub', lang),
                    ),
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
              isRtl: Directionality.of(context) == TextDirection.rtl,
              hasBackButton: Navigator.canPop(context),
              historyButton: widget.isSelectionMode
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.history),
                      onPressed: () => context.push(Routes.historyHub),
                      tooltip: Tr.t('historyHub', lang),
                    ),
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
          ),
          floatingActionButtonLocation:
              Directionality.of(context) == TextDirection.rtl
              ? FloatingActionButtonLocation.startFloat
              : FloatingActionButtonLocation.endFloat,
          floatingActionButton: widget.isEmbedded && hasCustomers
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 96.0),
                  child: HeavyIOSButton(
                    onTap: () => context.push(Routes.customerForm),
                    label: newClient,
                    icon: Icons.person_add,
                  ),
                )
              : (!widget.isEmbedded && hasCustomers)
              ? HeavyIOSButton(
                  onTap: () => context.push(Routes.customerForm),
                  label: newClient,
                  icon: Icons.person_add,
                )
              : null,
          body: CustomScrollView(
            controller: _catalogScrollController,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: AnimatedSegmentedPill<String>(
                              items: const ['all', 'debt'],
                              selectedValue: _selectedFilter,
                              onChanged: (val) {
                                setState(() => _selectedFilter = val);
                              },
                              labelBuilder: (val) =>
                                  val == 'all' ? allCustomers : outstandingDebt,
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
                            labelKey: 'sortDebtDesc',
                            icon: Icons.arrow_downward,
                            value: SortOptionType.debtDesc,
                          ),
                          SortOption(
                            labelKey: 'sortDebtAsc',
                            icon: Icons.arrow_upward,
                            value: SortOptionType.debtAsc,
                          ),
                        ],
                        onSelected: (newSort) async {
                          await ref
                              .read(sortPreferencesProvider.notifier)
                              .setSort('customers', newSort);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isSelectionMode)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.pop(
                        const CustomerEntity(
                          id: 'walk-in-anonymous',
                          businessName: 'walk-in',
                          debtBalance: 0,
                        ),
                      ),
                      icon: const Icon(Icons.directions_walk),
                      label: Text(Tr.t('auto_WalkInCustomer', lang)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                      ),
                    ),
                  ),
                ),
              Builder(
                builder: (context) {
                  final filtered = customers.where((c) {
                    final matchesSearch = c.businessName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                    final matchesFilter =
                        _selectedFilter == 'all' ||
                        (_selectedFilter == 'debt' && c.debtBalance > 0.0);
                    return matchesSearch && matchesFilter;
                  }).toList();

                  filtered.sort((a, b) {
                    switch (selectedSort) {
                      case SortOptionType.nameAsc:
                        return a.businessName.compareTo(b.businessName);
                      case SortOptionType.nameDesc:
                        return b.businessName.compareTo(a.businessName);
                      case SortOptionType.debtDesc:
                        return b.debtBalance.compareTo(a.debtBalance);
                      case SortOptionType.debtAsc:
                        return a.debtBalance.compareTo(b.debtBalance);
                      default:
                        return 0;
                    }
                  });

                  if (!hasCustomers) {
                    return SliverFillRemaining(
                      child: AnimatedEmptyState(
                        title: noData,
                        icon: Icons.group_off_outlined,
                        subtitle: registerFirst,
                        actionLabel: addCustomerLabel,
                        onAction: () => context.push(Routes.customerForm),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: AnimatedEmptyState(
                        title: Tr.t('noResults', lang),
                        icon: Icons.search_off,
                        subtitle: Tr.t('tryDifferentKeywords', lang),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.only(
                      top: 8,
                      bottom: widget.isEmbedded ? 120 : 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final customer = filtered[index];
                        final hasDebt = customer.debtBalance > 0.0;

                        return KeepAliveWrapper(
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: hasDebt
                                    ? (theme.colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ))
                                    : theme.colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: InitialsAvatar(
                                text: customer.businessName,
                                imageUrl: customer.imageUrl,
                                radius: 20,
                              ),
                              title: Text(
                                customer.businessName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (customer.phone != null &&
                                        customer.phone!.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.phone,
                                            size: 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              customer.phone!,
                                              style: TextStyle(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                                fontSize: 13,
                                              ),
                                              textDirection: TextDirection.ltr,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            customer.address ?? noAddress,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                constraints: const BoxConstraints(minWidth: 80),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$debtLabel ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(
                                        customer.debtBalance,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: hasDebt
                                            ? (isDark
                                                  ? Colors.red.shade400
                                                  : Colors.red.shade600)
                                            : (isDark
                                                  ? Colors.green.shade400
                                                  : Colors.green.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                if (widget.isSelectionMode) {
                                  context.pop(customer);
                                } else {
                                  context.push(
                                    Routes.customerDetail,
                                    extra: customer,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      }, childCount: filtered.length),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
