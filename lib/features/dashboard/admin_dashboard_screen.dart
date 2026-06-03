import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/local_database/database.dart';
import 'month_year_picker_dialog.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currentLocale = ref.watch(localeProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);
    
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: theme.colorScheme.primary,
          onRefresh: () async {
            ref.invalidate(dashboardMetricsProvider);
            ref.invalidate(topDebtorsProvider);
            ref.invalidate(lowStockProvider);
            ref.invalidate(recentActivityProvider);
          },
          child: metricsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (metrics) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context, isKurdish, isArabic, isDark, unreadNotifsCount).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                    const SizedBox(height: 24),
                    
                    _buildHeroCard(metrics, isKurdish, isArabic, isDark, theme).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader(isKurdish ? 'شیکارییەکان' : isArabic ? 'التحليلات' : 'Analytics', 'View detail', isDark, theme).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),
                    
                    _buildReportButtons(context, ref, isKurdish, isArabic, isDark, theme).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    
                    _buildTopDebtors(ref, isKurdish, isArabic, isDark, theme).animate().fadeIn(delay: 250.ms).slideX(begin: -0.1),
                    
                    const SizedBox(height: 32),
                    _buildLowStockAlerts(ref, isKurdish, isArabic, isDark, theme).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),
                    
                    const SizedBox(height: 32),
                    _buildRecentActivity(ref, isKurdish, isArabic, isDark, theme).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                    const SizedBox(height: 48),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isKurdish, bool isArabic, bool isDark, int unreadNotifsCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKurdish ? 'بەخێربێیتەوە،' : isArabic ? 'مرحباً بعودتك،' : 'Welcome back,',
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  'Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ],
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              ),
              child: IconButton(
                icon: Icon(Icons.notifications_outlined, size: 22, color: isDark ? Colors.white : Colors.black87),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications coming soon!')));
                },
              ),
            ),
            if (unreadNotifsCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: Text(
                    '$unreadNotifsCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ).animate().scale(duration: 300.ms),
              )
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(DashboardMetrics metrics, bool isKurdish, bool isArabic, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isKurdish ? 'پوختەی هەفتە' : isArabic ? 'ملخص الأسبوع' : 'Weekly Summary',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKurdish ? 'قازانج' : isArabic ? 'الأرباح' : 'Profit',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(metrics.thisWeekProfit),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isKurdish ? 'داواکارییەکان' : isArabic ? 'الطلبات' : 'Orders',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metrics.thisWeekOrders.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, bool isDark, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
        ),
        Text(
          action,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildReportButtons(BuildContext context, WidgetRef ref, bool isKurdish, bool isArabic, bool isDark, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildReportCard(
            context, ref,
            title: isKurdish ? 'ڕاپۆرتی مانگانە' : isArabic ? 'تقرير شهري' : 'Monthly Report',
            icon: Icons.bar_chart_rounded,
            isMonth: true,
            theme: theme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildReportCard(
            context, ref,
            title: isKurdish ? 'ڕاپۆرتی ساڵانە' : isArabic ? 'تقرير سنوي' : 'Yearly Report',
            icon: Icons.pie_chart_rounded,
            isMonth: false,
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, WidgetRef ref, {required String title, required IconData icon, required bool isMonth, required ThemeData theme}) {
    return GestureDetector(
      onTap: () => _openReportDialog(context, ref, isMonth: isMonth),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _openReportDialog(BuildContext context, WidgetRef ref, {required bool isMonth}) {
    showDialog(
      context: context,
      builder: (ctx) => ReportPickerModal(isMonth: isMonth),
    );
  }

  Widget _buildTopDebtors(WidgetRef ref, bool isKurdish, bool isArabic, bool isDark, ThemeData theme) {
    final debtorsAsync = ref.watch(topDebtorsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isKurdish ? 'قەرزدارە سەرەکییەکان' : isArabic ? 'أكبر المدينين' : 'Top Debtors', '', isDark, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: debtorsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Text('Error loading debtors'),
            data: (customers) {
              if (customers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(isKurdish ? 'هیچ قەرزێک نییە' : isArabic ? 'لا توجد ديون' : 'No outstanding debts!', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                );
              }
              return Column(
                children: customers.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.person_outline, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.businessName == 'Walk-In Customer' ? (isKurdish ? 'کڕیاری کاتی' : isArabic ? 'عميل عابر' : 'Walk-In Customer') : c.businessName, 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      Text(CurrencyFormatter.format(c.debtBalance), style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockAlerts(WidgetRef ref, bool isKurdish, bool isArabic, bool isDark, ThemeData theme) {
    final lowStockAsync = ref.watch(lowStockProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isKurdish ? 'ئاگاداری کەمبوونەوە' : isArabic ? 'تنبيهات نقص المخزون' : 'Low Stock Alerts', '', isDark, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: lowStockAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Text('Error loading alerts'),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green.shade400, size: 40),
                        const SizedBox(height: 8),
                        Text(isKurdish ? 'هیچ کێشەیەک نییە' : isArabic ? 'المخزون جيد' : 'Stock Levels Good', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: products.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${p.stockQuantity} left', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(WidgetRef ref, bool isKurdish, bool isArabic, bool isDark, ThemeData theme) {
    final recentAsync = ref.watch(recentActivityProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(isKurdish ? 'چالاکی دوایی' : isArabic ? 'النشاط الأخير' : 'Recent Activity', '', isDark, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
          ),
          child: recentAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => const Text('Error loading activity'),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(isKurdish ? 'هیچ داواکارییەک نییە' : isArabic ? 'لا توجد طلبات' : 'No recent orders', style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: orders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.shopping_bag_outlined, color: theme.colorScheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.customerName == 'Walk-In Customer' ? (isKurdish ? 'کڕیاری کاتی' : isArabic ? 'عميل عابر' : 'Walk-In Customer') : o.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(DateFormat('MMM dd, HH:mm', isKurdish ? 'ku' : isArabic ? 'ar' : 'en').format(o.date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(CurrencyFormatter.format(o.totalAmount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
