import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../customers/customers_screen.dart';
import '../orders/admin_orders_screen.dart';
import '../../core/providers/locale_provider.dart';

class ClientsOrdersScreen extends ConsumerWidget {
  const ClientsOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isArabic = currentLocale.languageCode == 'ar';
    final isKurdish = currentLocale.languageCode == 'ku';
    
    final title = isKurdish 
        ? 'کڕیارەکان و داواکارییەکان' 
        : isArabic 
            ? 'العملاء والطلبات' 
            : 'Clients & Orders';

    final clientsTab = isKurdish ? 'کڕیارەکان' : isArabic ? 'العملاء' : 'Clients';
    final ordersTab = isKurdish ? 'مێژووی داواکاری' : isArabic ? 'سجل الطلبات' : 'Order History';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: [
              Tab(text: clientsTab),
              Tab(text: ordersTab),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            // Embedded customers view (without its own scaffold appbar if possible, or we just use it directly)
            CustomersScreen(isEmbedded: true),
            
            // Embedded orders view
            AdminOrdersScreen(isEmbedded: true),
          ],
        ),
      ),
    );
  }
}

