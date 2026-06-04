import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomLoader({super.key, this.size = 48.0, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loaderColor = color ?? theme.colorScheme.primary;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: loaderColor.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glowing ring
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: loaderColor.withOpacity(0.5), width: 2),
              ),
            ).animate(onPlay: (controller) => controller.repeat())
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.4, 1.4), duration: 1500.ms, curve: Curves.easeOut)
             .fadeOut(duration: 1500.ms, curve: Curves.easeOut),
            
            // Inner pulsing dot
            Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: loaderColor,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms, curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}
