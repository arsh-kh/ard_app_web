import 'package:ard_app/core/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/notification_providers.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/app_translations.dart';
import '../../core/widgets/bouncing_widget.dart';
import '../../core/widgets/animated_counter.dart';
import '../../data/models/user_entity.dart';
import '../../core/widgets/initials_avatar.dart';
import '../../core/routing/routes.dart';
import 'month_year_picker_dialog.dart';
import '../../core/widgets/custom_loader.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currentLocale = ref.watch(localeProvider);
    final unreadNotifsCount = ref.watch(unreadNotificationsCountProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final lang = currentLocale.languageCode;

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
            loading: () => const Center(child: CustomLoader()),
            error: (err, stack) =>
                Center(child: Text('${Tr.t('errorPrefix', lang)}$err')),
            data: (metrics) {
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: false,
                    snap: false,
                    pinned: true,
                    toolbarHeight: 80,
                    automaticallyImplyLeading: false,
                    titleSpacing: 24,
                    title: _buildHeader(
                      context,
                      lang,
                      isDark,
                      unreadNotifsCount,
                      user,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 120.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeroCard(
                          metrics,
                          lang,
                          isDark,
                          theme,
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),

                        _buildRecentActivity(
                          ref,
                          lang,
                          isDark,
                          theme,
                        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                        const SizedBox(height: 32),

                        _buildTopDebtors(
                          ref,
                          lang,
                          isDark,
                          theme,
                        ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                        const SizedBox(height: 32),

                        _buildSectionHeader(
                          Tr.t('analytics', lang),
                          '',
                          isDark,
                          theme,
                        ).animate().fadeIn(delay: 300.ms),
                        const SizedBox(height: 16),

                        _buildReportButtons(
                          context,
                          ref,
                          lang,
                          isDark,
                          theme,
                        ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                        const SizedBox(height: 48),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String lang,
    bool isDark,
    int unreadNotifsCount,
    UserEntity? user,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            InitialsAvatar(
              text: user?.name ?? 'U',
              imageUrl: user?.imageUrl,
              radius: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: theme.colorScheme.onSurface,
                  ),
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
                border: Border.all(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  size: 22,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => context.push(Routes.notifications),
              ),
            ),
            if (unreadNotifsCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$unreadNotifsCount',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ).animate().scale(duration: 300.ms),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    DashboardMetrics metrics,
    String lang,
    bool isDark,
    ThemeData theme,
  ) {
    const Color textColor = Colors.white;
    const Color mutedTextColor = Colors.white70;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1F1F1F), const Color(0xFF121212)]
              : [const Color(0xFF222222), const Color(0xFF000000)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.primaryContainer, width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Transform.rotate(
              angle: -0.2,
              child: const Icon(
                Icons.trending_up_rounded,
                size: 140,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Tr.t('weeklyS', lang),
                  style: const TextStyle(
                    color: mutedTextColor,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Tr.t('profit', lang),
                            style: const TextStyle(
                              color: mutedTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: AnimatedCounter(
                                value: metrics.thisWeekProfit,
                                isCurrency: true,
                                style: TextStyle(
                                  color: metrics.thisWeekProfit > 0
                                      ? theme.colorScheme.primary
                                      : metrics.thisWeekProfit < 0
                                      ? theme.colorScheme.error
                                      : textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 1,
                      height: 40,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Tr.t('ordersLabel', lang),
                            style: const TextStyle(
                              color: mutedTextColor,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: AnimatedCounter(
                                value: metrics.thisWeekOrders.toDouble(),
                                isCurrency: false,
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action,
    bool isDark,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          action,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportButtons(
    BuildContext context,
    WidgetRef ref,
    String lang,
    bool isDark,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                context,
                ref,
                title: Tr.t('ordersLabel', lang),
                icon: Icons.shopping_cart_outlined,
                isMonth: false,
                theme: theme,
                onTap: () => context.push(Routes.adminOrders),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                context,
                ref,
                title: Tr.t('purchases', lang),
                icon: Icons.receipt_long,
                isMonth: false,
                theme: theme,
                onTap: () => context.push(Routes.purchases),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                context,
                ref,
                title: Tr.t('monthlyReport', lang),
                icon: Icons.bar_chart_rounded,
                isMonth: true,
                theme: theme,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildReportCard(
                context,
                ref,
                title: Tr.t('yearlyReport', lang),
                icon: Icons.pie_chart_rounded,
                isMonth: false,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required bool isMonth,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return BouncingWidget(
      onTap: onTap ?? () => _openReportDialog(context, ref, isMonth: isMonth),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF1A1A1A)
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.05),
          ),
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

  void _openReportDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isMonth,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => ReportPickerModal(isMonth: isMonth),
    );
  }

  Widget _buildTopDebtors(
    WidgetRef ref,
    String lang,
    bool isDark,
    ThemeData theme,
  ) {
    final debtorsAsync = ref.watch(topDebtorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Tr.t('topDebtors', lang), '', isDark, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primaryContainer),
          ),
          child: debtorsAsync.when(
            loading: () => const Center(child: CustomLoader()),
            error: (err, _) => Text(Tr.t('errorLoadingDebtors', lang)),
            data: (customers) {
              if (customers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      Tr.t('noDebts', lang),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < customers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == customers.length - 1 ? 0 : 16.0,
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            text: customers[i].businessName,
                            imageUrl: customers[i].imageUrl,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Tr.localiseCustomerName(
                                customers[i].businessName,
                                lang,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(customers[i].debtBalance),
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    WidgetRef ref,
    String lang,
    bool isDark,
    ThemeData theme,
  ) {
    final recentAsync = ref.watch(recentActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Tr.t('recentActivity', lang), '', isDark, theme),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primaryContainer),
          ),
          child: recentAsync.when(
            loading: () => const Center(child: CustomLoader()),
            error: (err, _) => Text(Tr.t('errorLoadingActivity', lang)),
            data: (activities) {
              if (activities.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      Tr.t('noRecentActivity', lang),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < activities.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == activities.length - 1 ? 0 : 16.0,
                      ),
                      child: Row(
                        children: [
                          InitialsAvatar(
                            text: activities[i].customerName,
                            radius: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activities[i].isPayment
                                      ? Tr.localiseCustomerName(
                                          activities[i].customerName,
                                          lang,
                                        )
                                      : '${Tr.localiseCustomerName(activities[i].customerName, lang)}${activities[i].orderNumber != null ? ' (#${activities[i].orderNumber})' : ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy • HH:mm',
                                  ).format(activities[i].date),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(activities[i].totalAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
