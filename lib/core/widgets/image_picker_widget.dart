import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/image_helper.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImagePath;
  final Function(String?) onImageSelected;
  final double radius;
  final IconData placeholderIcon;
  final String? namePlaceholder;
  final bool isKurdish;
  final bool isArabic;
  final String? heroTag;

  const ImagePickerWidget({
    super.key,
    this.initialImagePath,
    required this.onImageSelected,
    this.radius = 50,
    this.placeholderIcon = Icons.add_a_photo,
    this.namePlaceholder,
    this.isKurdish = false,
    this.isArabic = false,
    this.heroTag,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(
                  widget.isKurdish
                      ? 'کامێرا'
                      : widget.isArabic
                      ? 'كاميرا'
                      : 'Camera',
                ),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                  widget.isKurdish
                      ? 'وێنەکان'
                      : widget.isArabic
                      ? 'معرض الصور'
                      : 'Gallery',
                ),
                onTap: () => Navigator.pop(context, false),
              ),
              if (_currentImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    widget.isKurdish
                        ? 'سڕینەوەی وێنە'
                        : widget.isArabic
                        ? 'حذف الصورة'
                        : 'Remove Photo',
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
    final isDark = theme.brightness == Brightness.dark;

    // High-contrast avatar placeholder: white bg + black text in light mode,
    // near-black bg + white text in dark mode — always readable.
    final avatarBg = isDark ? const Color(0xFF2C2C2E) : Colors.black;
    const avatarFg = Colors.white;

    ImageProvider? imageProvider;
    if (_currentImagePath != null && _currentImagePath!.isNotEmpty) {
      if (_currentImagePath!.startsWith('http') ||
          _currentImagePath!.startsWith('https')) {
        imageProvider = CachedNetworkImageProvider(_currentImagePath!);
      } else if (_currentImagePath!.startsWith('blob:') || kIsWeb) {
        imageProvider = NetworkImage(_currentImagePath!);
      } else {
        imageProvider = FileImage(File(_currentImagePath!));
      }
    }

    Widget avatarWidget = CircleAvatar(
      radius: widget.radius,
      backgroundColor: avatarBg,
      backgroundImage: imageProvider,
      child: _currentImagePath == null
          ? (widget.namePlaceholder != null &&
                    widget.namePlaceholder!.trim().isNotEmpty)
                ? Text(
                    widget.namePlaceholder!.trim()[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: widget.radius * 0.8,
                      fontWeight: FontWeight.bold,
                      color: avatarFg,
                    ),
                  )
                : Icon(
                    widget.placeholderIcon,
                    size: widget.radius * 0.8,
                    color: avatarFg.withValues(alpha: 0.5),
                  )
          : null,
    );

    if (widget.heroTag != null) {
      avatarWidget = Hero(
        tag: widget.heroTag!,
        child: Material(
          type: MaterialType.transparency,
          child: avatarWidget,
        ),
      );
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          children: [
            avatarWidget,
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
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
