import 'package:flutter/material.dart';

class HeavyIOSButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final Color? color;

  const HeavyIOSButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
    this.color,
  });

  @override
  State<HeavyIOSButton> createState() => _HeavyIOSButtonState();
}

class _HeavyIOSButtonState extends State<HeavyIOSButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBgColor = isDark ? Colors.white : Colors.black;
    final defaultFgColor = isDark ? Colors.black : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color ?? defaultBgColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.color != null ? Colors.white : defaultFgColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color != null ? Colors.white : defaultFgColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
