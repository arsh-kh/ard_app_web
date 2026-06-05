import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:printing/printing.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/widgets/pdf_preview_screen.dart';

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
    setState(() { isLoading = true; reportData = null; });
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
      final data = await fetchReportData(ref, start, end);
      setState(() { reportData = data; isLoading = false; });
    } catch (e) {
      setState(() { isLoading = false; });
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

  Future<void> _exportPdf(String dateLabel, bool isMonth) async {
    if (reportData == null) return;
    try {
      final bytes = await PdfReportService.generateReport(
        reportData: reportData!,
        periodName: dateLabel,
        isMonth: isMonth,
      );
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PdfPreviewScreen(
              title: 'Report_$dateLabel',
              pdfBytes: bytes,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final isKurdish = currentLocale.languageCode == 'ku';
    final isArabic = currentLocale.languageCode == 'ar';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dateLabel = widget.isMonth 
      ? DateFormat.yMMMM().format(selectedDate)
      : DateFormat.y().format(selectedDate);

    final title = widget.isMonth 
      ? (isKurdish ? 'ڕاپۆرتی مانگانە' : isArabic ? 'تقرير شهري' : 'Monthly Report')
      : (isKurdish ? 'ڕاپۆرتی ساڵانە' : isArabic ? 'تقرير سنوي' : 'Yearly Report');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Date Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: _prev, icon: const Icon(Icons.chevron_left, size: 30)),
                Text(dateLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                IconButton(onPressed: _next, icon: const Icon(Icons.chevron_right, size: 30)),
              ],
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
            else if (reportData != null) ...[
              _buildStatRow('Total Orders', reportData!.ordersCount.toString(), isKurdish, isArabic, Icons.shopping_bag, Colors.blue),
              const SizedBox(height: 16),
              _buildStatRow('Total Revenue', CurrencyFormatter.format(reportData!.revenue), isKurdish, isArabic, Icons.trending_up, Colors.green),
              const SizedBox(height: 16),
              _buildStatRow('Total Purchases', CurrencyFormatter.format(reportData!.cogs), isKurdish, isArabic, Icons.inventory, Colors.orange),
              const Divider(height: 32, thickness: 2),
              _buildStatRow('Net Profit', CurrencyFormatter.format(reportData!.profit), isKurdish, isArabic, Icons.account_balance_wallet, Colors.purple, isTotal: true),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _exportPdf(dateLabel, widget.isMonth),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(isKurdish ? 'هەناردەکردنی PDF' : isArabic ? 'تصدير PDF' : 'Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String enTitle, String value, bool isKurdish, bool isArabic, IconData icon, MaterialColor color, {bool isTotal = false}) {
    String title = enTitle;
    if (enTitle == 'Total Orders') title = isKurdish ? 'کۆی داواکارییەکان' : isArabic ? 'إجمالي الطلبات' : 'Total Orders';
    if (enTitle == 'Total Revenue') title = isKurdish ? 'کۆی داهات' : isArabic ? 'إجمالي الإيرادات' : 'Total Revenue';
    if (enTitle == 'Total Purchases') title = isKurdish ? 'کۆی کڕینەکان' : isArabic ? 'إجمالي المشتريات' : 'Total Purchases';
    if (enTitle == 'Net Profit') title = isKurdish ? 'پوختەی قازانج' : isArabic ? 'صافي الربح' : 'Net Profit';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: isTotal ? 18 : 16, fontWeight: FontWeight.bold, color: isTotal ? color : null)),
      ],
    );
  }
}

