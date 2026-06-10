import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class InitialsAvatar extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final double radius;

  const InitialsAvatar({
    super.key,
    required this.text,
    this.imageUrl,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? Colors.white : theme.colorScheme.primary;
    final textColor = isDark ? Colors.black : Colors.white;

    ImageProvider? imageProvider;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http') || imageUrl!.startsWith('https')) {
        imageProvider = CachedNetworkImageProvider(imageUrl!);
      } else if (imageUrl!.startsWith('blob:') || kIsWeb) {
        imageProvider = NetworkImage(imageUrl!);
      } else {
        imageProvider = FileImage(File(imageUrl!));
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: imageProvider,
      child: imageUrl == null && text.isNotEmpty
          ? Text(
              text[0].toUpperCase(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.9,
              ),
            )
          : null,
    );
  }
}

