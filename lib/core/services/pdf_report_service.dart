import 'dart:typed_data';
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
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final generatedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final fontRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        isMonth ? 'MONTHLY REPORT / ڕاپۆرتی مانگانە' : 'YEARLY REPORT / ڕاپۆرتی ساڵانە',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text('Period: $periodName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textDirection: pw.TextDirection.ltr),
                      pw.Text('Generated: $generatedDate', textDirection: pw.TextDirection.ltr),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ئارد - Ard B2B Wholesale', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Flour Distribution & Inventory', textDirection: pw.TextDirection.ltr),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 48),

              // Summary Title
              pw.Text('پوختەی دارایی / Financial Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 16),

              // Metrics Table
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  _buildTableRow('Total Orders Executed / کۆی داواکارییەکان', reportData.ordersCount.toString()),
                  _buildTableRow('Total Revenue (Gross) / کۆی داهات', CurrencyFormatter.format(reportData.revenue)),
                  _buildTableRow('Total Purchases (Expenses) / تێچووی کڕین', CurrencyFormatter.format(reportData.cogs)),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // Net Profit Highlighting
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blueGrey50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.blueGrey200)
                    ),
                    child: pw.Row(
                      children: [
                        pw.Text('Net Profit: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                          CurrencyFormatter.format(reportData.profit), 
                          style: pw.TextStyle(
                            fontSize: 18, 
                            fontWeight: pw.FontWeight.bold, 
                            color: reportData.profit >= 0 ? PdfColors.green800 : PdfColors.red800
                          )
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // --- Top Products Table ---
              pw.SizedBox(height: 32),
              pw.Text('پڕفرۆشترین کاڵاکان / Top Selling Products', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 8),
              _buildProductsTable(reportData.topProducts),

              // --- Top Customers Table ---
              pw.SizedBox(height: 32),
              pw.Text('باشترین کڕیارەکان / Top Customers', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              pw.SizedBox(height: 8),
              _buildCustomersTable(reportData.topCustomers),

              pw.SizedBox(height: 48),

              // Footer
              pw.Center(
                child: pw.Text(
                  'This is an automatically generated system report.',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                ),
              ),
            ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 14)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  static pw.Widget _buildProductsTable(List<ProductPerformance> products) {
    if (products.isEmpty) {
      return pw.Text('No product sales recorded in this period.', style: const pw.TextStyle(color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Product Name', 'Qty Sold', 'Revenue', 'Profit'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      data: products.map((p) {
        return [
          p.productName,
          p.quantitySold.toStringAsFixed(0),
          CurrencyFormatter.format(p.revenue),
          CurrencyFormatter.format(p.profit),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildCustomersTable(List<CustomerPerformance> customers) {
    if (customers.isEmpty) {
      return pw.Text('No customer activity recorded in this period.', style: const pw.TextStyle(color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Customer Name', 'Orders', 'Total Spent'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      data: customers.map((c) {
        return [
          c.customerName,
          c.orderCount.toString(),
          CurrencyFormatter.format(c.totalSpent),
        ];
      }).toList(),
    );
  }
}
