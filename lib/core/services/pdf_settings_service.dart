import 'package:shared_preferences/shared_preferences.dart';

class PdfSettings {
  final String shopName;
  final String description1;
  final String description2;
  final String phone1;
  final String phone2;
  final String phone3;

  PdfSettings({
    required this.shopName,
    required this.description1,
    required this.description2,
    required this.phone1,
    required this.phone2,
    required this.phone3,
  });

  bool get isConfigured => shopName.isNotEmpty && phone1.isNotEmpty;
}

class PdfSettingsService {
  static const _keyShopName = 'pdf_shop_name';
  static const _keyDesc1 = 'pdf_desc_1';
  static const _keyDesc2 = 'pdf_desc_2';
  static const _keyPhone1 = 'pdf_phone_1';
  static const _keyPhone2 = 'pdf_phone_2';
  static const _keyPhone3 = 'pdf_phone_3';

  static Future<PdfSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PdfSettings(
      shopName: prefs.getString(_keyShopName) ?? '',
      description1: prefs.getString(_keyDesc1) ?? 'نحن مستعدون لتوصيل أفضل أنواع الطحين والرز بأنسب الأسعار.',
      description2: prefs.getString(_keyDesc2) ?? 'ئێمە ئامادەین بۆ گەیاندنی باشترین جۆرەکانی ئارد و برنج بە گونجاترین نرخ.',
      phone1: prefs.getString(_keyPhone1) ?? '',
      phone2: prefs.getString(_keyPhone2) ?? '',
      phone3: prefs.getString(_keyPhone3) ?? '',
    );
  }

  static Future<void> saveSettings(PdfSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyShopName, settings.shopName.trim());
    await prefs.setString(_keyDesc1, settings.description1.trim());
    await prefs.setString(_keyDesc2, settings.description2.trim());
    await prefs.setString(_keyPhone1, settings.phone1.trim());
    await prefs.setString(_keyPhone2, settings.phone2.trim());
    await prefs.setString(_keyPhone3, settings.phone3.trim());
  }

  static Future<bool> hasRequiredSettings() async {
    final settings = await getSettings();
    return settings.isConfigured;
  }
}
