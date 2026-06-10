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
import '../../data/models/customer_entity.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/app_translations.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  final bool isSelectionMode;
  const CustomersScreen({super.key, this.isEmbedded = false, this.isSelectionMode = false});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerRepo = ref.watch(customerRepositoryProvider);
    final customersStream = customerRepo.watchAllCustomers();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final currentLocale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;
    final lang = currentLocale.languageCode;

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

    return StreamBuilder<List<CustomerEntity>>(
      stream: customersStream,
      builder: (context, snapshot) {
        final customers = snapshot.data ?? [];
        final hasCustomers = customers.isNotEmpty;

        return Scaffold(
          appBar: widget.isEmbedded ? null : AppBar(
            title: Text(title),
            actions: [
              if (widget.isSelectionMode)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => context.push(Routes.customerForm),
                  tooltip: newClient,
                ),
            ],
          ),
          floatingActionButton: widget.isEmbedded && hasCustomers ? Padding(
            padding: const EdgeInsets.only(bottom: 96.0),
            child: HeavyIOSButton(
              onTap: () => context.push(Routes.customerForm),
              label: newClient,
              icon: Icons.person_add,
            ),
          ) : null,
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
                  label: Text(allCustomers),
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
                  label: Text(outstandingDebt),
                  selected: _selectedFilter == 'debt',
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = 'debt');
                  },
                  selectedColor: Colors.amber.withValues(alpha: 0.1),
                  checkmarkColor: Colors.amber.shade700,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'debt' ? Colors.amber.shade800 : Colors.grey.shade600,
                    fontWeight: _selectedFilter == 'debt' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                onPressed: () => context.pop(null), // null means Walk-in
                icon: const Icon(Icons.directions_walk),
                label: Text(lang == 'ku' ? 'کڕیاری کاتی (بێ ناو)' : lang == 'ar' ? 'عميل عابر' : 'Walk-In Customer'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                ),
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListSkeleton();
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final filtered = customers.where((c) {
                  final matchesSearch = c.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesFilter = _selectedFilter == 'all' ||
                      (_selectedFilter == 'debt' && c.debtBalance > 0.0);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (!hasCustomers) {
                  return AnimatedEmptyState(
                    title: noData,
                    icon: Icons.group_off_outlined,
                    subtitle: registerFirst,
                    actionLabel: lang == 'ku' ? 'تۆمارکردنی کڕیار' : 'New Customer',
                    onAction: () => context.push(Routes.customerForm),
                  );
                }

                if (filtered.isEmpty) {
                  return AnimatedEmptyState(
                    title: lang == 'ku' ? 'هیچ کڕیارێک نەدۆزرایەوە' : 'No customers found',
                    icon: Icons.search_off,
                    subtitle: lang == 'ku' ? 'وشەیەکی تر بەکاربهێنە' : 'Try different keywords',
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: EdgeInsets.only(top: 8, bottom: widget.isEmbedded ? 120 : 24),
                  itemBuilder: (context, index) {
                    final customer = filtered[index];
                    final hasDebt = customer.debtBalance > 0.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: hasDebt
                              ? (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5))
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: InitialsAvatar(
                          text: customer.businessName,
                          imageUrl: customer.imageUrl,
                          radius: 20,
                        ),
                        title: Text(
                          customer.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.phone != null && customer.phone!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 12, color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      customer.phone!,
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                      textDirection: TextDirection.ltr,
                                    ),
                                  ],
                                ),
                              Text(
                                customer.address ?? noAddress,
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(debtLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(customer.debtBalance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: hasDebt ? Colors.red.shade600 : Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (widget.isSelectionMode) {
                            context.pop(customer);
                          } else {
                            context.push(Routes.customerDetail, extra: customer);
                          }
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


