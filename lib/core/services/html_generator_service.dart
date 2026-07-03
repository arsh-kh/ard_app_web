import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../../data/models/order_entity.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/order_item_entity.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/payment_entity.dart';
import '../../data/models/purchase_entity.dart';
import '../../data/models/purchase_item_entity.dart';
import '../utils/currency_formatter.dart';
import '../utils/app_translations.dart';
import '../services/pdf_settings_service.dart';

class HtmlGeneratorService {
  /// Base CSS shared across all HTML documents
  static Future<String> _getBaseStyles() async {
    String fontRegularBase64 = '';
    String fontBoldBase64 = '';
    
    try {
      final ByteData regData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      fontRegularBase64 = base64Encode(regData.buffer.asUint8List());
      
      final ByteData boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      fontBoldBase64 = base64Encode(boldData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }
    
    return '''
    <style>
      @font-face {
        font-family: 'Noto Naskh Arabic';
        src: url(data:font/truetype;charset=utf-8;base64,$fontRegularBase64) format('truetype');
        font-weight: normal;
        font-style: normal;
      }
      @font-face {
        font-family: 'Noto Naskh Arabic';
        src: url(data:font/truetype;charset=utf-8;base64,$fontBoldBase64) format('truetype');
        font-weight: bold;
        font-style: normal;
      }
      
      :root {
        --primary-gold: #f1c40f;
        --gold-light: #fef9e7;
        --text-dark: #2c3e50;
        --text-muted: #7f8c8d;
        --border-color: #bdc3c7;
        --bg-light: #f8f9fa;
        --success: #27ae60;
        --danger: #c0392b;
      }

      * {
        box-sizing: border-box;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        color-adjust: exact !important;
      }

      body {
        font-family: 'Noto Naskh Arabic', sans-serif;
        margin: 0;
        padding: 20px;
        color: var(--text-dark);
        line-height: 1.6;
        font-size: 14px;
        background: #fff;
      }

      .invoice-container {
        max-width: 800px;
        margin: 0 auto;
        padding: 30px;
        border: 2px solid var(--primary-gold);
        border-radius: 12px;
        box-shadow: 0 4px 15px rgba(0,0,0,0.05);
      }

      .header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        padding: 20px;
        background: #2c3e50;
        color: white;
        border-radius: 8px;
        margin-bottom: 25px;
        border-bottom: 4px solid var(--primary-gold);
      }

      .header-title {
        font-size: 28px;
        font-weight: bold;
        margin: 0;
        color: var(--primary-gold);
      }

      .header-info p {
        margin: 4px 0;
        color: #ecf0f1;
      }

      .header-info strong {
        color: white;
      }

      .shop-info h2 {
        margin: 0 0 5px 0;
        font-size: 24px;
        color: var(--primary-gold);
      }

      .shop-info p {
        margin: 2px 0;
        color: #ecf0f1;
      }

      .customer-box {
        background: var(--bg-light);
        padding: 20px;
        border-radius: 8px;
        border-right: 5px solid var(--primary-gold);
        margin-bottom: 25px;
        box-shadow: 0 2px 5px rgba(0,0,0,0.02);
      }

      table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 0;
        margin-bottom: 25px;
        border: 1px solid var(--border-color);
        border-radius: 8px;
        overflow: hidden;
      }

      th {
        background: var(--primary-gold);
        color: #2c3e50;
        padding: 15px 12px;
        text-align: center;
        font-weight: bold;
        font-size: 15px;
      }

      td {
        padding: 12px;
        border-bottom: 1px solid #eee;
        text-align: center;
        font-weight: bold;
        font-size: 14px;
      }

      tr:last-child td {
        border-bottom: none;
      }

tr {
        page-break-inside: avoid;
      }

      .totals-container {
        display: flex;
        justify-content: flex-end;
        margin-top: 25px;
      }

      .totals-box {
        width: 350px;
        background: var(--bg-light);
        padding: 15px;
        border-radius: 8px;
        border: 1px solid #eee;
      }

      .total-row {
        display: flex;
        justify-content: space-between;
        padding: 10px 0;
        border-bottom: 1px dashed var(--border-color);
        font-size: 15px;
      }
      
      .total-row:last-child {
        border-bottom: none;
      }

      .total-row.grand-total {
        font-size: 20px;
        font-weight: bold;
        background: var(--primary-gold);
        color: #2c3e50;
        padding: 15px;
        border-radius: 6px;
        margin-top: 10px;
      }

      .footer {
        text-align: center;
        margin-top: 40px;
        padding-top: 20px;
        border-top: 2px solid #eee;
        color: var(--text-muted);
        font-weight: bold;
        page-break-inside: avoid;
      }

      @media print {
        body { padding: 0; background: white; }
        .invoice-container { 
          border: none; 
          box-shadow: none;
          padding: 0; 
          max-width: 100%;
        }
        @page { margin: 10mm; size: A4; }
      }
    </style>
    ''';
  }

  /// Premium Monochrome CSS for perfect PDFs (strictly Black & White)
  static Future<String> _getPerfectBaseStyles() async {
    String fontRegularBase64 = '';
    String fontBoldBase64 = '';
    
    try {
      final ByteData regData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf');
      fontRegularBase64 = base64Encode(regData.buffer.asUint8List());
      
      final ByteData boldData = await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf');
      fontBoldBase64 = base64Encode(boldData.buffer.asUint8List());
    } catch (e) {
      // Ignore
    }
    
    return '''
    <style>
      @font-face {
        font-family: 'Noto Naskh Arabic';
        src: url(data:font/truetype;charset=utf-8;base64,$fontRegularBase64) format('truetype');
        font-weight: normal;
        font-style: normal;
      }
      @font-face {
        font-family: 'Noto Naskh Arabic';
        src: url(data:font/truetype;charset=utf-8;base64,$fontBoldBase64) format('truetype');
        font-weight: bold;
        font-style: normal;
      }
      
      :root {
        --primary-black: #000000;
        --bg-light: #F9FAFB;
        --text-dark: #000000;
        --text-muted: #4B5563;
        --border-color: #000000;
      }

      * {
        box-sizing: border-box;
        -webkit-print-color-adjust: exact !important;
        print-color-adjust: exact !important;
        color-adjust: exact !important;
      }

      body {
        font-family: 'Noto Naskh Arabic', sans-serif;
        margin: 0;
        padding: 40px;
        color: var(--text-dark);
        line-height: 1.6;
        font-size: 14px;
        background: #fff;
      }

      .invoice-container {
        max-width: 800px;
        margin: 0 auto;
        padding: 0;
      }

      .header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 40px;
        border-bottom: 2px solid var(--primary-black);
        padding-bottom: 20px;
      }

      .header-title {
        font-size: 32px;
        font-weight: bold;
        margin: 0 0 10px 0;
        color: var(--primary-black);
        text-transform: uppercase;
        letter-spacing: 1px;
      }

      .header-info p {
        margin: 4px 0;
        color: var(--text-muted);
        font-size: 13px;
      }

      .header-info strong {
        color: var(--text-dark);
      }

      .shop-info {
        text-align: right;
      }

      .shop-info h2 {
        margin: 0 0 8px 0;
        font-size: 24px;
        color: var(--primary-black);
        font-weight: bold;
      }

      .shop-info p {
        margin: 3px 0;
        color: var(--text-muted);
        font-size: 13px;
      }

      .customer-box {
        margin-bottom: 30px;
      }

      table {
        width: 100%;
        border-collapse: collapse;
        margin-bottom: 30px;
        border: 2px solid var(--primary-black);
      }

      th {
        background: var(--primary-black);
        color: #ffffff;
        padding: 12px 15px;
        text-align: center;
        font-weight: bold;
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.5px;
        border: 1px solid var(--primary-black);
      }
      
      th[dir="rtl"] {
        text-align: center;
      }

      td {
        padding: 12px 15px;
        border: 1px solid var(--primary-black);
        color: var(--text-dark);
        font-size: 14px;
        text-align: center;
      }

      tr {
        page-break-inside: avoid;
      }

      .totals-container {
        display: flex;
        justify-content: flex-end;
        margin-top: 20px;
      }

      .totals-box {
        width: 350px;
      }

      .total-row {
        display: flex;
        justify-content: space-between;
        padding: 12px 15px;
        border-bottom: 1px solid var(--border-color);
        font-size: 15px;
      }
      
      .total-row:last-child {
        border-bottom: none;
      }

      .total-row.grand-total {
        font-size: 18px;
        font-weight: bold;
        background: var(--primary-black);
        color: #ffffff;
        margin-top: 10px;
        border-bottom: none;
        border-radius: 4px;
      }

      .footer {
        text-align: center;
        margin-top: 50px;
        padding-top: 20px;
        border-top: 1px solid var(--border-color);
        color: var(--text-muted);
        font-size: 12px;
        page-break-inside: avoid;
      }

      @media print {
        body { padding: 0; }
        .invoice-container { max-width: 100%; }
        @page { margin: 15mm; size: A4; }
      }
    </style>
    ''';
  }

  /// Generates and launches an HTML Invoice (Order Invoice) - The "Old Yellow" Design upgraded
  static Future<void> generateAndLaunchInvoice({
    required OrderEntity order,
    required CustomerEntity customer,
    required List<OrderItemEntity> items,
    required List<ProductEntity> products,
    required bool isKurdish,
    required bool isArabic,
    required String shopName,
    String? adminPhone,
  }) async {
    final pdfSettings = await PdfSettingsService.getSettings();
    final bool isRtl = isKurdish || isArabic;
    final String textDir = isRtl ? 'rtl' : 'ltr';
    String tr(String en, String arKu) {
      if (!isRtl) return en;
      return arKu;
    }

    final dateFormat = DateFormat('yyyy/MM/dd');
    final baseStyles = await _getBaseStyles();

    String bakerImageSrc = '';
    try {
      final ByteData imageData = await rootBundle.load('assets/images/baker.png');
      final String base64Image = base64Encode(imageData.buffer.asUint8List());
      bakerImageSrc = 'data:image/png;base64,$base64Image';
    } catch (e) {
      // Ignored
    }

    String itemsHtml = '';
    for (var item in items) {
      final product = products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductEntity(
          id: '', name: 'Unknown', categoryId: '',
          buyPrice: 0, sellPrice: 0, stockQuantity: 0, unitType: '',
        ),
      );
      itemsHtml += '''
        <tr>
          <td dir="auto" style="text-align: center; word-break: break-word;">${product.name}</td>
          <td dir="ltr">${CurrencyFormatter.formatNumber(item.unitPrice, forPrint: true)}</td>
          <td dir="ltr">${item.quantity}</td>
          <td dir="ltr">${CurrencyFormatter.formatNumber(item.unitPrice * item.quantity, forPrint: true)}</td>
        </tr>
      ''';
    }

    // Totals block sitting neatly on the bottom left (using colspan 2 for empty space)
    itemsHtml += '''
      <tr class="totals-row">
        <td colspan="3" style="background-color: var(--primary-gold) !important; border-left: 1px solid #2c3e50 !important; font-weight: bold; color: #2c3e50; font-size: 15pt; white-space: nowrap; text-align: right; padding-right: 15px;">${tr("Total Amount", "${tr("Total Amount", "المجموع الكلي / کۆی گشتی")}")}</td>
        <td dir="ltr" style="font-weight: bold; color: #2c3e50; font-size: 15pt;">${CurrencyFormatter.formatNumber(order.totalAmount, forPrint: true)}</td>
      </tr>
    ''';

    // Discount rows have been explicitly removed per user request

    if (customer.debtBalance > 0) {
      itemsHtml += '''
        <tr>
          <td colspan="3" style="background-color: #fff !important; border-left: 1px solid #2c3e50 !important; font-weight: bold; color: #2c3e50; font-size: 15pt; white-space: nowrap; text-align: right; padding-right: 15px;">${tr("Previous Debt", "الديون السابقة / قەرزی پێشوو")}</td>
          <td dir="ltr" style="font-weight: bold; color: #2c3e50; font-size: 15pt;">${CurrencyFormatter.formatNumber(customer.debtBalance - order.totalAmount + order.discount, forPrint: true)}</td>
        </tr>
        <tr>
          <td colspan="3" style="background-color: #fff !important; border-left: 1px solid #2c3e50 !important; font-weight: bold; color: #2c3e50; font-size: 15pt; white-space: nowrap; text-align: right; padding-right: 15px;">${tr("Total Debt", "إجمالي الديون / کۆی قەرزەکان")}</td>
          <td dir="ltr" style="font-weight: bold; color: var(--danger); font-size: 15pt;">${CurrencyFormatter.formatNumber(customer.debtBalance, forPrint: true)}</td>
        </tr>
      ''';
    }

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="${isRtl ? 'ar' : 'en'}" dir="$textDir">
    <head>
      <meta charset="UTF-8">
      <title>Invoice - ${order.orderNumber}</title>
      $baseStyles
      <style>
        @page {
          size: A4;
          margin: 5mm;
        }
        body {
          margin: 0;
          padding: 0;
          background: #fff;
        }
        .old-invoice-container {
          width: 100%;
          max-width: 200mm;
          margin: 0 auto;
          padding: 5mm;
          /* border: 2px solid #2c3e50; removed per user request */
          border-radius: 8px;
          display: flex;
          flex-direction: column;
          height: 98vh;
          box-sizing: border-box;
          overflow: hidden;
        }
        
        .old-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 25px;
          border-bottom: 3px solid var(--primary-gold);
          padding-bottom: 15px;
          gap: 30px;
        }
        
