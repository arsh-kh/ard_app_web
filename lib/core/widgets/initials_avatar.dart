import 'dart:io';
import 'package:flutter/material.dart';

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

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: imageUrl != null ? FileImage(File(imageUrl!)) : null,
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
