import 'dart:math';
import 'package:flutter/material.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final double angle;
  final int currentPage;
  final int totalPages;
  final Widget child;

  const OnboardingPageIndicator({
    super.key,
    required this.angle,
    required this.currentPage,
    required this.totalPages,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _IndicatorPainter(
          color: colorScheme.onSurface,
          arcAngle: angle,
          currentPage: currentPage,
          totalPages: totalPages,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _IndicatorPainter extends CustomPainter {
  final Color color;
  final double arcAngle;
  final int currentPage;
  final int totalPages;

  _IndicatorPainter({
    required this.color,
    required this.arcAngle,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    const double indicatorGap = pi / 12;
    final double indicatorLength = (2 * pi - (totalPages * indicatorGap)) / totalPages;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-pi / 2 + arcAngle);
    canvas.translate(-center.dx, -center.dy);

    for (int i = 0; i < totalPages; i++) {
      final isFilled = currentPage > i;
      
      final paint = Paint()
        ..color = isFilled ? color : color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      final startAngle = i * (indicatorLength + indicatorGap);
      
      canvas.drawArc(
        rect,
        startAngle,
        indicatorLength,
        false,
        paint,
      );
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IndicatorPainter oldDelegate) {
    return oldDelegate.arcAngle != arcAngle || oldDelegate.currentPage != currentPage || oldDelegate.totalPages != totalPages;
  }
}


