import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'custom_loader.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UniversalImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;

  const UniversalImage(
    this.imagePath, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildError(),
      );
    } else if (imagePath.startsWith('blob:')) {
      // Handle web local object URLs from image_picker
      return Image.network(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (_, __, ___) => _buildError(),
      );
    } else {
      if (kIsWeb) {
        return Image.network(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: colorBlendMode,
          errorBuilder: (_, __, ___) => _buildError(),
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: colorBlendMode,
          errorBuilder: (_, __, ___) => _buildError(),
        );
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CustomLoader(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