        .old-header-text {
          flex: 1;
          text-align: right;
        }
        
        .old-shop-name {
          color: var(--primary-gold);
          font-size: 40pt;
          font-weight: bold;
          margin: 0 0 10px 0;
          text-shadow: 1px 1px 1px rgba(0,0,0,0.1);
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        
        .old-shop-desc {
          font-size: 15pt;
          margin: 0 0 8px 0;
          font-weight: bold;
          color: #2c3e50;
          line-height: 1.4;
        }
        
        .old-header-logo {
          width: 240px;
          height: 240px;
          display: flex;
          align-items: center;
          justify-content: center;
          margin-left: 0px;
          flex-shrink: 0;
        }
        
        .meta-info-container {
          display: flex; 
          justify-content: space-between; 
          margin-bottom: 20px; 
          align-items: flex-end;
        }
        
        .meta-box {
          display: flex; 
          width: 48%; 
          align-items: flex-end;
        }
        
        .meta-label {
          font-size: 15pt; 
          font-weight: bold; 
          margin-left: 10px; 
          color: #2c3e50; 
          white-space: nowrap;
        }
        
        .meta-value {
          flex-grow: 1; 
          border-bottom: 2px dashed #2c3e50; 
          text-align: center; 
          font-size: 18pt; 
          font-weight: bold; 
          color: #c0392b; 
          padding-bottom: 2px;
        }
        
        .meta-date {
          color: #2c3e50;
          font-size: 17pt;
        }                                                                                        .old-table {
          width: 100%;
          border-collapse: separate;
          border-spacing: 0;
          margin-bottom: auto;
          box-sizing: border-box;
          border: 2px solid #2c3e50;
          border-radius: 8px;
          overflow: hidden;
        }
        
        .old-table th {
          background-color: var(--primary-gold) !important;
          color: #2c3e50;
          font-size: 15pt;
          padding: 12px 10px;
          border-bottom: 2px solid #2c3e50 !important;
          border-top: none !important;
        }
        
        .old-table td {
          font-size: 14pt;
          padding: 10px 8px;
          border-bottom: 1px solid #e0e0e0 !important;
          border-top: none !important;
          background-color: #ffffff !important;
        }
        
        /* Remove bottom border from last row before totals */
        .old-table tbody tr:last-child td {
          border-bottom: none !important;
        }
        
        /* Inner vertical lines - soft gray */
        .old-table th:not(:last-child), .old-table td:not(:last-child) {
          border-left: 1px solid #e0e0e0 !important;
        }
        
        /* Totals block styling */
        .old-table .totals-row td {
          background-color: #f8f9fa !important;
          border-top: 2px solid #2c3e50 !important;
          border-bottom: 1px solid #e0e0e0 !important;
          font-weight: bold;
        }
        .old-table .final-totals-row td {
          background-color: #f8f9fa !important;
          border-bottom: none !important;
          font-weight: bold;
        }
        .old-footer {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-top: 20px;
          padding-top: 15px;
          border-top: 2px solid var(--border-color);
        }
        
        @media print {
          body { padding: 0; margin: 0; box-sizing: border-box; }
          .old-invoice-container { 
            /* border: 2px solid #2c3e50; removed per user request */ 
            padding: 0; 
            margin: 0 auto;
            width: 100%;
            box-sizing: border-box;
            height: 285mm; 
            max-height: 285mm;
            overflow: hidden;
          }
        }
      </style>
      <script>window.onload = function() { window.print(); }</script>
    </head>
    <body>
      <div class="old-invoice-container">
        <div class="old-header">
          <div class="old-header-text">
            <h1 class="old-shop-name">${pdfSettings.shopName.isNotEmpty ? pdfSettings.shopName : shopName}</h1>
            <p class="old-shop-desc"><b>${pdfSettings.description1.isNotEmpty ? pdfSettings.description1 : tr("We are ready to deliver the best types of flour and rice at the most reasonable prices.", "نحن مستعدون لتوصيل أفضل أنواع الطحين والرز بأنسب الأسعار.")}</b></p>
            ${pdfSettings.description2.isNotEmpty ? '<p class="old-shop-desc"><b>${pdfSettings.description2}</b></p>' : (isRtl ? '<p class="old-shop-desc"><b>ئێمە ئامادەین بۆ گەیاندنی باشترین جۆرەکانی ئارد و برنج بە گونجاترین نرخ.</b></p>' : '')}
          </div>
          <div class="old-header-logo">
            <img src="${bakerImageSrc}" alt="Logo" style="max-width: 100%; max-height: 100%;" />
          </div>
        </div>

        <div class="meta-info-container">
          <!-- Name Section -->
          <div class="meta-box">
            <span class="meta-label">${tr("Customer Name:", "السيد / بەڕێز:")}</span>
            <span class="meta-value">${customer.businessName}</span>
          </div>
          <!-- Date Section -->
          <div class="meta-box">
            <span class="meta-label">${tr("Date:", "${tr("Date", "${tr("Date", "التاريخ / بەروار")}")}:")}</span>
            <span class="meta-value meta-date" dir="ltr">${dateFormat.format(order.orderDate)}</span>
          </div>
        </div>

        <div style="padding: 0 4px; margin-bottom: auto;"><table class="old-table" border="1" bordercolor="#2c3e50">
          <thead>
            <tr>
              <th style="width: 35%;">${tr("Type", "نوع<br>جۆر")}</th>
              <th style="width: 25%;">${tr("Unit Price", "سعر كيس واحد<br>نرخی یەک فەردە")}</th>
              <th style="width: 15%;">${tr("Qty", "العدد<br>دانە")}</th>
              <th style="width: 25%;">${tr("Total", "المجموع<br>کۆی نرخ")}</th>
            </tr>
          </thead>
          <tbody>
            $itemsHtml
          </tbody>
        </table></div>

        <div class="old-footer">
          <!-- Right side in RTL (First child) - Phone Numbers -->
          <div style="display: flex; align-items: center; gap: 15px;">
            <svg width="32" height="32" viewBox="0 0 24 24" fill="#f1c40f">
              <path d="M20.01 15.38c-1.23 0-2.42-.2-3.53-.56a.977.977 0 00-1.01.24l-1.57 1.97c-2.83-1.35-5.48-3.9-6.89-6.83l1.95-1.66c.27-.28.35-.67.24-1.02-.37-1.11-.56-2.3-.56-3.53 0-.54-.45-.99-.99-.99H4.19C3.65 3 3 3.24 3 3.99 3 13.28 10.73 21 20.03 21c.76 0 .98-.66.98-1.21v-3.42c0-.54-.45-.99-.99-.99z"/>
            </svg>
            <div style="display: flex; flex-direction: column; direction: ltr; font-size: 16pt; font-weight: bold; color: #2c3e50;">
              ${pdfSettings.phone1.isNotEmpty ? '<span>${pdfSettings.phone1}</span>' : (adminPhone?.isNotEmpty == true ? '<span>$adminPhone</span>' : '<span>0776 481 3985</span>')}
              ${pdfSettings.phone2.isNotEmpty ? '<span>${pdfSettings.phone2}</span>' : ''}
              ${pdfSettings.phone3.isNotEmpty ? '<span>${pdfSettings.phone3}</span>' : ''}
            </div>
          </div>
          <!-- Left side in RTL (Second child) - Delivery Badge -->
          <div style="display: flex; align-items: center; gap: 10px;">
            <span style="font-size: 19pt; font-weight: bold; color: black;">${tr("Free Delivery", "توصيل مجاني")}</span>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="#f1c40f">
              <path d="M20 8h-3V4H3c-1.1 0-2 .9-2 2v11h2c0 1.66 1.34 3 3 3s3-1.34 3-3h6c0 1.66 1.34 3 3 3s3-1.34 3-3h2v-5l-3-4zM6 18.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zm13.5-9l1.96 2.5H17V9.5h2.5zm-1.5 9c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/>
            </svg>
          </div>
        </div>
      </div>
    </body>
    </html>
    ''';

    await _saveAndLaunchHtml(htmlContent, 'invoice_${order.orderNumber ?? order.id}.html');
  }

  static Future<void> generateAndLaunchPaymentReceipt({
    required PaymentEntity payment,
    required CustomerEntity customer,
    required bool isKurdish,
    required bool isArabic,
    String? adminPhone,
  }) async {
    final pdfSettings = await PdfSettingsService.getSettings();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final langCode = isKurdish ? 'ku' : isArabic ? 'ar' : 'en';
    final baseStyles = await _getPerfectBaseStyles();

    final tReceipt = isKurdish ? 'پسوڵەی پاره‌دان' : isArabic ? 'وصل استلام' : 'Payment Receipt';
    final tReceiptId = isKurdish ? 'ژمارە' : isArabic ? 'رقم الوصل' : 'Receipt No';
    final tDate = Tr.t('auto_Date', langCode);
    final tCompany = Tr.t('auto_ArdWholesale', langCode);
    final tContact = Tr.t('auto_Contact', langCode);
    final tReceivedFrom = isKurdish ? 'وەرگیراوە لە' : isArabic ? 'استلمت من' : 'Received From';
    final tAmountPaid = isKurdish ? 'بڕی پاره‌دان' : isArabic ? 'المبلغ المدفوع' : 'Amount Paid';
    final tDebt = Tr.t('auto_CurrentDebtBala', langCode);
    final tThanks = Tr.t('auto_Thankyouforyour', langCode);

    final isRtl = isKurdish || isArabic;
    final dir = isRtl ? 'rtl' : 'ltr';

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="$langCode" dir="$dir">
    <head>
      <meta charset="UTF-8">
      <title>$tReceipt - ${payment.id.substring(0, 8)}</title>
      $baseStyles
      <script>window.onload = function() { window.print(); }</script>
    </head>
    <body>
      <div class="invoice-container">
        <div class="header">
          <div class="header-info">
            <h1 class="header-title">$tReceipt</h1>
            <p>$tReceiptId: <strong>${payment.id.substring(0, 8)}</strong></p>
            <p>$tDate: <strong dir="ltr">${dateFormat.format(payment.paymentDate)}</strong></p>
          </div>
          <div class="shop-info">
            <h2 dir="auto">${pdfSettings.shopName.isNotEmpty ? pdfSettings.shopName : tCompany}</h2>
            ${pdfSettings.phone1.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone1}</strong></p>' : (adminPhone?.isNotEmpty == true ? '<p>$tContact: <strong dir="ltr">$adminPhone</strong></p>' : '<p>$tContact: <strong dir="ltr">-</strong></p>')}
            ${pdfSettings.phone2.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone2}</strong></p>' : ''}
            ${pdfSettings.phone3.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone3}</strong></p>' : ''}
          </div>
        </div>

        <div class="customer-box" style="display: flex; flex-direction: column; gap: 20px;">
          <div>
            <strong style="color: var(--text-muted); font-size: 16px;">$tReceivedFrom:</strong>
            <h3 style="margin: 5px 0 0 0; font-size: 24px; color: var(--primary-black);" dir="auto">${customer.businessName}</h3>
          </div>
          
          <div style="background: var(--bg-light); padding: 25px; border: 2px solid var(--primary-black); text-align: center;">
            <strong style="color: var(--text-muted); font-size: 18px; text-transform: uppercase; letter-spacing: 1px;">$tAmountPaid</strong>
            <h2 style="margin: 10px 0 0 0; font-size: 36px; color: var(--primary-black);" dir="ltr">
              ${CurrencyFormatter.format(payment.amount, forPrint: true)}
            </h2>
          </div>

          <div style="padding: 15px; border: 1px solid var(--border-color); display: flex; justify-content: space-between; align-items: center;">
            <strong style="color: var(--text-muted); text-transform: uppercase;">$tDebt:</strong>
            <span style="font-size: 18px; font-weight: bold; color: var(--primary-black);" dir="ltr">
              ${CurrencyFormatter.format(customer.debtBalance, forPrint: true)}
            </span>
          </div>
        </div>

        <div class="footer">
          <p style="font-size: 16px;">$tThanks</p>
        </div>
      </div>
    </body>
    </html>
    ''';

    await _saveAndLaunchHtml(htmlContent, 'receipt_${payment.id.substring(0, 8)}.html');
  }

