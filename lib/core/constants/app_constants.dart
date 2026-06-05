/// Application-wide constants for the ئارد flour distribution app.
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'ARD BAZAR';
  static const String appNameEn = 'ARD BAZAR';
  static const String appVersion = '1.0.0';

  // Currency
  static const String currencySymbol = 'IQD';
  static const String currencyCode = 'IQD';
  static const String currencyName = 'Iraqi Dinar';
  static const int currencyDecimalPlaces = 0; // IQD has no decimal subdivision

  // Sync
  static const int syncIntervalSeconds = 30;
  static const int maxSyncRetries = 5;
  static const int syncBatchSize = 50;

  // Pagination
  static const int defaultPageSize = 20;

  // Stock
  static const double defaultMinStockAlert = 10.0;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayDateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Invoice
  static const String invoicePrefix = 'INV';
  static const String purchaseInvoicePrefix = 'PUR';

  // Unit Labels
  static const Map<String, String> unitLabels = {
    'kg': 'Kilogram',
    'bag': 'Bag',
    'ton': 'Ton',
  };

  // Business defaults
  static const String defaultBusinessName = 'ئارد';
  static const String defaultBusinessPhone = '';
  static const String defaultBusinessAddress = '';

  // Shared Preferences Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
  static const String keyLastSyncTime = 'last_sync_time';
  static const String keyCurrentUserId = 'current_user_id';
  static const String keyRememberMe = 'remember_me';
  static const String keyBusinessName = 'business_name';
  static const String keyBusinessPhone = 'business_phone';
  static const String keyBusinessAddress = 'business_address';
}

