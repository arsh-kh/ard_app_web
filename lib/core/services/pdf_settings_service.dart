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

  static Future<PdfSettings> getSettings(String businessId) async {
    if (businessId.isEmpty) return _getDefaultSettings();
    
    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('settings')
          .doc('pdf_settings')
          .get();
          
      if (doc.exists && doc.data() != null) {
        return PdfSettings.fromMap(doc.data()!);
      }
    } catch (e) {
      // Ignored
    }
    
    return _getDefaultSettings();
  }

  static Future<void> saveSettings(PdfSettings settings, String businessId) async {
    if (businessId.isEmpty) throw Exception('No business selected');
    
    await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('pdf_settings')
        .set(settings.toMap());
  }

  static Future<bool> hasRequiredSettings(String businessId) async {
    final settings = await getSettings(businessId);
    return settings.isConfigured;
  }
  
  static PdfSettings _getDefaultSettings() {
    return PdfSettings(
      shopName: '',
      description1: 'نحن مستعدون لتوصيل أفضل أنواع الطحين والرز بأنسب الأسعار.',
      description2: 'ئێمە ئامادەین بۆ گەیاندنی باشترین جۆرەکانی ئارد و برنج بە گونجاترین نرخ.',
      phone1: '',
      phone2: '',
      phone3: '',
    );
  }
}

