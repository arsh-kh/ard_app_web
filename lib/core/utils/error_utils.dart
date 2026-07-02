import 'package:firebase_core/firebase_core.dart';
import '../error/app_exception.dart';
import 'app_translations.dart';

class ErrorUtils {
  /// Translates an error object into a localized string.
  static String translate(Object error, String langCode) {
    if (error is AppException) {
      // If it's our custom AppException, the message is typically a translation key
      return Tr.t(error.message, langCode);
    }
    
    if (error is FirebaseException) {
      // Convert standard FirebaseException to AppException and translate
      final appEx = AppException.fromFirebase(error);
      return Tr.t(appEx.message, langCode);
    }
    
    // For normal Exception or String
    final String raw = error.toString().replaceAll('Exception: ', '');
    
    // Check if the raw string is a known translation key or contains it
    final knownErrors = [
      'businessNameTaken', 'userNotAuthenticated', 'invalidInviteCode', 
      'businessNameEmpty', 'noEmailFound', 'noBusinessAttached',
      'invalidCredentials', 'unauthorizedEmail', 'businessNotFound',
      'outOfStockStr', 'noItemsSelected', 'couldNotDialPhone', 'noPhoneAvailable'
    ];
    
    for (final key in knownErrors) {
      if (raw.contains(key)) {
        return Tr.t(key, langCode);
      }
    }
    
    // Fallback: Check if it's already a key we can translate natively
    final translated = Tr.t(raw, langCode);
    if (translated != raw) {
      return translated;
    }
    
    final prefix = Tr.t('errorPrefix', langCode);
    if (!raw.startsWith(prefix)) {
        return '$prefix$raw';
    }
    return raw;
  }
}
