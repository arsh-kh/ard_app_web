import 'dart:typed_data';
import 'package:ard_app/data/local_database/tables.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/local_database/database.dart';
import '../utils/currency_formatter.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice({
    required OrderEntity order,
    required CustomerEntity customer,
    required List<OrderItemEntity> items,
    required List<ProductEntity> products, // Needed for product names
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ئارد - Ard B2B Wholesale', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Flour Distribution & Inventory'),
                    pw.Text('Contact: +964 XXX XXXX'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice #: ${order.id.substring(0, 8).toUpperCase()}'),
                    pw.Text('Date: ${dateFormat.format(order.orderDate)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // Customer Info
            pw.Text('Billed To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.Text(customer.businessName, style: pw.TextStyle(fontSize: 14)),
            if (customer.address != null && customer.address!.isNotEmpty)
              pw.Text(customer.address!),
            pw.Text('Current Debt Balance: ${CurrencyFormatter.format(customer.debtBalance)}'),
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
                      pw.Text('Total Amount: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
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
      headers: ['Item', 'Quantity', 'Unit Price', 'Total'],
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
            syncStatus: SyncStatus.synced,
            lastUpdated: DateTime.now(), 
            isDeleted: false
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
