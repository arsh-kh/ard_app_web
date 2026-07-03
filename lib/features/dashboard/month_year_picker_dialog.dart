import 'package:flutter/material.dart';
import '../../core/utils/pdf_interceptor.dart';

import '../../core/utils/app_translations.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/html_generator_service.dart';


class ReportPickerModal extends ConsumerStatefulWidget {
  final bool isMonth;
  const ReportPickerModal({super.key, required this.isMonth});

  @override
  ConsumerState<ReportPickerModal> createState() => _ReportPickerModalState();
}

class _ReportPickerModalState extends ConsumerState<ReportPickerModal> {
  DateTime selectedDate = DateTime.now();
  ReportData? reportData;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      reportData = null;
    });
    DateTime start;
    DateTime end;

    if (widget.isMonth) {
      start = DateTime(selectedDate.year, selectedDate.month, 1);
      end = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
    } else {
      start = DateTime(selectedDate.year, 1, 1);
      end = DateTime(selectedDate.year, 12, 31, 23, 59, 59);
    }

    try {

      final langCode = ref.read(localeProvider).languageCode;
      final data = await fetchReportData(ref, start, end, langCode);
      setState(() {
        reportData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _next() {
    setState(() {
      if (widget.isMonth) {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
      } else {
        selectedDate = DateTime(selectedDate.year + 1, 1, 1);
      }
    });
    _fetchData();
  }

  void _prev() {
    setState(() {
      if (widget.isMonth) {
        selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      } else {
        selectedDate = DateTime(selectedDate.year - 1, 1, 1);
      }
    });
    _fetchData();
  }

  Future<void> _printReport(String dateLabel, bool isMonth) async {
    if (reportData == null) return;
    final currentLocale = ref.read(localeProvider);
    try {
      if (!context.mounted) return;
      if (!await PdfInterceptor.checkAndNavigate(context)) return;
      await HtmlGeneratorService.generateAndLaunchReport(
        reportData: reportData!,
        periodName: dateLabel,
        isMonth: isMonth,
        isKurdish: currentLocale.languageCode == 'ku',
        isArabic: currentLocale.languageCode == 'ar',
      );
    } catch (e) {
      if (mounted) {

        AppFeedback.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final isKurdish = langCode == 'ku';
    final isArabic = langCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateLabel = widget.isMonth
        ? DateFormat.yMMMM().format(selectedDate)
        : DateFormat.y().format(selectedDate);

    final title = widget.isMonth
        ? (Tr.t('auto_MonthlyReport', langCode))
        : (Tr.t('auto_YearlyReport', langCode));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _prev,
                  icon: const Icon(Icons.chevron_left, size: 30),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: _next,
                  icon: const Icon(Icons.chevron_right, size: 30),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CustomLoader(),
                ),
              )
            else if (reportData != null) ...[
              _buildStatRow(
                'auto_TotalOrders',
                reportData!.ordersCount.toString(),
                isKurdish,
                isArabic,
                Icons.shopping_bag,
                Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                'auto_TotalRevenue',
                CurrencyFormatter.format(reportData!.revenue),
                isKurdish,
                isArabic,
                Icons.trending_up,
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatRow(
                'auto_TotalPurchases',
                CurrencyFormatter.format(reportData!.cogs),
                isKurdish,
                isArabic,
                Icons.inventory,
                Colors.orange,
              ),
              const Divider(height: 32, thickness: 2),
              _buildStatRow(
                'auto_NetProfit_1',
                CurrencyFormatter.format(reportData!.profit),
                isKurdish,
                isArabic,
                Icons.account_balance_wallet,
                Colors.purple,
                isTotal: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _printReport(dateLabel, widget.isMonth),
                icon: const Icon(Icons.print),
                label: Text(Tr.t('auto_printReport', langCode)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String enTitle,
    String value,
    bool isKurdish,
    bool isArabic,
    IconData icon,
    MaterialColor color, {
    bool isTotal = false,
  }) {
    final langCode = isKurdish
        ? 'ku'
        : isArabic
        ? 'ar'
        : 'en';
    final String title = Tr.t(enTitle, langCode);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? color : null,
          ),
        ),
      ],
    );
  }
}
