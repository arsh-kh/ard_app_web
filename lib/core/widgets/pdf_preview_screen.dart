import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final Uint8List pdfBytes;

  const PdfPreviewScreen({
    super.key, 
    required this.title, 
    required this.pdfBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (format) => pdfBytes,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.a4,
        // Extremely critical: We must use strict ASCII characters for the filename.
        // Android/iOS file systems often crash when the printing package tries to save
        // a file containing Arabic/Kurdish characters like 'ڕاپۆرتی مانگانە.pdf'.
        pdfFileName: 'ard_document_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
  }
}
