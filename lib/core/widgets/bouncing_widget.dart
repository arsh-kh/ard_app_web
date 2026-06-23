import 'package:flutter/material.dart';

class BouncingWidget extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double scaleFactor;
  final Duration duration;

  const BouncingWidget({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleFactor = 0.94,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<BouncingWidget> createState() => _BouncingWidgetState();
}

class _BouncingWidgetState extends State<BouncingWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
