import 'package:flutter/material.dart';

class HeavyIOSButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const HeavyIOSButton({
    super.key,
    required this.onTap,
    required this.label,
    required this.icon,
  });

  @override
  State<HeavyIOSButton> createState() => _HeavyIOSButtonState();
}

class _HeavyIOSButtonState extends State<HeavyIOSButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: _isPressed ? 0.05 : 0.3),
                blurRadius: _isPressed ? 4 : 14,
                offset: Offset(0, _isPressed ? 2 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: isDark ? Colors.black : Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
