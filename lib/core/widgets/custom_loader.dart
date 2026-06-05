import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const CustomLoader({super.key, this.size = 32.0, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default to a premium monochrome color based on theme if no color provided
    final loaderColor = color ?? (isDark ? Colors.white : Colors.black87);
    
    final barWidth = size * 0.22;
    final barHeight = size * 0.8;
    final gap = size * 0.12;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: gap / 2),
              width: barWidth,
              height: barHeight * 0.3, // Initial squeezed height
              decoration: BoxDecoration(
                color: loaderColor,
                borderRadius: BorderRadius.circular(barWidth / 2),
                boxShadow: [
                  BoxShadow(
                    color: loaderColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
            )
            .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
              delay: (index * 150).ms, // Staggered delay for wave effect
            )
            .scaleY(
              begin: 1.0, 
              end: 3.0, 
              duration: 450.ms, 
              curve: Curves.easeInOutSine,
            );
          }),
        ),
      ),
    );
  }
}
