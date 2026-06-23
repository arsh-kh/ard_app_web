import 'package:flutter/services.dart';
import '../../core/utils/app_translations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/order_entity.dart';
import '../../data/models/customer_entity.dart';
import '../utils/currency_formatter.dart';

class PdfInvoiceLedgerService {
  static Future<Uint8List> generateLedger({
    required List<OrderEntity> orders,
    required List<CustomerEntity> customers,
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

    final primaryColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final accentColor = PdfColor.fromHex('#3B82F6'); // Blue 500
    final secondaryColor = PdfColor.fromHex('#F8FAFC'); // Slate 50
    final borderColor = PdfColor.fromHex('#E2E8F0'); // Slate 200

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [
            fontRegular,
            fontBold,
          ],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          final langCode = isKurdish
              ? 'ku'
              : isArabic
              ? 'ar'
              : 'en';
          final tTitle = Tr.t('auto_INVOICESLEDGER', langCode);
          final tPeriod = Tr.t('auto_Period', langCode);
          final tGenerated = Tr.t('auto_Generated', langCode);
          final tCompany = Tr.t('auto_ArdWholesale', langCode);
          final tDesc = Tr.t('auto_FlourDistributi', langCode);
          final tFooter = Tr.t('auto_Thisisanautomat', langCode);

          final tTotalOrders = Tr.t('auto_TotalOrders', langCode);
          final tTotalAmount = Tr.t('auto_TotalRevenue', langCode);

          final double totalRevenue = orders.fold(
            0,
            (sum, order) => sum + order.totalAmount,
          );

          return [
            // Premium Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
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
                              periodName,
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

            // Summary Cards (Moved to top!)
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
                            tTotalOrders,
                            style: const pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          orders.length.toString(),
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
                      color: PdfColor.fromHex('#F0F9FF'), // Light blue tint
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#BFDBFE'),
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
                              color: accentColor,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Text(
                            CurrencyFormatter.format(totalRevenue),
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
              orders,
              customers,
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
    List<OrderEntity> orders,
    List<CustomerEntity> customers, {
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
    final tEmpty = Tr.t('auto_Noordersfoundin', langCode);

    if (orders.isEmpty) {
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

    final tDate = Tr.t('auto_Date', langCode);
    final tInvoice = Tr.t('auto_Invoice', langCode);
    final tCustomer = Tr.t('auto_Customer', langCode);
    final tAmount = Tr.t('auto_Amount', langCode);

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
            1: const pw.FlexColumnWidth(1.2), // Invoice #
            2: const pw.FlexColumnWidth(3), // Customer
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
                      tInvoice,
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
                      tCustomer,
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
            ...List.generate(orders.length, (index) {
              final o = orders[index];
              final isEven = index % 2 == 0;
              final customer = customers.firstWhere(
                (c) => c.id == o.customerId,
                orElse: () => const CustomerEntity(
                  id: 'unknown',
                  businessName: 'Unknown',
                  phone: '',
                  debtBalance: 0,
                ),
              );

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
                        dateFormat.format(o.orderDate),
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
                        o.orderNumber?.toString() ?? '...',
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
                      textDirection: (isKurdish || isArabic)
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                      child: pw.Text(
                        customer.businessName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
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
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        CurrencyFormatter.format(o.totalAmount),
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