  static Future<void> generateAndLaunchPurchaseInvoice({
    required PurchaseEntity purchase,
    required List<PurchaseItemEntity> items,
    required List<ProductEntity> products,
    required bool isKurdish,
    required bool isArabic,
    String? adminPhone,
  }) async {
    final pdfSettings = await PdfSettingsService.getSettings();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final langCode = isKurdish ? 'ku' : isArabic ? 'ar' : 'en';
    final baseStyles = await _getPerfectBaseStyles();

    final tInvoice = Tr.t('purchaseInvoice', langCode);
    final tInvoiceNum = Tr.t('purchaseNo', langCode);
    final tDate = Tr.t('auto_Date', langCode);
    final tDesc = Tr.t('auto_FlourDistributi', langCode);
    final tContact = Tr.t('auto_Contact', langCode);
    final tCompany = Tr.t('auto_ArdWholesale', langCode);
    final tTotal = Tr.t('auto_TotalAmount', langCode);

    final isRtl = isKurdish || isArabic;
    final dir = isRtl ? 'rtl' : 'ltr';

    String itemsHtml = '';
    for (var item in items) {
      final product = products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductEntity(id: '', name: 'Unknown', categoryId: '', buyPrice: 0, sellPrice: 0, stockQuantity: 0, unitType: ''),
      );
      itemsHtml += '''
        <tr>
          <td><strong dir="auto" style="font-size: 16px;">${product.name}</strong></td>
          <td dir="ltr">${item.quantity}</td>
          <td dir="ltr">${CurrencyFormatter.format(item.unitPrice, forPrint: true)}</td>
          <td dir="ltr" style="color: var(--primary-black); font-size: 16px;"><strong>${CurrencyFormatter.format(item.unitPrice * item.quantity, forPrint: true)}</strong></td>
        </tr>
      ''';
    }

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="$langCode" dir="$dir">
    <head>
      <meta charset="UTF-8">
      <title>$tInvoice - ${purchase.purchaseNumber ?? purchase.id.substring(0, 8)}</title>
      $baseStyles
      <script>window.onload = function() { window.print(); }</script>
    </head>
    <body>
      <div class="invoice-container">
        <div class="header">
          <div class="header-info">
            <h1 class="header-title">$tInvoice</h1>
            <p>$tInvoiceNum: <strong>${purchase.purchaseNumber ?? purchase.id.substring(0, 8)}</strong></p>
            <p>$tDate: <strong dir="ltr">${dateFormat.format(purchase.purchaseDate)}</strong></p>
          </div>
          <div class="shop-info">
            <h2 dir="auto">${pdfSettings.shopName.isNotEmpty ? pdfSettings.shopName : tCompany}</h2>
            <p dir="auto">${pdfSettings.description1.isNotEmpty ? pdfSettings.description1 : tDesc}</p>
            ${pdfSettings.phone1.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone1}</strong></p>' : (adminPhone?.isNotEmpty == true ? '<p>$tContact: <strong dir="ltr">$adminPhone</strong></p>' : '<p>$tContact: <strong dir="ltr">-</strong></p>')}
            ${pdfSettings.phone2.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone2}</strong></p>' : ''}
            ${pdfSettings.phone3.isNotEmpty ? '<p>$tContact: <strong dir="ltr">${pdfSettings.phone3}</strong></p>' : ''}
          </div>
        </div>

