import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/business_provider.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String? _businessId;

  CloudStorageService(this._businessId);

  /// Uploads an image to Firebase Storage and returns the public download URL.
  Future<String?> uploadImage(String imagePath, String folderName, {String? prefixId}) async {
    try {
      // Create a unique file name
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imagePath)}';
      
      final prefix = prefixId ?? (_businessId != null ? 'businesses/$_businessId' : null);
      final path = prefix != null ? '$prefix/$folderName/$fileName' : '$folderName/$fileName';
      final ref = _storage.ref().child(path);

      final ext = p.extension(imagePath).toLowerCase();
      String contentType = 'image/jpeg';
      if (ext == '.png') {
        contentType = 'image/png';
      } else if (ext == '.gif') {
        contentType = 'image/gif';
      } else if (ext == '.webp') {
        contentType = 'image/webp';
      }
      
      final metadata = SettableMetadata(contentType: contentType);

      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        // On web or Windows, use putData with the bytes of the file
        final bytes = await XFile(imagePath).readAsBytes();
        final uploadTask = await ref.putData(bytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } else {
        // On mobile/macOS, we can use putFile
        final file = File(imagePath);
        if (!await file.exists()) {
          debugPrint('Local file does not exist: $imagePath');
          throw Exception('Local file does not exist: $imagePath');
        }
        final uploadTask = await ref.putFile(file, metadata);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading image to Firebase Storage: $e');
      throw Exception('Storage Error: $e');
    }
  }
}

final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  final businessId = ref.watch(currentBusinessIdProvider);
  return CloudStorageService(businessId);
});
