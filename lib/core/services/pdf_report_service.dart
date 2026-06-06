import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/providers/dashboard_providers.dart';
import '../utils/currency_formatter.dart';

class PdfReportService {
  static Future<Uint8List> generateReport({
    required ReportData reportData,
    required String periodName,
    required bool isMonth,
    required bool isKurdish,
    required bool isArabic,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final generatedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'));
    
    final primaryColor = PdfColor.fromHex('#1E293B'); // Slate 800
    final secondaryColor = PdfColor.fromHex('#F8FAFC'); // Slate 50

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [pw.Font.helvetica(), pw.Font.helveticaBold(), fontRegular, fontBold],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          final tTitle = isMonth 
            ? (isKurdish ? 'ڕاپۆرتی مانگانە' : isArabic ? 'تقرير شهري' : 'MONTHLY REPORT')
            : (isKurdish ? 'ڕاپۆرتی ساڵانە' : isArabic ? 'تقرير سنوي' : 'YEARLY REPORT');
            
          final tPeriod = isKurdish ? 'ماوە' : isArabic ? 'الفترة' : 'Period';
          final tGenerated = isKurdish ? 'دەرچووە لە' : isArabic ? 'تاريخ الإصدار' : 'Generated';
          final tDesc = isKurdish ? 'دابەشکردنی ئارد و کۆگا' : isArabic ? 'توزيع الطحين والمخزون' : 'Flour Distribution & Inventory';
          final tSummary = isKurdish ? 'پوختەی دارایی' : isArabic ? 'ملخص مالي' : 'Financial Summary';
          final tCompany = isKurdish ? 'ئارد - کۆفرۆشی' : isArabic ? 'آرد - جملة' : 'Ard - Wholesale';
          final tTopProducts = isKurdish ? 'پڕفرۆشترین کاڵاکان' : isArabic ? 'المنتجات الأكثر مبيعاً' : 'Top Selling Products';
          final tTopCustomers = isKurdish ? 'باشترین کڕیارەکان' : isArabic ? 'أفضل العملاء' : 'Top Customers';
          final tFooter = isKurdish ? 'ئەم ڕاپۆرتە بەشێوەیەکی ئۆتۆماتیکی دروستکراوە.' : isArabic ? 'تم إنشاء هذا التقرير تلقائيًا.' : 'This is an automatically generated system report.';
          final tNetProfit = isKurdish ? 'قازانجی ساف:' : isArabic ? 'صافي الربح:' : 'Net Profit:';
          final tTotalOrders = isKurdish ? 'کۆی داواکارییەکان' : isArabic ? 'إجمالي الطلبات' : 'Total Orders Executed';
          final tTotalRev = isKurdish ? 'کۆی داهات' : isArabic ? 'إجمالي الإيرادات' : 'Total Revenue (Gross)';
          final tTotalExp = isKurdish ? 'تێچووی کڕین' : isArabic ? 'إجمالي المشتريات' : 'Total Purchases (Expenses)';

          return [
              // Premium Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Directionality(
                          textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          child: pw.Text(
                            tTitle,
                            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text('$tPeriod: ', style: pw.TextStyle(color: PdfColors.grey300, fontSize: 12)),
                              pw.Text(periodName, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                            ]
                          )
                        ),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text('$tGenerated: ', style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                              pw.Text(generatedDate, style: pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
                            ]
                          )
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Directionality(
                          textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          child: pw.Text(tCompany, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Directionality(
                          textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                          child: pw.Text(tDesc, style: pw.TextStyle(color: PdfColors.grey300, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // Summary Title
              pw.Directionality(
                textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Text(tSummary, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              ),
              pw.SizedBox(height: 8),

              // Metrics Table
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    _buildTableRow(tTotalOrders, reportData.ordersCount.toString(), isRtl: isKurdish || isArabic),
                    _buildTableRow(tTotalRev, CurrencyFormatter.format(reportData.revenue), isRtl: isKurdish || isArabic, isGrey: true),
                    _buildTableRow(tTotalExp, CurrencyFormatter.format(reportData.cogs), isRtl: isKurdish || isArabic),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Net Profit Highlighting
              pw.Row(
                mainAxisAlignment: (isKurdish || isArabic) ? pw.MainAxisAlignment.start : pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: pw.BoxDecoration(
                      color: secondaryColor,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      border: pw.Border.all(color: primaryColor, width: 2)
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Row(
                        children: [
                          if (isKurdish || isArabic) ...[
                            pw.Text(
                              CurrencyFormatter.format(reportData.profit), 
                              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: reportData.profit >= 0 ? PdfColors.green700 : PdfColors.red700)
                            ),
                            pw.SizedBox(width: 12),
                            pw.Directionality(
                              textDirection: pw.TextDirection.rtl,
                              child: pw.Text(tNetProfit, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor))
                            ),
                          ] else ...[
                            pw.Text('$tNetProfit ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text(
                              CurrencyFormatter.format(reportData.profit), 
                              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: reportData.profit >= 0 ? PdfColors.green700 : PdfColors.red700)
                            ),
                          ]
                        ]
                      ),
                    )
                  )
                ],
              ),

              // --- Top Products Table ---
              pw.SizedBox(height: 32),
              pw.Directionality(
                textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Text(tTopProducts, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              ),
              pw.SizedBox(height: 12),
              _buildProductsTable(reportData.topProducts, isKurdish: isKurdish, isArabic: isArabic, primaryColor: primaryColor),

              // --- Top Customers Table ---
              pw.SizedBox(height: 32),
              pw.Directionality(
                textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                child: pw.Text(tTopCustomers, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: primaryColor)),
              ),
              pw.SizedBox(height: 12),
              _buildCustomersTable(reportData.topCustomers, isKurdish: isKurdish, isArabic: isArabic, primaryColor: primaryColor),

              pw.SizedBox(height: 48),

              // Footer
              pw.Center(
                child: pw.Directionality(
                  textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
                  child: pw.Text(
                    tFooter,
                    style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                  ),
                )
              ),
            ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String title, String value, {bool isRtl = false, bool isGrey = false}) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isGrey ? PdfColors.grey100 : PdfColors.white,
        border: const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: pw.Directionality(
            textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.Text(title, style: const pw.TextStyle(fontSize: 14)),
          )
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Text(
              value, 
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              textAlign: isRtl ? pw.TextAlign.left : pw.TextAlign.right,
            )
          )
        ),
      ]
    );
  }

  static pw.Widget _buildProductsTable(List<ProductPerformance> products, {required bool isKurdish, required bool isArabic, required PdfColor primaryColor}) {
    final tEmpty = isKurdish ? 'هیچ فرۆشێک تۆمار نەکراوە.' : isArabic ? 'لم يتم تسجيل أي مبيعات.' : 'No product sales recorded.';
    
    if (products.isEmpty) {
      return pw.Directionality(
        textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Text(tEmpty, style: const pw.TextStyle(color: PdfColors.grey600))
      );
    }

    final tName = isKurdish ? 'کاڵا' : isArabic ? 'المنتج' : 'Product Name';
    final tQty = isKurdish ? 'بڕ' : isArabic ? 'الكمية' : 'Qty Sold';
    final tRev = isKurdish ? 'داهات' : isArabic ? 'الإيرادات' : 'Revenue';
    final tProf = isKurdish ? 'قازانج' : isArabic ? 'الربح' : 'Profit';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tQty, textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tRev, textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tProf, textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
          ]
        ),
        // Rows
        ...List.generate(products.length, (index) {
          final p = products[index];
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(p.productName))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text(p.quantitySold.toStringAsFixed(0), textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text(CurrencyFormatter.format(p.revenue), textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text(CurrencyFormatter.format(p.profit), textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right))),
            ]
          );
        }),
      ]
    );
  }

  static pw.Widget _buildCustomersTable(List<CustomerPerformance> customers, {required bool isKurdish, required bool isArabic, required PdfColor primaryColor}) {
    final tEmpty = isKurdish ? 'هیچ کڕیارێک تۆمار نەکراوە.' : isArabic ? 'لم يتم تسجيل أي عميل.' : 'No customer activity recorded.';
    if (customers.isEmpty) {
      return pw.Directionality(
        textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        child: pw.Text(tEmpty, style: const pw.TextStyle(color: PdfColors.grey600))
      );
    }

    final tName = isKurdish ? 'کڕیار' : isArabic ? 'العميل' : 'Customer Name';
    final tOrd = isKurdish ? 'داواکاری' : isArabic ? 'الطلبات' : 'Orders';
    final tSpn = isKurdish ? 'پارەی خەرجکراو' : isArabic ? 'المبلغ المنفق' : 'Total Spent';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tOrd, textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
            pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(tSpn, textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white)))),
          ]
        ),
        // Rows
        ...List.generate(customers.length, (index) {
          final c = customers[index];
          final isEven = index % 2 == 0;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? PdfColors.grey50 : PdfColors.white),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: (isKurdish || isArabic) ? pw.TextDirection.rtl : pw.TextDirection.ltr, child: pw.Text(c.customerName))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text(c.orderCount.toString(), textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right))),
              pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Directionality(textDirection: pw.TextDirection.ltr, child: pw.Text(CurrencyFormatter.format(c.totalSpent), textAlign: (isKurdish || isArabic) ? pw.TextAlign.left : pw.TextAlign.right))),
            ]
          );
        }),
      ]
    );
  }
}
