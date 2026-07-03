import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_settings_service.dart';
import '../routing/routes.dart';
import '../providers/locale_provider.dart';
import 'app_translations.dart';

class PdfInterceptor {
  static Future<bool> checkAndNavigate(BuildContext context) async {
    final hasSettings = await PdfSettingsService.hasRequiredSettings();
    if (!hasSettings) {
      if (context.mounted) {
        final container = ProviderScope.containerOf(context);
        final langCode = container.read(localeProvider).languageCode;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Tr.t('pdfSettingsWarning', langCode)),
            backgroundColor: Colors.orange,
          ),
        );
        await context.push(Routes.pdfSettings);
      }
      return false;
    }
    return true;
  }
}
