import 'package:flutter/material.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/analytics_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_entity.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/order_providers.dart';

class _LocalTranslations {
  static const _data = {
    'en': {
      'analyticsTitle': 'Business Analytics',
      'margins': 'Margins',
      'topCustomers': 'Top Customers',
      'debtAging': 'Debt Risk',
      'cogs': 'Cost Price (COGS)',
      'sellPrice': 'Selling Price',
      'profitAmount': 'Profit per Unit',
      'margin': 'Margin',
      'avgMargin': 'Avg. Wholesale Margin',
      'topMargin': 'Top Margin',
      'salesVolume': 'Sales Volume',
      'ordersCount': 'Orders Count',
      'debtRiskLevel': 'Debt Risk Analysis',
      'recent': 'Recent (0-15 Days)',
      'due': 'Due (16-30 Days)',
      'overdue': 'Overdue (31+ Days)',
      'requireActionList': 'Clients Requiring Action (Overdue)',
      'noOverdueClients': 'No overdue clients. Debt collection is healthy.',
      'lastOrder': 'Last Order: {days} days ago',
      'neverOrdered': 'Never ordered (or manual debt balance)',
      'total': 'Total',
    },
    'ku': {
      'analyticsTitle': 'Ø´ÛŒÚ©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ú©Ø§Ø±',
      'margins': 'Ú•ÛŽÚ˜Û•ÛŒ Ù‚Ø§Ø²Ø§Ù†Ø¬',
      'topCustomers': 'Ú©Ú•ÛŒØ§Ø±Û• Ø³Û•Ø±Û•Ú©ÛŒÛŒÛ•Ú©Ø§Ù†',
      'debtAging': 'Ù…Û•ØªØ±Ø³ÛŒ Ù‚Û•Ø±Ø²',
      'cogs': 'Ù†Ø±Ø®ÛŒ Ú©Ú•ÛŒÙ† (COGS)',
      'sellPrice': 'Ù†Ø±Ø®ÛŒ ÙØ±Û†Ø´ØªÙ†',
      'profitAmount': 'Ù‚Ø§Ø²Ø§Ù†Ø¬ÛŒ ØªØ§Ú©',
      'margin': 'Ú•ÛŽÚ˜Û•',
      'avgMargin': 'ØªÛŽÚ©Ú•Ø§ÛŒ Ù‚Ø§Ø²Ø§Ù†Ø¬ÛŒ Ú©Û†Ú¯Ø§',
      'topMargin': 'Ø¨Û•Ø±Ø²ØªØ±ÛŒÙ† Ù‚Ø§Ø²Ø§Ù†Ø¬',
      'salesVolume': 'Ø¨Ú•ÛŒ ÙØ±Û†Ø´ØªÙ†',
      'ordersCount': 'Ú˜Ù…Ø§Ø±Û•ÛŒ Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ•Ú©Ø§Ù†',
      'debtRiskLevel': 'Ø´ÛŒÚ©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ù…Û•ØªØ±Ø³ÛŒ Ù‚Û•Ø±Ø²',
      'recent': 'Ø¦Û•Ù… Ø¯ÙˆØ§ÛŒÛŒØ§Ù†Û• (Ù -Ù¡Ù¥ Ú•Û†Ú˜)',
      'due': 'Ø´Ø§ÛŒØ³ØªÛ• (Ù¡Ù¦-Ù£Ù  Ú•Û†Ú˜)',
      'overdue': 'Ø¯ÙˆØ§Ú©Û•ÙˆØªÙˆÙˆ (Ù£Ù¡+ Ú•Û†Ú˜)',
      'requireActionList': 'Ú©Ú•ÛŒØ§Ø±Ø§Ù†ÛŒ Ù¾ÛŽÙˆÛŒØ³Øª Ø¨Û† Ù¾Û•ÛŒÙˆÛ•Ù†Ø¯ÛŒÚ©Ø±Ø¯Ù† (Ø¯ÙˆØ§Ú©Û•ÙˆØªÙˆÙˆ)',
      'noOverdueClients': 'Ù‡ÛŒÚ† Ú©Ú•ÛŒØ§Ø±ÛŽÚ©ÛŒ Ø¯ÙˆØ§Ú©Û•ÙˆØªÙˆÙˆ Ù†ÛŒÛŒÛ•. Ú©Û†Ú©Ø±Ø¯Ù†Û•ÙˆÛ•ÛŒ Ù‚Û•Ø±Ø² ØªÛ•Ù†Ø¯Ø±ÙˆØ³ØªÛ•.',
      'lastOrder': 'Ø¯ÙˆØ§ÛŒÛŒÙ† Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒ: {days} Ú•Û†Ú˜ Ù¾ÛŽØ´ Ø¦ÛŽØ³ØªØ§',
      'neverOrdered': 'Ù‡ÛŒÚ† Ø¯Ø§ÙˆØ§Ú©Ø§Ø±ÛŒÛŒÛ•Ú©ÛŒ Ù†ÛŒÛŒÛ• (ÛŒØ§Ù† Ù‚Û•Ø±Ø²ÛŒ Ø¯Û•Ø³ØªÛŒ)',
      'total': 'Ú©Û†ÛŒ Ú¯Ø´ØªÛŒ',
    },
    'ar': {
      'analyticsTitle': 'ØªØ­Ù„ÙŠÙ„Ø§Øª Ø§Ù„Ø¹Ù…Ù„',
      'margins': 'Ù‡Ø§Ù…Ø´ Ø§Ù„Ø±Ø¨Ø­',
      'topCustomers': 'Ø£ÙØ¶Ù„ Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡',
      'debtAging': 'Ù…Ø®Ø§Ø·Ø± Ø§Ù„Ø¯ÙŠÙˆÙ†',
      'cogs': 'Ø³Ø¹Ø± Ø§Ù„ØªÙƒÙ„ÙØ© (COGS)',
      'sellPrice': 'Ø³Ø¹Ø± Ø§Ù„Ø¨ÙŠØ¹',
      'profitAmount': 'Ø§Ù„Ø±Ø¨Ø­ Ù„ÙƒÙ„ ÙˆØ­Ø¯Ø©',
      'margin': 'Ø§Ù„Ù‡Ø§Ù…Ø´',
      'avgMargin': 'Ù…ØªÙˆØ³Ø· Ù‡Ø§Ù…Ø´ Ø§Ù„Ø¬Ù…Ù„Ø©',
      'topMargin': 'Ø£Ø¹Ù„Ù‰ Ù‡Ø§Ù…Ø´',
      'salesVolume': 'Ø­Ø¬Ù… Ø§Ù„Ù…Ø¨ÙŠØ¹Ø§Øª',
      'ordersCount': 'Ø¹Ø¯Ø¯ Ø§Ù„Ø·Ù„Ø¨Ø§Øª',
      'debtRiskLevel': 'ØªØ­Ù„ÙŠÙ„ Ù…Ø®Ø§Ø·Ø± Ø§Ù„Ø¯ÙŠÙˆÙ†',
      'recent': 'Ø­Ø¯ÙŠØ«Ø§Ù‹ (0-15 ÙŠÙˆÙ…)',
      'due': 'Ù…Ø³ØªØ­Ù‚ (16-30 ÙŠÙˆÙ…)',
      'overdue': 'Ù…ØªØ£Ø®Ø± (31+ ÙŠÙˆÙ…)',
      'requireActionList': 'Ø§Ù„Ø¹Ù…Ù„Ø§Ø¡ Ø§Ù„Ø°ÙŠÙ† ÙŠØªØ·Ù„Ø¨ÙˆÙ† Ø§ØªØ®Ø§Ø° Ø¥Ø¬Ø±Ø§Ø¡ (Ù…ØªØ£Ø®Ø±)',
      'noOverdueClients': 'Ù„Ø§ ÙŠÙˆØ¬Ø¯ Ø¹Ù…Ù„Ø§Ø¡ Ù…ØªØ£Ø®Ø±ÙˆÙ†. ØªØ­ØµÙŠÙ„ Ø§Ù„Ø¯ÙŠÙˆÙ† Ø³Ù„ÙŠÙ….',
      'lastOrder': 'Ø¢Ø®Ø± Ø·Ù„Ø¨: Ù…Ù†Ø° {days} ÙŠÙˆÙ…',
      'neverOrdered': 'Ù„Ù… ÙŠØ·Ù„Ø¨ Ø£Ø¨Ø¯Ø§Ù‹ (Ø£Ùˆ Ø±ØµÙŠØ¯ Ø¯ÙŠÙˆÙ† ÙŠØ¯ÙˆÙŠ)',
      'total': 'Ø§Ù„Ù…Ø¬Ù…ÙˆØ¹',
    }
  };

