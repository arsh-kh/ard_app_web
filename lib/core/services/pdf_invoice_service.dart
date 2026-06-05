import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/order_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../utils/currency_formatter.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice({
    required OrderEntity order,
    required CustomerEntity customer,
    required List<OrderItemEntity> items,
    required List<ProductEntity> products, // Needed for product names
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
                    pw.Text('وەسڵ / INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice #: ${order.orderNumber ?? "..."}', textDirection: pw.TextDirection.ltr),
                    pw.Text('Date: ${dateFormat.format(order.orderDate)}', textDirection: pw.TextDirection.ltr),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ئارد - Ard B2B Wholesale', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Flour Distribution & Inventory', textDirection: pw.TextDirection.ltr),
                    pw.Text('Contact: +964 XXX XXXX', textDirection: pw.TextDirection.ltr),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Customer Info
            pw.Text('کڕیار / Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text(customer.businessName, style: pw.TextStyle(fontSize: 14)),
            if (customer.address != null && customer.address!.isNotEmpty)
              pw.Text(customer.address!),
            pw.Text('قەرزی پێشوو / Current Debt Balance: ${CurrencyFormatter.format(customer.debtBalance)}'),
            pw.SizedBox(height: 32),

            // Items Table
            _buildItemsTable(items, products),
            
            pw.SizedBox(height: 16),
            
            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey200,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('کۆی گشتی / Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Text(CurrencyFormatter.format(order.totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                    ]
                  )
                )
              ]
            ),
            
            pw.SizedBox(height: 32),
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Thank you for your business!',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemsTable(List<OrderItemEntity> items, List<ProductEntity> products) {
    return pw.TableHelper.fromTextArray(
      headers: ['کاڵا / Item', 'دانە / Qty', 'نرخ / Price', 'کۆی گشتی / Total'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      data: items.map((item) {
        // Find product name
        final product = products.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => ProductEntity(
            id: 'unknown', 
            name: 'Unknown Product', 
            categoryId: '', 
            buyPrice: 0, 
            sellPrice: 0, 
            stockQuantity: 0, 
            unitType: '', 
          ),
        );
        
        final total = item.quantity * item.unitPrice;
        
        return [
          product.name,
          '${item.quantity}',
          CurrencyFormatter.format(item.unitPrice),
          CurrencyFormatter.format(total),
        ];
      }).toList(),
    );
  }
}

