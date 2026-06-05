import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlourBagPainter extends CustomPainter {
  final int look;    // 0=idle, 1=tracking, 2=cover
  final double eyeX; // -0.8..+0.8
  final double peek; // 0=covered, 1=peeking
  final bool isDark;
  final TextDirection textDirection;

  const FlourBagPainter({
    this.look = 0,
    this.eyeX = 0.0,
    this.peek = 0.0,
    required this.isDark,
    required this.textDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    final bagColor = Colors.white;
    final shadeColor = const Color(0xFFDEDEDE);
    final knotColor = const Color(0xFF777777);
    final inkColor = Colors.black87;

    // Drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 62), width: 65, height: 9),
      Paint()
        ..color = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // Bag body
    final body = Path()
      ..moveTo(cx - 34, cy + 58)
      ..quadraticBezierTo(cx, cy + 66, cx + 34, cy + 58)
      ..quadraticBezierTo(cx + 47, cy + 24, cx + 38, cy - 6)
      ..quadraticBezierTo(cx + 32, cy - 30, cx + 17, cy - 36)
      ..lineTo(cx - 17, cy - 36)
      ..quadraticBezierTo(cx - 32, cy - 30, cx - 38, cy - 6)
      ..quadraticBezierTo(cx - 47, cy + 24, cx - 34, cy + 58)
      ..close();

    canvas.drawPath(body, Paint()..color = bagColor);
    canvas.drawPath(body, Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, shadeColor.withValues(alpha: 0.38)],
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
      ).createShader(Rect.fromLTWH(cx, cy - 36, 48, 102), textDirection: textDirection));
    canvas.drawPath(body, Paint()
      ..color = inkColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);

    // Seams
    final s = Paint()..color = shadeColor..strokeWidth = 0.9..style = PaintingStyle.stroke;
    for (final dy in [6.0, 20.0, 36.0]) {
      canvas.drawLine(Offset(cx - 26, cy + dy), Offset(cx + 26, cy + dy), s);
    }

    // Gathered Top Fabric (Flour Bag Ruffles)
    final gatherPath = Path()
      ..moveTo(cx - 16, cy - 35) // start at neck
      ..quadraticBezierTo(cx - 24, cy - 48, cx - 18, cy - 54) // flare left
      ..quadraticBezierTo(cx - 8, cy - 50, cx, cy - 56) // wavy top edge
      ..quadraticBezierTo(cx + 8, cy - 50, cx + 18, cy - 54) // wavy top edge
      ..quadraticBezierTo(cx + 24, cy - 48, cx + 16, cy - 35) // flare right
      ..close();

    // Fill it with bag color
    canvas.drawPath(gatherPath, Paint()..color = bagColor);
    
    // Outline it
    canvas.drawPath(gatherPath, Paint()
      ..color = inkColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);

    // Draw some vertical crease lines on the ruffled top
    final ruffleCrease = Paint()
      ..color = shadeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(Offset(cx - 8, cy - 36), Offset(cx - 12, cy - 50), ruffleCrease);
    canvas.drawLine(Offset(cx, cy - 36), Offset(cx, cy - 52), ruffleCrease);
    canvas.drawLine(Offset(cx + 8, cy - 36), Offset(cx + 12, cy - 50), ruffleCrease);

    // The Tie (Rope/String around the neck)
    final ropeColor = const Color(0xFFC0A080); // Brownish rope color
    final ropePaint = Paint()
      ..color = ropeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Wrap around neck
    canvas.drawLine(Offset(cx - 18, cy - 35), Offset(cx + 18, cy - 35), ropePaint);

    // FACE
    if (look == 2) {
      _drawCovering(canvas, cx, cy, bagColor, shadeColor, knotColor, inkColor);
    } else {
      final ex = eyeX * 5.0;
      final ey = look == 1 ? 3.5 : 0.0;

      // Brows: two small round dots above eyes (not lines) — neutral look
      _drawBrowDot(canvas, cx - 14, cy - 27, inkColor);
      _drawBrowDot(canvas, cx + 14, cy - 27, inkColor);

      // Eyes
      _drawEye(canvas, cx - 14, cy - 10, ex, ey, bagColor, inkColor);
      _drawEye(canvas, cx + 14, cy - 10, ex, ey, bagColor, inkColor);

      // Blush
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 27, cy + 1), width: 12, height: 7),
          Paint()..color = inkColor.withValues(alpha: 0.05));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 27, cy + 1), width: 12, height: 7),
          Paint()..color = inkColor.withValues(alpha: 0.05));

      // Smile
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy + 7), width: 20, height: 10),
        0, math.pi, false,
        Paint()..color = inkColor.withValues(alpha: 0.25)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawCovering(Canvas canvas, double cx, double cy,
      Color bag, Color shade, Color knot, Color ink) {
    final drop = peek * 22.0;
    final handTopY = cy - 22 + drop;
    final handCenterY = handTopY + 14;

    if (drop > 5) {
      final eyeReveal = ((drop - 5) / 17.0).clamp(0.0, 1.0);
      final eyeH = 3.0 + eyeReveal * 11.0;
      _drawNarrowEye(canvas, cx - 14, cy - 10, eyeH, bag, ink);
      _drawNarrowEye(canvas, cx + 14, cy - 10, eyeH, bag, ink);
    } else {
      final sp = Paint()
        ..color = ink.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 14, cy - 12), width: 16, height: 8), 0, math.pi, false, sp);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 14, cy - 12), width: 16, height: 8), 0, math.pi, false, sp);
    }

    _drawHandPad(canvas, cx - 14, handCenterY, bag, shade);
    _drawHandPad(canvas, cx + 14, handCenterY, bag, shade);

    _drawBrowDot(canvas, cx - 14, cy - 27, ink);
    _drawBrowDot(canvas, cx + 14, cy - 27, ink);

    final blush = 0.04 + peek * 0.14;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 28, cy + 4), width: 15, height: 9),
        Paint()..color = ink.withValues(alpha: blush));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 28, cy + 4), width: 15, height: 9),
        Paint()..color = ink.withValues(alpha: blush));

    final mp = Paint()
      ..color = ink.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (peek > 0.5) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 4, cy + 10), width: 15, height: 7),
        0.1, math.pi * 0.75, false, mp,
      );
    } else {
      canvas.drawLine(Offset(cx - 7, cy + 10), Offset(cx + 7, cy + 10), mp);
    }
  }

  void _drawHandPad(Canvas canvas, double cx, double cy, Color bag, Color shade) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 1.5, cy + 2.5), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = shade.withValues(alpha: 0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = bag,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = shade.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    for (int i = 0; i < 4; i++) {
      final fx = cx - 10.5 + i * 7.0;
      final fy = cy - 14.5;
      canvas.drawCircle(Offset(fx + 1, fy + 1), 5.2, Paint()..color = shade.withValues(alpha: 0.2));
      canvas.drawCircle(Offset(fx, fy), 5.2, Paint()..color = bag);
      canvas.drawCircle(Offset(fx, fy), 5.2,
          Paint()..color = shade.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
  }

  void _drawEye(Canvas canvas, double x, double y, double ex, double ey, Color white, Color dark) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: 16), Paint()..color = white);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: 16),
        Paint()..color = dark.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    final px = (x + ex).clamp(x - 5.0, x + 5.0);
    final py = (y + ey).clamp(y - 3.0, y + 3.0);
    canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = dark);
    canvas.drawCircle(Offset(px, py - 2.2), 1.7, Paint()..color = white.withValues(alpha: 0.82));
  }

  void _drawNarrowEye(Canvas canvas, double x, double y, double h, Color white, Color dark) {
    if (h < 1.0) return;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: h), Paint()..color = white);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: h),
        Paint()..color = dark.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final pr = (h * 0.45).clamp(1.5, 6.0);
    canvas.drawCircle(Offset(x, y + h * 0.12), pr, Paint()..color = dark);
    canvas.drawCircle(Offset(x, y + h * 0.12 - pr * 0.35), (pr * 0.3).clamp(0.5, 2.0),
        Paint()..color = white.withValues(alpha: 0.8));
  }

  void _drawBrowDot(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()..color = color.withValues(alpha: 0.28);
    canvas.drawOval(Rect.fromCenter(center: Offset(x - 4, y), width: 5, height: 3.5), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 4, y), width: 5, height: 3.5), paint);
  }

  @override
  bool shouldRepaint(FlourBagPainter o) =>
      o.look != look || o.eyeX != eyeX || o.peek != peek || o.isDark != isDark;
}
