import 'package:flutter/services.dart';
import '../../core/utils/app_translations.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/order_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/payment_entity.dart';
import '../utils/currency_formatter.dart';

class PdfInvoiceService {
  static Future<Uint8List> generateInvoice({
    required OrderEntity order,
    required CustomerEntity customer,
    required List<OrderItemEntity> items,
    required List<ProductEntity> products, // Needed for product names
    required bool isKurdish,
    required bool isArabic,
    String? adminPhone, // optional — pulled from admin profile
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('yyyy/MM/dd');

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'),
    );

    // Load APPLogo to use as the baker placeholder if needed
    final ByteData logoData = await rootBundle.load(
      'assets/images/APPLogo.png',
    );
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final langCode = isKurdish
        ? 'ku'
        : isArabic
        ? 'ar'
        : 'en';

    // Translations
    final String shopName = Tr.t('pdfShopName', langCode);
    final String shopDesc1 = Tr.t('pdfShopDesc1', langCode);
    final String shopDesc2 = Tr.t('pdfShopDesc2', langCode);
    final String tDear = Tr.t('pdfDear', langCode);
    final String tDate = Tr.t('pdfDate', langCode);
    final String tType = Tr.t('pdfType', langCode);
    final String tUnitPrice = Tr.t('pdfUnitPrice', langCode);
    final String tQty = Tr.t('pdfQty', langCode);
    final String tTotal = Tr.t('pdfTotal', langCode);
    final String tFreeDelivery = Tr.t('pdfFreeDelivery', langCode);

    final yellowColor = PdfColor.fromHex('#FCEE98');
    final orangeColor = PdfColor.fromHex('#F5B041');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Right side: text
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        shopName,
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: orangeColor,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        shopDesc1,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        shopDesc2,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                // Left side: image
                pw.Container(
                  width: 110,
                  height: 110,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Customer & Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      tDear,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      customer.businessName,
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text(
                      tDate,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      dateFormat.format(order.orderDate),
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Yellow Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: {
                0: const pw.FlexColumnWidth(3), // Type
                1: const pw.FlexColumnWidth(2), // Unit Price
                2: const pw.FlexColumnWidth(1.5), // Qty
                3: const pw.FlexColumnWidth(2), // Total
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: orangeColor),
                  children: [
                    _buildCell(tType, isHeader: true),
                    _buildCell(tUnitPrice, isHeader: true),
                    _buildCell(tQty, isHeader: true),
                    _buildCell(tTotal, isHeader: true),
                  ],
                ),
                // Data Rows
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final product = products.firstWhere(
                    (p) => p.id == item.productId,
                    orElse: () => const ProductEntity(
                      id: '',
                      name: 'Unknown',
                      stockQuantity: 0,
                      buyPrice: 0,
                      sellPrice: 0,
                      categoryId: 'none',
                      unitType: 'none',
                    ),
                  );

                  final totalItemCost = item.quantity * item.unitPrice;
                  final isEven = index % 2 == 0;
                  final rowColor = isEven ? yellowColor : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _buildCell(product.name),
                      _buildCell(CurrencyFormatter.format(item.unitPrice)),
                      _buildCell(item.quantity.toStringAsFixed(0)),
                      _buildCell(CurrencyFormatter.format(totalItemCost)),
                    ],
                  );
                }),

                // Add empty rows to match the style of the picture
                ...List.generate(
                  (10 - items.length > 0) ? 10 - items.length : 0,
                  (index) {
                    final isEven = (items.length + index) % 2 == 0;
                    final rowColor = isEven ? yellowColor : PdfColors.white;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: rowColor),
                      children: [
                        _buildCell(' '),
                        _buildCell(' '),
                        _buildCell(' '),
                        _buildCell(' '),
                      ],
                    );
                  },
                ),
              ],
            ),

            // If total has a discount, show the final total below
            if (order.discount > 0) ...[
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total After Discount: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(CurrencyFormatter.format(order.totalAmount)),
                ],
              ),
            ],

            pw.SizedBox(height: 24),

            // Footer
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Right: Phones
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      '0776 481 3985',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'ر.م: ',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        pw.Text(
                          '0770 156 9971',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Left: Free delivery
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      tFreeDelivery,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // Draw a simple truck shape using basic widgets
                    pw.Container(
                      width: 50,
                      height: 35,
                      decoration: pw.BoxDecoration(
                        color: orangeColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'TRUCK',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 14 : 14,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<Uint8List> generatePaymentReceipt({
    required PaymentEntity payment,
    required CustomerEntity customer,
    required bool isKurdish,
    required bool isArabic,
    String? adminPhone,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'),
    );

    final primaryColor = PdfColor.fromHex('#15803d'); // Green 700

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: [fontRegular, fontBold],
        ),
        textDirection: pw.TextDirection.rtl,
        build: (context) {
          final langCode = isKurdish
              ? 'ku'
              : isArabic
              ? 'ar'
              : 'en';

          final tReceipt = isKurdish
              ? 'پسوڵەی پاره‌دان'
              : isArabic
              ? 'وصل استلام'
              : 'Payment Receipt';
          final tReceiptId = isKurdish
              ? 'ژمارە'
              : isArabic
              ? 'رقم الوصل'
              : 'Receipt No';
          final tDate = Tr.t('auto_Date', langCode);
          final tCompany = Tr.t('auto_ArdWholesale', langCode);
          final tContact = Tr.t('auto_Contact', langCode);
          final tReceivedFrom = isKurdish
              ? 'وەرگیراوە لە'
              : isArabic
              ? 'استلمت من'
              : 'Received From';
          final tAmountPaid = isKurdish
              ? 'بڕی پاره‌دان'
              : isArabic
              ? 'المبلغ المدفوع'
              : 'Amount Paid';
          final tDebt = Tr.t('auto_CurrentDebtBala', langCode);
          final tThanks = Tr.t('auto_Thankyouforyour', langCode);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Premium Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(12),
                  ),
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
                            tReceipt,
                            style: pw.TextStyle(
                              fontSize: 28,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                '$tReceiptId: ',
                                style: const pw.TextStyle(
                                  color: PdfColors.grey300,
                                  fontSize: 12,
                                ),
                              ),
                              pw.Text(
                                payment.id.substring(0, 8).toUpperCase(),
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                '$tDate: ',
                                style: const pw.TextStyle(
                                  color: PdfColors.grey300,
                                  fontSize: 12,
                                ),
                              ),
                              pw.Text(
                                dateFormat.format(payment.paymentDate),
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 12,
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
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Directionality(
                          textDirection: pw.TextDirection.ltr,
                          child: pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                '$tContact: ',
                                style: const pw.TextStyle(
                                  color: PdfColors.grey300,
                                  fontSize: 12,
                                ),
                              ),
                              pw.Text(
                                adminPhone?.isNotEmpty == true
                                    ? adminPhone!
                                    : '—',
                                style: const pw.TextStyle(
                                  color: PdfColors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // Customer Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Directionality(
                      textDirection: (isKurdish || isArabic)
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                      child: pw.Text(
                        tReceivedFrom,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 14,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Directionality(
                      textDirection: (isKurdish || isArabic)
                          ? pw.TextDirection.rtl
                          : pw.TextDirection.ltr,
                      child: pw.Text(
                        customer.businessName,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    if (customer.address != null &&
                        customer.address!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Directionality(
                        textDirection: (isKurdish || isArabic)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        child: pw.Text(
                          customer.address!,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (isKurdish || isArabic) ...[
                            pw.Text(
                              CurrencyFormatter.format(customer.debtBalance),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: customer.debtBalance > 0
                                    ? PdfColors.red700
                                    : PdfColors.green700,
                              ),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Directionality(
                              textDirection: pw.TextDirection.rtl,
                              child: pw.Text(
                                '$tDebt:',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else ...[
                            pw.Text(
                              '$tDebt: ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(customer.debtBalance),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: customer.debtBalance > 0
                                    ? PdfColors.red700
                                    : PdfColors.green700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 32),

              // Total Box
              pw.Row(
                mainAxisAlignment: (isKurdish || isArabic)
                    ? pw.MainAxisAlignment.start
                    : pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(12),
                      ),
                    ),
                    child: pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          if (isKurdish || isArabic) ...[
                            pw.Text(
                              CurrencyFormatter.format(payment.amount),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 20,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.SizedBox(width: 12),
                            pw.Directionality(
                              textDirection: pw.TextDirection.rtl,
                              child: pw.Text(
                                tAmountPaid,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 18,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ] else ...[
                            pw.Text(
                              '$tAmountPaid ',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              CurrencyFormatter.format(payment.amount),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 20,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 48),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tThanks,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