        <table>
          <thead>
            <tr>
              <th>Product</th>
              <th>Qty</th>
              <th>Cost</th>
              <th>Total Cost</th>
            </tr>
          </thead>
          <tbody>
            $itemsHtml
          </tbody>
        </table>

        <div class="totals-container">
          <div class="totals-box">
            <div class="total-row grand-total">
              <span>$tTotal:</span>
              <span dir="ltr">${CurrencyFormatter.format(purchase.totalAmount, forPrint: true)}</span>
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
    ''';

    await _saveAndLaunchHtml(htmlContent, 'purchase_${purchase.purchaseNumber ?? purchase.id}.html');
  }

  static Future<void> generateAndLaunchReport({
    required dynamic reportData,
    required String periodName,
    required bool isMonth,
    required bool isKurdish,
    required bool isArabic,
  }) async {
    final pdfSettings = await PdfSettingsService.getSettings();
    final now = DateTime.now();
    final generatedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final langCode = isKurdish ? 'ku' : isArabic ? 'ar' : 'en';
    final baseStyles = await _getPerfectBaseStyles();

    final tTitle = isMonth ? Tr.t('auto_MONTHLYREPORT', langCode) : Tr.t('auto_YEARLYREPORT', langCode);
    final tPeriod = Tr.t('auto_Period', langCode);
    final tGenerated = Tr.t('auto_Generated', langCode);
    final tSummary = Tr.t('auto_FinancialSummar', langCode);
    final tCompany = Tr.t('auto_ArdWholesale', langCode);
    final tNetProfit = Tr.t('auto_NetProfit', langCode);
    final tTotalOrders = Tr.t('auto_TotalOrdersExec', langCode);
    final tTotalRev = Tr.t('auto_TotalRevenueGro', langCode);
    final tTotalExp = Tr.t('auto_TotalPurchasesE', langCode);
    final tTotalReturns = Tr.t('totalReturns', langCode);

    final isRtl = isKurdish || isArabic;
    final dir = isRtl ? 'rtl' : 'ltr';

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="$langCode" dir="$dir">
    <head>
      <meta charset="UTF-8">
      <title>$tTitle - $periodName</title>
      $baseStyles
      <script>window.onload = function() { window.print(); }</script>
      <style>
        .summary-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 20px;
          margin-bottom: 30px;
        }
        .stat-card {
          background: #ffffff;
          padding: 25px;
          border: 2px solid var(--primary-black);
        }
        .stat-card.profit { 
          background: var(--primary-black); 
          color: white;
          padding: 30px;
        }
        .stat-card.profit .stat-title { color: #aaaaaa; }
        .stat-card.profit .stat-value { color: #ffffff; }
        
        .stat-title { color: var(--text-muted); font-size: 13px; margin-bottom: 8px; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; }
        .stat-value { font-size: 28px; font-weight: bold; margin: 0; color: var(--primary-black); }
      </style>
    </head>
    <body>
      <div class="invoice-container">
        <div class="header">
          <div class="header-info">
            <h1 class="header-title">$tTitle</h1>
            <p>$tPeriod: <strong dir="ltr">$periodName</strong></p>
            <p>$tGenerated: <strong dir="ltr">$generatedDate</strong></p>
          </div>
          <div class="shop-info">
            <h2 dir="auto">${pdfSettings.shopName.isNotEmpty ? pdfSettings.shopName : tCompany}</h2>
          </div>
        </div>

        <h3 style="border-bottom: 2px solid var(--primary-black); padding-bottom: 10px; font-size: 20px; color: var(--primary-black); text-transform: uppercase; letter-spacing: 1px;">$tSummary</h3>
        
        <div class="summary-grid">
          <div class="stat-card revenue">
            <div class="stat-title">$tTotalRev</div>
            <div class="stat-value" dir="ltr">
              ${CurrencyFormatter.format(reportData.revenue, forPrint: true)}
            </div>
          </div>
          <div class="stat-card expense">
            <div class="stat-title">$tTotalExp</div>
            <div class="stat-value" dir="ltr">
              ${CurrencyFormatter.format(reportData.cogs, forPrint: true)}
            </div>
          </div>
          <div class="stat-card returns">
            <div class="stat-title">$tTotalReturns</div>
            <div class="stat-value" dir="ltr">
              ${CurrencyFormatter.format(reportData.totalReturns, forPrint: true)}
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-title">$tTotalOrders</div>
            <div class="stat-value" dir="ltr">
              ${reportData.ordersCount}
            </div>
          </div>
        </div>

        <div class="stat-card profit" style="text-align: center; margin-bottom: 30px;">
          <div class="stat-title" style="font-size: 20px;">$tNetProfit</div>
          <div class="stat-value" dir="ltr" style="font-size: 38px; color: white;">
            ${CurrencyFormatter.format(reportData.profit, forPrint: true)}
          </div>
        </div>
      </div>
    </body>
    </html>
    ''';

