import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/custom_top_bar_helper.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../orders/admin_orders_screen.dart';
import 'payment_history_screen.dart';

final historyIsScrolledProvider = StateProvider<bool>((ref) => false);
final historySearchTriggerProvider = StateProvider<DateTime?>((ref) => null);

class HistoryHubScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;

  const HistoryHubScreen({
    super.key,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<HistoryHubScreen> createState() => _HistoryHubScreenState();
}

class _HistoryHubScreenState extends ConsumerState<HistoryHubScreen> {
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider).languageCode;
    final isRtl = Directionality.of(context).name == 'rtl';
    final theme = Theme.of(context);


    final Widget? searchButton = ref.watch(historyIsScrolledProvider)
        ? IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ref.read(historySearchTriggerProvider.notifier).state = DateTime.now();
            },
          )
        : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          automaticallyImplyLeading: false,
          title: Text(Tr.t('historyHub', lang)),
          centerTitle: true,
          leading: CustomTopBarHelper.buildLeading(
            context: context,
            isRtl: isRtl,
            hasBackButton: Navigator.canPop(context),
            searchButton: searchButton,
          ),
          actions: CustomTopBarHelper.buildActions(
            context: context,
            isRtl: isRtl,
            hasBackButton: Navigator.canPop(context),
            searchButton: searchButton,
          ),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long, size: 18),
                    const SizedBox(width: 6),
                    Text(Tr.t('auto_OrderHistory', lang)),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(Tr.t('auto_PaymentHistory', lang)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical) {
              final isScrolled = notification.metrics.pixels > 60;
              if (isScrolled != ref.read(historyIsScrolledProvider)) {
                Future.microtask(() => ref.read(historyIsScrolledProvider.notifier).state = isScrolled);
              }
            }
            return false;
          },
          child: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: [
              AdminOrdersScreen(
                isEmbedded: true,
                initialSearchQuery: widget.initialSearchQuery,
              ),
              PaymentHistoryScreen(
                isEmbedded: true,
                initialSearchQuery: widget.initialSearchQuery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
