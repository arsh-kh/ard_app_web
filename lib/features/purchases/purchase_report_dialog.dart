import 'package:flutter/material.dart';
import '../../core/utils/pdf_interceptor.dart';

import '../../core/widgets/custom_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/purchase_providers.dart';
import '../../core/services/html_generator_service.dart';
import '../../core/providers/business_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/heavy_ios_button.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/feedback_utils.dart';
import '../../core/utils/app_date_range_picker.dart';

class PurchaseReportDialog extends ConsumerStatefulWidget {
  const PurchaseReportDialog({super.key});

  @override
  ConsumerState<PurchaseReportDialog> createState() =>
      _PurchaseReportDialogState();
}

class _PurchaseReportDialogState extends ConsumerState<PurchaseReportDialog> {
  String _selectedRange = 'week';
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _isLoading = false;

  void _generateReport() async {
    final lang = ref.read(localeProvider).languageCode;
    if (_selectedRange == 'custom' &&
        (_customStart == null || _customEnd == null)) {
      AppFeedback.showError(context, Tr.t('selectDatesError', lang));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      DateTime start;
      DateTime end;
      String periodName;
      final langCode = ref.read(localeProvider).languageCode;
      final isKurdish = langCode == 'ku';
      final isArabic = langCode == 'ar';

      switch (_selectedRange) {
        case 'week':
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = start.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          );
          periodName = Tr.t('auto_ThisWeek', langCode);
          break;
        case 'month':
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          periodName = Tr.t('auto_ThisMonth', langCode);
          break;
        case 'year':
          start = DateTime(now.year, 1, 1);
          end = DateTime(now.year, 12, 31, 23, 59, 59);
          periodName = Tr.t('auto_ThisYear', langCode);
          break;
        case 'custom':
        default:
          start = DateTime(
            _customStart!.year,
            _customStart!.month,
            _customStart!.day,
          );
          end = DateTime(
            _customEnd!.year,
            _customEnd!.month,
            _customEnd!.day,
            23,
            59,
            59,
          );
          final df = DateFormat('dd/MM/yyyy');
          periodName = '${df.format(start)} - ${df.format(end)}';
          break;
      }

      final purchaseRepo = ref.read(purchaseRepositoryProvider);

      final allPurchases = await purchaseRepo.getAllPurchases();
      final filteredPurchases = allPurchases
          .where(
            (p) =>
                p.purchaseDate.isAfter(
                  start.subtract(const Duration(seconds: 1)),
                ) &&
                p.purchaseDate.isBefore(end.add(const Duration(seconds: 1))),
          )
          .toList();

      filteredPurchases.sort(
        (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
      );

      final tDate = Tr.t('auto_Date', langCode);
      final tPurchaseNo = Tr.t('auto_PurchaseNo', langCode);
      final tAmount = Tr.t('auto_Amount', langCode);

      final dateFormat = DateFormat('dd/MM/yyyy');
      final rows = filteredPurchases.map((purchase) {
        final netAmount = purchase.totalAmount - purchase.totalReturnedAmount;
        return [
          dateFormat.format(purchase.purchaseDate),
          purchase.purchaseNumber?.toString() ?? purchase.id.substring(0, 8),
          CurrencyFormatter.format(netAmount, forPrint: true),
        ];
      }).toList();

      final totalAmount = filteredPurchases.fold(0.0, (sum, purchase) => sum + (purchase.totalAmount - purchase.totalReturnedAmount));
      final business = ref.read(currentBusinessEntityProvider).valueOrNull;

      if (!context.mounted) return;
      if (!await PdfInterceptor.checkAndNavigate(context)) return;
      await HtmlGeneratorService.generateAndLaunchLedger(
        title: Tr.t('auto_PURCHASESLEDGER', langCode),
        periodName: periodName,
        headers: [tDate, tPurchaseNo, tAmount],
        rows: rows,
        totalLabel: Tr.t('auto_TotalPurchases', langCode),
        totalAmount: totalAmount,
        isKurdish: isKurdish,
        isArabic: isArabic,
        shopName: business?.name ?? Tr.t('auto_ArdWholesale', langCode),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        AppFeedback.showError(context, e);
      }
    }
  }

  Future<void> _pickDateRange() async {
    final langCode = ref.read(localeProvider).languageCode;
    final picked = await showAppDateRangePicker(
      context: context,
      langCode: langCode,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
        _selectedRange = 'custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(localeProvider).languageCode;
    final theme = Theme.of(context);

    final tTitle = Tr.t('auto_PurchasesReport', langCode);
    final tDesc = Tr.t('auto_Selectaperiodto', langCode);
    final tWeek = Tr.t('auto_ThisWeek', langCode);
    final tMonth = Tr.t('auto_ThisMonth', langCode);
    final tYear = Tr.t('auto_ThisYear', langCode);
    final tCustom = Tr.t('auto_CustomRange', langCode);
    final tGenerate = Tr.t('auto_GenerateReport', langCode);

    return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tDesc,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Grid Options
                Row(
                  children: [
                    Expanded(
                      child: _buildPremiumCard(
                        'week',
                        tWeek,
                        Icons.view_week_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPremiumCard(
                        'month',
                        tMonth,
                        Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPremiumCard(
                        'year',
                        tYear,
                        Icons.insert_invitation_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCustomCard(tCustom)),
                  ],
                ),

                const SizedBox(height: 32),

                // Action Button
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CustomLoader(),
                        ),
                      )
                    : HeavyIOSButton(
                        label: tGenerate,
                        icon: Icons.print_rounded,
                        onTap: _generateReport,
                      ).animate().scale(
                        duration: 200.ms,
                        curve: Curves.easeOutCubic,
                      ),

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      Tr.t(
                        'auto_Cancel',
                        ref.read(localeProvider).languageCode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fade(duration: 250.ms)
        .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutQuad);
  }

  Widget _buildPremiumCard(String value, String label, IconData icon) {
    final isSelected = _selectedRange == value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedRange = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : (Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : (Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomCard(String label) {
    final isSelected = _selectedRange == 'custom';
    final theme = Theme.of(context);
    final langCode = ref.watch(localeProvider).languageCode;

    String formatDate(DateTime date) {
      if (langCode == 'ku') {
        const months = [
          'مانگی یەک',
          'مانگی دوو',
          'مانگی سێ',
          'مانگی چوار',
          'مانگی پێنج',
          'مانگی شەش',
          'مانگی حەوت',
          'مانگی هەشت',
          'مانگی نۆ',
          'مانگی دە',
          'مانگی یانزە',
          'مانگی دوانزە',
        ];
        return '${date.day} ${months[date.month - 1]}';
      }
      return DateFormat('MMM d', langCode).format(date);
    }

    final hasDate = _customStart != null && _customEnd != null;
    final displayLabel = hasDate
        ? '${formatDate(_customStart!)} - ${formatDate(_customEnd!)}'
        : label;

    return GestureDetector(
      onTap: _pickDateRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : (Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 32,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : (Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              displayLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : (Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
