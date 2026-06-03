import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/routing/routes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/local_database/database.dart';
import '../../l10n/app_localizations.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const CustomersScreen({super.key, this.isEmbedded = false});

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
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    final localizations = AppLocalizations.of(context)!;

    final title = isKurdish ? 'کڕیارەکان و قەرزەکان' : isArabic ? 'العملاء والديون' : 'Customers & Debts';
    final searchHint = isKurdish ? 'گەڕان بۆ کڕیار...' : isArabic ? 'البحث عن عميل...' : 'Search customers...';
    final allCustomers = localizations.all;
    final outstandingDebt = isKurdish ? 'قەرزی ماوە' : isArabic ? 'الديون المستحقة' : 'Outstanding Debt';
    final noData = localizations.noData;
    final registerFirst = isKurdish ? 'یەکەم کڕیار تۆمار بکە' : isArabic ? 'سجل عميلك الأول' : 'Add Your First Customer';
    final newClient = isKurdish ? 'کڕیاری نوێ' : isArabic ? 'عميل جديد' : 'New Client';
    final noAddress = isKurdish ? 'ناونیشان نییە' : isArabic ? 'لا يوجد عنوان' : 'No address registered';
    final debtLabel = isKurdish ? 'قەرزی ماوە' : isArabic ? 'الديون المستحقة' : 'Outstanding Debt';

    return Scaffold(
      appBar: widget.isEmbedded ? null : AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 28),
            onPressed: () {
              context.push(Routes.customerForm);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: widget.isEmbedded ? FloatingActionButton.extended(
        onPressed: () => context.push(Routes.customerForm),
        icon: const Icon(Icons.person_add),
        label: Text(newClient),
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
          Expanded(
            child: StreamBuilder<List<CustomerEntity>>(
              stream: customersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final customers = snapshot.data ?? [];

                final filtered = customers.where((c) {
                  final matchesSearch = c.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesFilter = _selectedFilter == 'all' ||
                      (_selectedFilter == 'debt' && c.debtBalance > 0.0);
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(noData, style: TextStyle(color: Colors.grey.shade500)),
                        if (customers.isEmpty) ...[
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => context.push(Routes.customerForm),
                            icon: const Icon(Icons.person_add, size: 18),
                            label: Text(registerFirst),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
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
                              ? Colors.amber.withValues(alpha: 0.4)
                              : isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: hasDebt
                              ? Colors.amber.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 0.08),
                          child: Text(
                            customer.businessName[0].toUpperCase(),
                            style: TextStyle(
                              color: hasDebt ? Colors.amber.shade800 : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          context.push(Routes.customerDetail, extra: customer);
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
  }
}
