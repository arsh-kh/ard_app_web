import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory PdfSettings.fromMap(Map<String, dynamic> map) {
    return PdfSettings(
      shopName: map['shopName'] ?? '',
      description1: map['description1'] ?? 'نحن مستعدون لتوصيل أفضل أنواع الطحين والرز بأنسب الأسعار.',
      description2: map['description2'] ?? 'ئێمە ئامادەین بۆ گەیاندنی باشترین جۆرەکانی ئارد و برنج بە گونجاترین نرخ.',
      phone1: map['phone1'] ?? '',
      phone2: map['phone2'] ?? '',
      phone3: map['phone3'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'description1': description1,
      'description2': description2,
      'phone1': phone1,
      'phone2': phone2,
      'phone3': phone3,
    };
  }
}

class PdfSettingsService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collection = 'settings';
  static const _document = 'pdf_settings';

  static Future<PdfSettings> getSettings() async {
    try {
      final doc = await _firestore.collection(_collection).doc(_document).get();
      if (doc.exists && doc.data() != null) {
        return PdfSettings.fromMap(doc.data()!);
      }
    } catch (e) {
      // Ignored
    }
    
    // Return default empty settings if none exist
    return PdfSettings(
      shopName: '',
      description1: 'نحن مستعدون لتوصيل أفضل أنواع الطحين والرز بأنسب الأسعار.',
      description2: 'ئێمە ئامادەین بۆ گەیاندنی باشترین جۆرەکانی ئارد و برنج بە گونجاترین نرخ.',
      phone1: '',
      phone2: '',
      phone3: '',
    );
  }

  static Future<void> saveSettings(PdfSettings settings) async {
    await _firestore.collection(_collection).doc(_document).set(settings.toMap());
  }

  static Future<bool> hasRequiredSettings() async {
    final settings = await getSettings();
    return settings.isConfigured;
  }
}

