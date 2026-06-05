import 'dart:ui';
import 'package:flutter/material.dart';

class ModernSplashLoader extends StatefulWidget {
  const ModernSplashLoader({super.key});

  @override
  State<ModernSplashLoader> createState() => _ModernSplashLoaderState();
}

class _ModernSplashLoaderState extends State<ModernSplashLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A 4-second, ultra-smooth cinematic loop
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(64, 80),
          painter: _MinimalistWheatPainter(_controller.value, color),
        );
      },
    );
  }
}

class _MinimalistWheatPainter extends CustomPainter {
  final double progress;
  final Color color;

  _MinimalistWheatPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final centerX = size.width / 2;
    final bottomY = size.height * 0.9;
    final topY = size.height * 0.1;

    // The central stem
    path.moveTo(centerX, bottomY);
    path.lineTo(centerX, topY);

    // 3 Geometric minimalist wheat grains (chevrons) blooming upwards
    for (int i = 0; i < 3; i++) {
      final yBase = topY + (size.height * 0.2 * i) + (size.height * 0.15);
      final grainHeight = size.height * 0.15;
      final spreadX = size.width * 0.25;

      // Left grain
      path.moveTo(centerX, yBase);
      path.lineTo(centerX - spreadX, yBase - grainHeight);
      
      // Right grain
      path.moveTo(centerX, yBase);
      path.lineTo(centerX + spreadX, yBase - grainHeight);
    }

    // Extract all individual line segments to animate them simultaneously
    final pathMetrics = path.computeMetrics().toList();
    
    // We break the 4-second loop into 4 cinematic phases:
    // Phase 1 (0% to 40%): Smoothly draw in
    // Phase 2 (40% to 50%): Pause and hold the full icon
    // Phase 3 (50% to 90%): Smoothly erase out in the same direction
    // Phase 4 (90% to 100%): Pause empty before looping
    
    double curveProgress;
    bool isDrawing = true;

    if (progress <= 0.4) {
      curveProgress = Curves.easeInOutQuint.transform(progress / 0.4);
    } else if (progress <= 0.5) {
      curveProgress = 1.0;
    } else if (progress <= 0.9) {
      isDrawing = false;
      curveProgress = Curves.easeInOutQuint.transform((progress - 0.5) / 0.4);
    } else {
      isDrawing = false;
      curveProgress = 1.0;
    }

    for (var metric in pathMetrics) {
      final extractPath = isDrawing
          ? metric.extractPath(0.0, metric.length * curveProgress)
          : metric.extractPath(metric.length * curveProgress, metric.length);
          
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalistWheatPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
