import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from gallery or camera and saves it to the app's document directory.
  /// Returns the absolute path to the saved image, or null if cancelled.
  static Future<String?> pickAndSaveImage({bool fromCamera = false}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'app_images'));
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(pickedFile.path)}';
      final savedFile = File(p.join(imagesDir.path, fileName));
      
      await File(pickedFile.path).copy(savedFile.path);
      
      return savedFile.path;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}

