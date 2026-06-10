import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image to Firebase Storage and returns the public download URL.
  Future<String?> uploadImage(String imagePath, String folderName) async {
    try {
      // Create a unique file name
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(imagePath)}';
      final ref = _storage.ref().child('$folderName/$fileName');

      if (kIsWeb) {
        // On web, we must use putData with the bytes of the file
        final bytes = await XFile(imagePath).readAsBytes();
        final uploadTask = await ref.putData(bytes);
        return await uploadTask.ref.getDownloadURL();
      } else {
        // On mobile/desktop, we can use putFile
        final file = File(imagePath);
        if (!await file.exists()) {
          debugPrint('Local file does not exist: $imagePath');
          return null;
        }
        final uploadTask = await ref.putFile(file);
        return await uploadTask.ref.getDownloadURL();
      }
    } catch (e) {
      debugPrint('Error uploading image to Firebase Storage: $e');
      return null;
    }
  }
}

final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) {
  return CloudStorageService();
});
