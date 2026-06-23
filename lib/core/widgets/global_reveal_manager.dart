import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final GlobalKey appBoundaryKey = GlobalKey();

class GlobalRevealManager {
  static Future<void> animateChange(
    BuildContext context,
    Offset tapPosition,
    VoidCallback onStateChanged, {
    bool isExpanding = true,
  }) async {
    // 1. Capture screenshot of the current UI
    final RenderRepaintBoundary? boundary =
        appBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      onStateChanged();
      return;
    }

    ui.Image? image;
    try {
      image = await boundary.toImage(pixelRatio: 0.5);
    } catch (e) {
      onStateChanged();
      return;
    }

    // 2. Render screenshot on an OverlayEntry covering the screen
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return _RevealOverlay(
          image: image!,
          tapPosition: tapPosition,
          isExpanding: isExpanding,
          onComplete: () {
            if (entry != null && entry!.mounted) {
              entry!.remove();
              entry = null;
            }
          },
        );
      },
    );

    if (!context.mounted) return;
    Overlay.of(context, rootOverlay: true).insert(entry!);

    // 3. Immediately trigger the state change (theme or language)
    // We delay slightly so the image overlay has 1 frame to render on screen before the UI beneath changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStateChanged();
    });
  }
}

class _RevealOverlay extends StatefulWidget {
  final ui.Image image;
  final Offset tapPosition;
  final bool isExpanding;
  final VoidCallback onComplete;

  const _RevealOverlay({
    required this.image,
    required this.tapPosition,
    required this.isExpanding,
    required this.onComplete,
  });

  @override
  State<_RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<_RevealOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Start animation immediately
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final center = widget.tapPosition;
        final d1 = center.distance;
        final d2 = (center - Offset(screenSize.width, 0)).distance;
        final d3 = (center - Offset(0, screenSize.height)).distance;
        final d4 =
            (center - Offset(screenSize.width, screenSize.height)).distance;
        final maxRadius = [d1, d2, d3, d4].reduce(math.max);

        final radiusValue = Curves.easeInOutCubic.transform(_controller.value);
        final currentRadius = widget.isExpanding
            ? radiusValue * maxRadius
            : (1.0 - radiusValue) * maxRadius;

        return ClipPath(
          clipper: _RevealClipper(
            widget.tapPosition,
            currentRadius,
            isExpanding: widget.isExpanding,
          ),
          child: child,
        );
      },
      child: SizedBox.expand(
        child: RawImage(image: widget.image, fit: BoxFit.cover),
      ),
    );
  }
}

class _RevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  final bool isExpanding;

  _RevealClipper(this.center, this.radius, {required this.isExpanding});

  @override
  Path getClip(Size size) {
    if (isExpanding) {
      return Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(Rect.fromCircle(center: center, radius: radius));
    } else {
      return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    }
  }

  @override
  bool shouldReclip(_RevealClipper old) =>
      radius != old.radius ||
      center != old.center ||
      isExpanding != old.isExpanding;
}
