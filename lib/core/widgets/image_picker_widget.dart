import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/image_helper.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImagePath;
  final Function(String?) onImageSelected;
  final double radius;
  final IconData placeholderIcon;
  final bool isKurdish;
  final bool isArabic;

  const ImagePickerWidget({
    super.key,
    this.initialImagePath,
    required this.onImageSelected,
    this.radius = 50,
    this.placeholderIcon = Icons.add_a_photo,
    this.isKurdish = false,
    this.isArabic = false,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  String? _currentImagePath;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.initialImagePath;
  }

  Future<void> _pickImage() async {
    // Show bottom sheet to choose camera or gallery
    final source = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(widget.isKurdish ? 'کامێرا' : widget.isArabic ? 'كاميرا' : 'Camera'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(widget.isKurdish ? 'وێنەکان' : widget.isArabic ? 'معرض الصور' : 'Gallery'),
                onTap: () => Navigator.pop(context, false),
              ),
              if (_currentImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    widget.isKurdish ? 'سڕینەوەی وێنە' : widget.isArabic ? 'حذف الصورة' : 'Remove Photo',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    setState(() {
                      _currentImagePath = null;
                    });
                    widget.onImageSelected(null);
                    Navigator.pop(context, null);
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final path = await ImageHelper.pickAndSaveImage(fromCamera: source);
      if (path != null) {
        setState(() {
          _currentImagePath = path;
        });
        widget.onImageSelected(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: widget.radius,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: _currentImagePath != null ? FileImage(File(_currentImagePath!)) : null,
              child: _currentImagePath == null
                  ? Icon(widget.placeholderIcon, size: widget.radius * 0.8, color: theme.colorScheme.primary.withValues(alpha: 0.5))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                ),
                child: Icon(
                  _currentImagePath != null ? Icons.edit : Icons.add,
                  size: 16,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