  static String get(String key, String langCode) {
    final langMap = _data[langCode] ?? _data['en']!;
    return langMap[key] ?? key;
  }
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final langCode = currentLocale.languageCode;
    final isRtl = langCode == 'ku' || langCode == 'ar';
    
    String t(String key) => _LocalTranslations.get(key, langCode);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('analyticsTitle'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: isDark ? theme.colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              labelColor: isDark ? Colors.white : theme.colorScheme.primary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: t('margins')),
                Tab(text: t('topCustomers')),
                Tab(text: t('debtAging')),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMarginsTab(context, t, isDark, theme),
          _buildTopCustomersTab(context, t, isDark, theme, isRtl),
          _buildDebtAgingTab(context, t, isDark, theme, isRtl),
        ],
      ),
    );
  }

  // --- MARGINS TAB ---
  Widget _buildMarginsTab(BuildContext context, String Function(String) t, bool isDark, ThemeData theme) {
    final marginsAsync = ref.watch(productMarginsProvider);

    return marginsAsync.when(
      loading: () => const Center(child: CustomLoader()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (margins) {
        if (margins.isEmpty) {
          return Center(child: Text(t('noData')));
        }

        // Calculate Average Margin
        final avgMargin = margins.fold(0.0, (sum, m) => sum + m.marginPercentage) / margins.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [theme.colorScheme.primary.withValues(alpha: 0.05), theme.colorScheme.primary.withValues(alpha: 0.12)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    radius: 24,
                    child: Icon(Icons.analytics, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('avgMargin'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${avgMargin.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            const SizedBox(height: 20),

            // Products list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: margins.length,
              itemBuilder: (context, index) {
                final item = margins[index];
                final isTopMargin = index == 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (isTopMargin) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        t('topMargin'),
                                        style: const TextStyle(
                                          color: Colors.teal,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${t('cogs')}: ',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(item.product.buyPrice),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${t('sellPrice')}: ',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(item.product.sellPrice),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${CurrencyFormatter.format(item.marginAmount)}',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.marginPercentage.toStringAsFixed(1)}% ${t('margin')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (50 * index).ms, duration: 250.ms);
              },
            ),
          ],
        );
      },
    );
  }

  // --- TOP CUSTOMERS TAB ---
  Widget _buildTopCustomersTab(BuildContext context, String Function(String) t, bool isDark, ThemeData theme, bool isRtl) {
    final topCustomersAsync = ref.watch(topCustomersProvider);

    return topCustomersAsync.when(
      loading: () => const Center(child: CustomLoader()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (customers) {
        if (customers.isEmpty) {
          return Center(child: Text(t('noData')));
        }

        // Find the maximum sales amount to normalize progress bars
        final maxSales = customers.first.totalSales;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final item = customers[index];
            final progress = maxSales > 0 ? (item.totalSales / maxSales) : 0.0;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.customer.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalSales),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${t('ordersCount')}: ${item.orderCount}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 12),
                    // Visual Progress indicator representing wholesale percentage
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progress > 0 ? progress : 0.001,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (50 * index).ms, duration: 250.ms).slideX(begin: isRtl ? -0.05 : 0.05, end: 0);
          },
        );
      },
    );
  }

  // --- DEBT AGING RISK TAB ---
  Widget _buildDebtAgingTab(BuildContext context, String Function(String) t, bool isDark, ThemeData theme, bool isRtl) {
    final agingAsync = ref.watch(debtAgingProvider);
    final customersAsync = ref.watch(dashboardCustomersProvider);

    return agingAsync.when(
      loading: () => const Center(child: CustomLoader()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (aging) {
        final totalDebt = aging.totalDebt;
        
        final percentRecent = totalDebt > 0 ? (aging.recentDebt / totalDebt) : 0.0;
        final percentDue = totalDebt > 0 ? (aging.dueDebt / totalDebt) : 0.0;
        final percentOverdue = totalDebt > 0 ? (aging.overdueDebt / totalDebt) : 0.0;

        return customersAsync.when(
          loading: () => const Center(child: CustomLoader()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (customersList) {
            // Find customers with active debt balance > 0
            final debtCustomers = customersList.where((c) => c.debtBalance > 0.0).toList();
            
            // For the overdue details, we will query their last order to filter clients
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Segment Bar Representing Risk Ratios
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t('debtRiskLevel'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t('total')}: ${CurrencyFormatter.format(totalDebt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      
                      // Colored Stack Bar
                      Container(
                        height: 16,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                        ),
                        child: Row(
                          children: [
                            if (percentRecent > 0)
                              Expanded(
                                flex: (percentRecent * 100).round(),
                                child: Container(color: Colors.green),
                              ),
                            if (percentDue > 0)
                              Expanded(
                                flex: (percentDue * 100).round(),
                                child: Container(color: Colors.amber),
                              ),
                            if (percentOverdue > 0)
                              Expanded(
                                flex: (percentOverdue * 100).round(),
                                child: Container(color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Legend Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLegendItem(Colors.green, t('recent'), aging.recentDebt),
                          _buildLegendItem(Colors.amber, t('due'), aging.dueDebt),
                          _buildLegendItem(Colors.red, t('overdue'), aging.overdueDebt),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),

                // Overdue Client Ledger Action Items
                Text(
                  t('requireActionList'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                if (debtCustomers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        t('noOverdueClients'),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  // We show all customers with debt, sorting by highest balance first
                  ...debtCustomers.map((customer) {
                    return FutureBuilder<OrderEntity?>(
                      // Find their last order to calculate exact days overdue
                      future: () async {
                        final orderRepo = ref.read(orderRepositoryProvider);
                        final cOrders = await orderRepo.getOrdersByCustomer(customer.id);
                        final delivered = cOrders.where((o) => o.status == 'delivered').toList();
                        delivered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
                        return delivered.isNotEmpty ? delivered.first : null;
                      }(),
                      builder: (context, orderSnapshot) {
                        final lastOrder = orderSnapshot.data;
                        Color riskColor = Colors.green;
                        String statusDesc = t('neverOrdered');
                        
                        if (lastOrder != null) {
                          final days = DateTime.now().difference(lastOrder.orderDate).inDays;
                          statusDesc = t('lastOrder').replaceFirst('{days}', '$days');
                          if (days <= 15) {
                            riskColor = Colors.green;
                          } else if (days <= 30) {
                            riskColor = Colors.amber;
                          } else {
                            riskColor = Colors.red;
                          }
                        } else {
                          // No order means long-standing manual ledger debt balance
                          riskColor = Colors.red;
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: riskColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(
                              customer.businessName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              statusDesc,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(customer.debtBalance),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ).animate().fadeIn(duration: 200.ms);
                      },
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label.split(' ').first, // Just the short label (Recent, Due, Overdue)
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}


