import 'package:flutter/services.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/arabic_reshaper_utils.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/purchase_entity.dart';
import '../utils/currency_formatter.dart';

class PdfPurchaseLedgerService {
  static Future<Uint8List> generateLedger({
    required List<PurchaseEntity> purchases,
    required String periodName,
    required bool isKurdish,
    required bool isArabic,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final generatedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'),
    );

    const primaryColor = PdfColors.black;
    const secondaryColor = PdfColors.grey200;
    const borderColor = PdfColors.grey400;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold, pw.Font.helvetica()],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          final langCode = isKurdish
              ? 'ku'
              : isArabic
              ? 'ar'
              : 'en';
          final tTitle = ArabicReshaperUtils.reshape(Tr.t('auto_PURCHASESLEDGER', langCode));
          final tPeriod = ArabicReshaperUtils.reshape(Tr.t('auto_Period', langCode));
          final tGenerated = ArabicReshaperUtils.reshape(Tr.t('auto_Generated', langCode));
          final tCompany = ArabicReshaperUtils.reshape(Tr.t('auto_ArdWholesale', langCode));
          final tDesc = ArabicReshaperUtils.reshape(Tr.t('auto_FlourDistributi', langCode));
          final tFooter = ArabicReshaperUtils.reshape(Tr.t('auto_Thisisanautomat', langCode));

          final tTotalPurchasesRaw = Tr.t('summaryPurchases', langCode)
              .split('·')
              .first
              .replaceAll('{count}', ''); // Extracting "purchases" word
          final tTotalPurchases = ArabicReshaperUtils.reshape(tTotalPurchasesRaw);
          final tTotalAmount = ArabicReshaperUtils.reshape(Tr.t('auto_Amount', langCode));

          final double totalExpenses = purchases.fold(
            0,
            (sum, p) => sum + (p.totalAmount - p.totalReturnedAmount),
          );

          return [
            // Premium Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: const pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Directionality(
                        textDirection: (isKurdish || isArabic)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        child: pw.Text(
                          tTitle,
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Directionality(
                        textDirection: pw.TextDirection.ltr,
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              '$tPeriod: ',
                              style: const pw.TextStyle(
                                color: PdfColors.grey400,
                                fontSize: 11,
                              ),
                            ),
                            pw.Text(
                              ArabicReshaperUtils.reshape(periodName),
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Directionality(
                        textDirection: pw.TextDirection.ltr,
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              '$tGenerated: ',
                              style: const pw.TextStyle(
                                color: PdfColors.grey400,
                                fontSize: 9,
                              ),
                            ),
                            pw.Text(
                              generatedDate,
                              style: const pw.TextStyle(
                                color: PdfColors.grey400,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Directionality(
                        textDirection: (isKurdish || isArabic)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        child: pw.Text(
                          tCompany,
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Directionality(
                        textDirection: (isKurdish || isArabic)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        child: pw.Text(
                          tDesc,
                          style: const pw.TextStyle(
                            color: PdfColors.grey400,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Summary Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(color: borderColor, width: 1.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Directionality(
                          textDirection: (isKurdish || isArabic)
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                          child: pw.Text(
                            tTotalPurchases,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          purchases.length.toString(),
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(
                        color: PdfColors.grey300,
                        width: 1.5,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Directionality(
                          textDirection: (isKurdish || isArabic)
                              ? pw.TextDirection.rtl
                              : pw.TextDirection.ltr,
                          child: pw.Text(
                            tTotalAmount,
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Text(
                            CurrencyFormatter.format(totalExpenses),
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 32),

            // Ledger Table
            _buildLedgerTable(
              purchases,
              isKurdish: isKurdish,
              isArabic: isArabic,
              primaryColor: primaryColor,
              borderColor: borderColor,
              dateFormat: dateFormat,
            ),

            pw.SizedBox(height: 48),

            // Footer
            pw.Center(
              child: pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tFooter,
                  style: const pw.TextStyle(
                    color: PdfColors.grey500,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildLedgerTable(
    List<PurchaseEntity> purchases, {
    required bool isKurdish,
    required bool isArabic,
    required PdfColor primaryColor,
    required PdfColor borderColor,
    required DateFormat dateFormat,
  }) {
    final langCode = isKurdish
        ? 'ku'
        : isArabic
        ? 'ar'
        : 'en';
    final tEmpty = ArabicReshaperUtils.reshape(Tr.t('auto_Noordersfoundin', langCode));

    if (purchases.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(32),
        alignment: pw.Alignment.center,
        child: pw.Directionality(
          textDirection: (isKurdish || isArabic)
              ? pw.TextDirection.rtl
              : pw.TextDirection.ltr,
          child: pw.Text(
            tEmpty,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 14),
          ),
        ),
      );
    }

    final tDate = ArabicReshaperUtils.reshape(Tr.t('auto_Date', langCode));
    final tPurchaseNo = ArabicReshaperUtils.reshape(Tr.t('auto_PurchaseNo', langCode));
    final tStatus = ArabicReshaperUtils.reshape(Tr.t('auto_Status', langCode));
    final tAmount = ArabicReshaperUtils.reshape(Tr.t('auto_Amount', langCode));

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 12,
        verticalRadius: 12,
        child: pw.Table(
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 1),
            verticalInside: pw.BorderSide.none,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2), // Date
            1: const pw.FlexColumnWidth(1.2), // Purchase #
            2: const pw.FlexColumnWidth(2), // Status
            3: const pw.FlexColumnWidth(2), // Amount
          },
          children: [
            // Beautiful Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: primaryColor),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: pw.Directionality(
                    textDirection: (isKurdish || isArabic)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    child: pw.Text(
                      tDate,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: pw.Directionality(
                    textDirection: (isKurdish || isArabic)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    child: pw.Text(
                      tPurchaseNo,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: pw.Directionality(
                    textDirection: (isKurdish || isArabic)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    child: pw.Text(
                      tStatus,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: pw.Directionality(
                    textDirection: (isKurdish || isArabic)
                        ? pw.TextDirection.rtl
                        : pw.TextDirection.ltr,
                    child: pw.Text(
                      tAmount,
                      textAlign: (isKurdish || isArabic)
                          ? pw.TextAlign.left
                          : pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Rows
            ...List.generate(purchases.length, (index) {
              final p = purchases[index];
              final isEven = index % 2 == 0;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                ),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        dateFormat.format(p.purchaseDate),
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                        textAlign: (isKurdish || isArabic)
                            ? pw.TextAlign.right
                            : pw.TextAlign.left,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        p.purchaseNumber?.toString() ?? '...',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                        textAlign: (isKurdish || isArabic)
                            ? pw.TextAlign.right
                            : pw.TextAlign.left,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        ArabicReshaperUtils.reshape(p.status.toUpperCase()),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: (isKurdish || isArabic)
                            ? pw.TextAlign.right
                            : pw.TextAlign.left,
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        CurrencyFormatter.format(
                          p.totalAmount - p.totalReturnedAmount,
                        ),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                        textAlign: (isKurdish || isArabic)
                            ? pw.TextAlign.left
                            : pw.TextAlign.right,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
