import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_settings_service.dart';
import '../routing/routes.dart';
import '../providers/locale_provider.dart';
import '../providers/business_provider.dart';
import 'app_translations.dart';

class PdfInterceptor {
  static Future<bool> checkAndNavigate(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final businessId = container.read(currentBusinessIdProvider) ?? '';
    
    final hasSettings = await PdfSettingsService.hasRequiredSettings(businessId);
    
    if (!hasSettings) {
      if (context.mounted) {
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
