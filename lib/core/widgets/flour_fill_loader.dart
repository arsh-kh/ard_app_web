import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlourFillLoader extends StatefulWidget {
  final double width;
  final double height;
  const FlourFillLoader({super.key, this.width = 280, this.height = 360});

  @override
  State<FlourFillLoader> createState() => _FlourFillLoaderState();
}

class _FlourFillLoaderState extends State<FlourFillLoader> with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    // Continuous physics (particle and dust sway)
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    
    // The main loading progress (0 to 1) over 3 seconds
    _fillController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000));
    
    _fillAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.33).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.33), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.33, end: 0.66).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.66), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.66, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 15),
    ]).animate(_fillController);

    _fillController.forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _fillController]),
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFF121212), // Deep premium dark background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _CinematicFlourPainter(
              waveValue: _waveController.value,
              fillValue: _fillAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class _CinematicFlourPainter extends CustomPainter {
  final double waveValue;
  final double fillValue;

  _CinematicFlourPainter({
    required this.waveValue,
    required this.fillValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // To make it look like powder/flour filling from the bottom up:
    // we map fillValue to the volume of a pile. 
    // The pile is a cone shape, not a flat liquid line.
    final double fillHeight = size.height * fillValue;
    final double fillY = size.height - fillHeight;
    final double centerX = size.width / 2;
    
    // ==========================================
    // 1. TYPOGRAPHY (Base Layer - White Text)
    // ==========================================
    _drawTypography(canvas, size, Colors.white);

    // ==========================================
    // 2. THE RISING FLOUR MOUND (Powder physics, NOT liquid)
    // ==========================================
    final flourAreaPath = Path();
    
    // Flour piles in a conical mound with an angle of repose (roughly 40 degrees)
    // We simulate this by drawing a curved triangle that spreads out
    
    for (int i = 0; i < 3; i++) {
      final moundPath = Path();
      
      // Depth offsets
      double layerFillY = fillY - (i * 15.0); 
      if (layerFillY > size.height) layerFillY = size.height;
      
      double layerPileHeight = size.height - layerFillY;
      // The wider it spreads, the more it looks like a pile of powder
      double baseSpread = layerPileHeight * 1.5 + (i * 20.0); 

      moundPath.moveTo(centerX, layerFillY); // Peak of the pile

      // Right slope of the powder pile
      moundPath.quadraticBezierTo(
        centerX + baseSpread * 0.5, 
        layerFillY + layerPileHeight * 0.4, 
        centerX + baseSpread, 
        size.height
      );
      
      // Bottom flat edge
      moundPath.lineTo(centerX - baseSpread, size.height);
      
      // Left slope of the powder pile
      moundPath.quadraticBezierTo(
        centerX - baseSpread * 0.5, 
        layerFillY + layerPileHeight * 0.4, 
        centerX, 
        layerFillY
      );

      moundPath.close();

      flourAreaPath.addPath(moundPath, Offset.zero);

      final layerColor = i == 0 
          ? Colors.white
          : Colors.white.withValues(alpha: 0.6 - (i * 0.2));
          
      // Give the mound a very slight blur so it looks powdery and soft, not rigid
      canvas.drawPath(moundPath, Paint()
        ..color = layerColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + i)
      );
    }

    // ==========================================
    // 3. TYPOGRAPHY (Inverted Layer - Dark Text)
    // ==========================================
    canvas.save();
    canvas.clipPath(flourAreaPath);
    // Draw the exact same text, but dark, clipped exactly to the flour shape!
    _drawTypography(canvas, size, const Color(0xFF121212));
    canvas.restore();

    // ==========================================
    // 4. THE FALLING FLOUR STREAM & DUST IMPACTS
    // ==========================================
    if (fillValue < 0.98 && fillValue > 0.02) {
      // Stream falls straight down, not swaying like water
      final streamPath = Path();
      streamPath.moveTo(centerX - 8, 0);
      
      // Jagged edges to make it look like granular powder falling rapidly
      double noise = math.sin(waveValue * math.pi * 30) * 4;
      streamPath.lineTo(centerX - 4 + noise, fillY);
      streamPath.lineTo(centerX + 4 - noise, fillY);
      streamPath.lineTo(centerX + 8, 0);
      streamPath.close();

      final streamGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(centerX - 15, 0, 30, fillY));

      canvas.drawPath(streamPath, Paint()..shader = streamGradient);

      // Impact Dust Particles (Flour exploding on impact and avalanching down)
      for (int i = 0; i < 25; i++) {
        final phase = (waveValue * 10 + i * 0.618) % 1.0; 
        
        // Powder slides down the slopes (avalanche effect)
        final slideDirection = (i % 2 == 0) ? 1.0 : -1.0;
        final slideSpeed = 20.0 + (i * 2.0);
        final dx = slideDirection * (10.0 + phase * slideSpeed); 
        final dy = phase * slideSpeed * 0.8; // Move down the slope
        
        // Powdery dust kicking up into the air
        final upDx = math.sin(i * 1.3) * 50.0 * phase; 
        final upDy = -math.cos(i * 0.9) * 40.0 * phase; 

        final opacity = (1.0 - phase) * 0.6;
        final radius = 2.0 + (phase * 12.0); // Spreads out like a puff of dust

        // Sliding avalanche clumps
        canvas.drawCircle(
          Offset(centerX + dx, fillY + dy), 
          radius * 0.5, 
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
        );

        // Airborne dust puffs
        canvas.drawCircle(
          Offset(centerX + upDx, fillY + upDy), 
          radius, 
          Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
        );
      }
    }
  }

  void _drawTypography(Canvas canvas, Size size, Color color) {
    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    // Percentage perfectly centered (massive typography)
    textPainter.text = TextSpan(
      text: '${(fillValue * 100).toInt()}%',
      style: TextStyle(
        color: color,
        fontSize: 56, // Massive focal point
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2)
    );
  }

  @override
  bool shouldRepaint(_CinematicFlourPainter oldDelegate) {
    return oldDelegate.waveValue != waveValue || oldDelegate.fillValue != fillValue;
  }
}

