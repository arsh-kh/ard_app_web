import 'package:flutter/services.dart';
import '../../core/utils/app_translations.dart';
import '../../core/utils/arabic_reshaper_utils.dart';
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
    required List<ProductEntity> products,
    required bool isKurdish,
    required bool isArabic,
    required String shopName,
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

    const primaryColor = PdfColors.black;

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
          
          final tInvoice = ArabicReshaperUtils.reshape(Tr.t('auto_Invoice', langCode));
          final tInvoiceNum = ArabicReshaperUtils.reshape(Tr.t('auto_InvoiceNo', langCode));
          final tDate = ArabicReshaperUtils.reshape(Tr.t('auto_Date', langCode));
          final tDesc = ArabicReshaperUtils.reshape(Tr.t('auto_FlourDistributi', langCode));
          final tContact = ArabicReshaperUtils.reshape(Tr.t('auto_Contact', langCode));
          final tCompany = ArabicReshaperUtils.reshape(shopName);
          final tCustomer = ArabicReshaperUtils.reshape(Tr.t('auto_Customer', langCode));
          final tTotal = ArabicReshaperUtils.reshape(Tr.t('auto_TotalAmount', langCode));

          return [
            // Premium Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
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
                          tInvoice,
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
                              '$tInvoiceNum: ',
                              style: const pw.TextStyle(
                                color: PdfColors.grey300,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              order.orderNumber?.toString() ?? "...",
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
                              dateFormat.format(order.orderDate),
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
                        textDirection: (isKurdish || isArabic)
                            ? pw.TextDirection.rtl
                            : pw.TextDirection.ltr,
                        child: pw.Text(
                          tDesc,
                          style: const pw.TextStyle(
                            color: PdfColors.grey300,
                            fontSize: 12,
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
            pw.SizedBox(height: 16),
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
                      tCustomer,
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
                      ArabicReshaperUtils.reshape(customer.businessName),
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
                        ArabicReshaperUtils.reshape(customer.address!),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 32),

            // Items Table
            _buildItemsTable(
              items,
              products,
              isKurdish: isKurdish,
              isArabic: isArabic,
              primaryColor: primaryColor,
            ),

            pw.SizedBox(height: 24),

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
                  decoration: const pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.all(
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
                            CurrencyFormatter.format(order.totalAmount),
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
                              tTotal,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 18,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ] else ...[
                          pw.Text(
                            '$tTotal ',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 18,
                              color: PdfColors.white,
                            ),
                          ),
                          pw.Text(
                            CurrencyFormatter.format(order.totalAmount),
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
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildItemsTable(
    List<OrderItemEntity> items,
    List<ProductEntity> products, {
    required bool isKurdish,
    required bool isArabic,
    required PdfColor primaryColor,
  }) {
    final langCode = isKurdish
        ? 'ku'
        : isArabic
        ? 'ar'
        : 'en';
    final tItem = ArabicReshaperUtils.reshape(Tr.t('auto_Item', langCode));
    final tQty = ArabicReshaperUtils.reshape(Tr.t('auto_Qty', langCode));
    final tPrice = ArabicReshaperUtils.reshape(Tr.t('auto_UnitPrice', langCode));
    final tTotal = ArabicReshaperUtils.reshape(Tr.t('auto_Total', langCode));

    final activeItems = items;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tItem,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tQty,
                  textAlign: (isKurdish || isArabic)
                      ? pw.TextAlign.left
                      : pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tPrice,
                  textAlign: (isKurdish || isArabic)
                      ? pw.TextAlign.left
                      : pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Directionality(
                textDirection: (isKurdish || isArabic)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                child: pw.Text(
                  tTotal,
                  textAlign: (isKurdish || isArabic)
                      ? pw.TextAlign.left
                      : pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        ...List.generate(activeItems.length, (index) {
          final item = activeItems[index];
          final product = products.firstWhere(
            (p) => p.id == item.productId,
            orElse: () => ProductEntity(
              id: 'unknown',
              name: Tr.t('unknownProduct', langCode),
              categoryId: '',
              buyPrice: 0,
              sellPrice: 0,
              stockQuantity: 0,
              unitType: '',
            ),
          );
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey200 : PdfColors.white,
            ),
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Directionality(
                  textDirection: (isKurdish || isArabic)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  child: pw.Text(ArabicReshaperUtils.reshape(product.name)),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    item.quantity.toString(),
                    textAlign: (isKurdish || isArabic)
                        ? pw.TextAlign.left
                        : pw.TextAlign.right,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    CurrencyFormatter.format(item.unitPrice),
                    textAlign: (isKurdish || isArabic)
                        ? pw.TextAlign.left
                        : pw.TextAlign.right,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    CurrencyFormatter.format(item.quantity * item.unitPrice),
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

    const primaryColor = PdfColors.black; 

    pdf.addPage(
      pw.Page(
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

          final tReceipt = ArabicReshaperUtils.reshape(isKurdish
              ? 'پسوڵەی پاره‌دان'
              : isArabic
              ? 'وصل استلام'
              : 'Payment Receipt');
          final tReceiptId = ArabicReshaperUtils.reshape(isKurdish
              ? 'ژمارە'
              : isArabic
              ? 'رقم الوصل'
              : 'Receipt No');
          final tDate = ArabicReshaperUtils.reshape(Tr.t('auto_Date', langCode));
          final tCompany = ArabicReshaperUtils.reshape(Tr.t('auto_ArdWholesale', langCode));
          final tContact = ArabicReshaperUtils.reshape(Tr.t('auto_Contact', langCode));
          final tReceivedFrom = ArabicReshaperUtils.reshape(isKurdish
              ? 'وەرگیراوە لە'
              : isArabic
              ? 'استلمت من'
              : 'Received From');
          final tAmountPaid = ArabicReshaperUtils.reshape(isKurdish
              ? 'بڕی پاره‌دان'
              : isArabic
              ? 'المبلغ المدفوع'
              : 'Amount Paid');
          final tDebt = ArabicReshaperUtils.reshape(Tr.t('auto_CurrentDebtBala', langCode));
          final tThanks = ArabicReshaperUtils.reshape(Tr.t('auto_Thankyouforyour', langCode));

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Premium Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.all(
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
                        ArabicReshaperUtils.reshape(customer.businessName),
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
                          ArabicReshaperUtils.reshape(customer.address!),
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
                                color: primaryColor,
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
                                color: primaryColor,
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
                    decoration: const pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.all(
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
