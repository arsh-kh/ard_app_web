import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final GlobalKey appBoundaryKey = GlobalKey();

class GlobalRevealManager {
  static Future<void> animateChange(
    BuildContext context, 
    Offset tapPosition, 
    VoidCallback onStateChanged,
  ) async {
    // 1. Capture screenshot of the current UI
    RenderRepaintBoundary? boundary = appBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      onStateChanged();
      return;
    }

    ui.Image? image;
    try {
      image = await boundary.toImage(pixelRatio: MediaQuery.of(context).devicePixelRatio);
    } catch (e) {
      onStateChanged();
      return;
    }

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      onStateChanged();
      return;
    }
    
    final bytes = byteData.buffer.asUint8List();

    // 2. Render screenshot on an OverlayEntry covering the screen
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) {
        return _RevealOverlay(
          imageBytes: bytes,
          tapPosition: tapPosition,
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
  final Uint8List imageBytes;
  final Offset tapPosition;
  final VoidCallback onComplete;

  const _RevealOverlay({
    required this.imageBytes,
    required this.tapPosition,
    required this.onComplete,
  });

  @override
  State<_RevealOverlay> createState() => _RevealOverlayState();
}

class _RevealOverlayState extends State<_RevealOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Start animation immediately
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
        final maxRadius = screenSize.longestSide * 1.5;
        // As the animation progresses, the old screenshot shrinks into the tap position
        return ClipPath(
          clipper: _RevealClipper(widget.tapPosition, (1.0 - Curves.easeOutCubic.transform(_controller.value)) * maxRadius),
          child: child,
        );
      },
      child: Image.memory(widget.imageBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
    );
  }
}

class _RevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  _RevealClipper(this.center, this.radius);
  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }
  @override
  bool shouldReclip(_RevealClipper old) => radius != old.radius || center != old.center;
}
