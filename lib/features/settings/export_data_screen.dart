import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/utils/app_translations.dart';
import '../../core/providers/customer_providers.dart';
import '../../core/providers/inventory_providers.dart';
import '../../core/providers/order_providers.dart';
import '../../core/providers/payment_providers.dart';
import '../../core/providers/purchase_providers.dart';
import '../../core/providers/business_provider.dart';

import '../../data/models/audit_log_entity.dart';
import '../../core/widgets/custom_top_bar_helper.dart';
import 'export_data_service.dart';

class ExportDataScreen extends ConsumerWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);
    final isRtl = langCode == 'ku' || langCode == 'ar';
    final businessId = ref.read(currentBusinessIdProvider) ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          Tr.t('exportDataAction', langCode),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        leading: CustomTopBarHelper.buildLeading(
          context: context,
          isRtl: isRtl,
          hasBackButton: Navigator.canPop(context),
        ),
        actions: CustomTopBarHelper.buildActions(
          context: context,
          isRtl: isRtl,
          hasBackButton: Navigator.canPop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECURE FULL BACKUP
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 28,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      langCode == 'ku'
                          ? 'دابەزاندنی کۆپییەکی تەواو لە هەموو داتاکانی کارەکەت بۆ پاراستنیان لە لەناوچوون.'
                          : langCode == 'ar'
                          ? 'تنزيل نسخة كاملة من جميع بيانات عملك لحمايتها من الضياع.'
                          : 'Download a complete copy of all your business data to keep it safe.',
                      textDirection: isRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildExportCard(
              theme: theme,
              icon: Icons.security_rounded,
              title: Tr.t('secureFullBackup', langCode),
              subtitle: langCode == 'ku'
                  ? 'کۆپییەکی تەواو'
                  : langCode == 'ar'
                  ? 'نسخة كاملة'
                  : 'Complete Copy',
              isRtl: isRtl,
              onTap: () async {
                _showLoading(context, langCode);
                final fullData = await _gatherFullBackupData(ref, businessId);
                if (context.mounted) Navigator.pop(context);
                await ExportDataService.exportFullBackup(fullData);
              },
            ),
            const SizedBox(height: 32),

            // SALES & CUSTOMERS
            _buildSectionHeader(
              theme,
              langCode == 'ku'
                  ? 'فرۆشتن و کڕیارەکان'
                  : langCode == 'ar'
                  ? 'المبيعات والعملاء'
                  : 'Sales & Customers',
            ),
            _buildExportCard(
              theme: theme,
              icon: Icons.people_rounded,
              title: Tr.t('exportCustomers', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final customers = await ref
                    .read(customerRepositoryProvider)
                    .getAllCustomers();
                await ExportDataService.exportCustomers(customers);
              },
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              theme: theme,
              icon: Icons.analytics_rounded,
              title: Tr.t('exportMonthlySales', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final orders = await ref
                    .read(orderRepositoryProvider)
                    .getAllOrders();
                await ExportDataService.exportMonthlySales(orders);
              },
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              theme: theme,
              icon: Icons.attach_money_rounded,
              title: Tr.t('exportCustomerPayments', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final payments = await ref
                    .read(paymentRepositoryProvider)
                    .getAllPayments();
                await ExportDataService.exportCustomerPayments(payments);
              },
            ),

            const SizedBox(height: 24),

            // PURCHASES
            _buildSectionHeader(
              theme,
              langCode == 'ku'
                  ? 'کڕینەکان'
                  : langCode == 'ar'
                  ? 'المشتريات'
                  : 'Purchases',
            ),
            _buildExportCard(
              theme: theme,
              icon: Icons.shopping_cart_checkout_rounded,
              title: Tr.t('exportPurchases', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final purchases = await ref
                    .read(purchaseRepositoryProvider)
                    .getAllPurchases();
                await ExportDataService.exportPurchases(purchases);
              },
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 24),

            // INVENTORY & SYSTEM
            _buildSectionHeader(
              theme,
              langCode == 'ku'
                  ? 'کۆگا و تۆمارەکان'
                  : langCode == 'ar'
                  ? 'المخزون والسجلات'
                  : 'Inventory & Logs',
            ),
            _buildExportCard(
              theme: theme,
              icon: Icons.inventory_2_rounded,
              title: Tr.t('exportInventory', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final products = await ref
                    .read(inventoryRepositoryProvider)
                    .getAllProducts();
                await ExportDataService.exportInventory(products);
              },
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              theme: theme,
              icon: Icons.history_rounded,
              title: Tr.t('exportAuditLogs', langCode),
              subtitle: Tr.t('csvFormat', langCode),
              isRtl: isRtl,
              onTap: () async {
                final snapshot = await FirebaseFirestore.instance
                    .collection('audit_logs')
                    .where('businessId', isEqualTo: businessId)
                    .get();
                final logs = snapshot.docs
                    .map(
                      (doc) => AuditLogEntity.fromJson({
                        'id': doc.id,
                        ...doc.data(),
                      }),
                    )
                    .toList();
                await ExportDataService.exportAuditLogs(logs);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showLoading(BuildContext context, String langCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<Map<String, dynamic>> _gatherFullBackupData(
    WidgetRef ref,
    String businessId,
  ) async {
    final db = FirebaseFirestore.instance;
    final Map<String, dynamic> backup = {};

    final collections = [
      'customers',
      'inventory',
      'orders',
      'payments',
      'purchases',
      'suppliers',
      'supplier_payments',
      'audit_logs',
      'returns',
      'purchase_returns',
    ];

    for (var col in collections) {
      final snap = await db
          .collection(col)
          .where('businessId', isEqualTo: businessId)
          .get();
      backup[col] = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
    }

    return backup;
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isRtl,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection: isRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
