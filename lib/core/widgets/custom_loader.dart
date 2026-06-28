import 'dart:math' as math;
import 'package:flutter/material.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const CustomLoader({super.key, this.size = 32.0, this.color});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A perfectly smooth, slightly relaxed 2-second continuous loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default to a premium monochrome color based on theme if no color provided
    final loaderColor =
        widget.color ?? (Theme.of(context).colorScheme.onSurface);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadiantWreathPainter(_controller.value, loaderColor),
        );
      },
    );
  }
}

class _RadiantWreathPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RadiantWreathPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.6;

    // THE BEAUTY ENGINE: A perfectly smooth spinning beam of light
    final sweepGradient = SweepGradient(
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.1),
        color.withValues(alpha: 0.5),
        color,
        Colors.transparent,
      ],
      // A much softer, smoother transition for the head of the gradient (0.9 to 1.0)
      stops: const [0.0, 0.3, 0.7, 0.9, 1.0],
      transform: GradientRotation(progress * 2 * math.pi),
    );

    final activeFillPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: size.width),
      )
      ..style = PaintingStyle.fill;

    final activeStemPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: size.width),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final trackFillPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final trackStemPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final grainsPath = Path();

    // The continuous unbroken circular stem
    final stemPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    // Helper to draw dense, beautiful organic wheat grains
    void drawOrganicGrain(Offset base, double angle) {
      final length = radius * 0.45;
      const width = 0.55;

      final tip = Offset(
        base.dx + length * math.cos(angle),
        base.dy + length * math.sin(angle),
      );

      final cp1 = Offset(
        base.dx + length * width * math.cos(angle - math.pi / 4),
        base.dy + length * width * math.sin(angle - math.pi / 4),
      );

      final cp2 = Offset(
        base.dx + length * width * math.cos(angle + math.pi / 4),
        base.dy + length * width * math.sin(angle + math.pi / 4),
      );

      grainsPath.moveTo(base.dx, base.dy);
      grainsPath.quadraticBezierTo(cp1.dx, cp1.dy, tip.dx, tip.dy);
      grainsPath.quadraticBezierTo(cp2.dx, cp2.dy, base.dx, base.dy);
    }

    // Generate an incredibly lush, dense, completely continuous braided wheat wreath
    // 16 tightly packed segments (32 total grains) creates a masterpiece of geometry
    const segments = 16;
    for (int i = 0; i < segments; i++) {
      final angle = (i / segments) * 2 * math.pi;
      final base = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      final tangent = angle + math.pi / 2;

      drawOrganicGrain(base, tangent - math.pi / 6);
      drawOrganicGrain(base, tangent + math.pi / 6);
    }

    // Draw the faint static background tracks first
    canvas.drawPath(grainsPath, trackFillPaint);
    canvas.drawPath(stemPath, trackStemPaint);

    // Draw the rapidly sweeping gradient illumination beam over top
    canvas.drawPath(grainsPath, activeFillPaint);
    canvas.drawPath(stemPath, activeStemPaint);
  }

  @override
  bool shouldRepaint(covariant _RadiantWreathPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