    await _saveAndLaunchHtml(htmlContent, 'report_${periodName.replaceAll('/', '-')}.html');
  }

  static Future<void> generateAndLaunchLedger({
    required String title,
    required String periodName,
    required List<String> headers,
    required List<List<String>> rows,
    required String totalLabel,
    required double totalAmount,
    required bool isKurdish,
    required bool isArabic,
    required String shopName,
  }) async {
    final pdfSettings = await PdfSettingsService.getSettings();
    final now = DateTime.now();
    final generatedDate = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final langCode = isKurdish ? 'ku' : isArabic ? 'ar' : 'en';
    final baseStyles = await _getPerfectBaseStyles();

    final isRtl = isKurdish || isArabic;
    final dir = isRtl ? 'rtl' : 'ltr';

    String headersHtml = '';
    for (var header in headers) {
      headersHtml += '<th>$header</th>';
    }

    String rowsHtml = '';
    for (var row in rows) {
      rowsHtml += '<tr>';
      for (var i = 0; i < row.length; i++) {
        final cellDir = RegExp(r'^[0-9.,$€£ IQD]+$').hasMatch(row[i].trim()) ? 'ltr' : 'auto';
        rowsHtml += '<td dir="$cellDir">${row[i]}</td>';
      }
      rowsHtml += '</tr>';
    }

    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="$langCode" dir="$dir">
    <head>
      <meta charset="UTF-8">
      <title>$title - $periodName</title>
      $baseStyles
      <script>window.onload = function() { window.print(); }</script>
    </head>
    <body>
      <div class="invoice-container">
        <div class="header">
          <div class="header-info">
            <h1 class="header-title">$title</h1>
            <p>Period: <strong dir="ltr">$periodName</strong></p>
            <p>Generated: <strong dir="ltr">$generatedDate</strong></p>
          </div>
          <div class="shop-info">
            <h2 dir="auto">${pdfSettings.shopName.isNotEmpty ? pdfSettings.shopName : shopName}</h2>
          </div>
        </div>

        <table>
          <thead>
            <tr>
              $headersHtml
            </tr>
          </thead>
          <tbody>
            $rowsHtml
          </tbody>
        </table>

        <div class="totals-container">
          <div class="totals-box">
            <div class="total-row grand-total">
              <span>$totalLabel:</span>
              <span dir="ltr">${CurrencyFormatter.format(totalAmount, forPrint: true)}</span>
            </div>
          </div>
        </div>
      </div>
    </body>
    </html>
    ''';

    await _saveAndLaunchHtml(htmlContent, 'ledger_${DateTime.now().millisecondsSinceEpoch}.html');
  }

  static Future<void> _saveAndLaunchHtml(String htmlContent, String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString(htmlContent);

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open HTML receipt: ${result.message}');
    }
  }
}
