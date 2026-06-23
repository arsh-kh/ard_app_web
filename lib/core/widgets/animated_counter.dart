import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final bool isCurrency;

  const AnimatedCounter({
    super.key,
    required this.value,
    required this.style,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        final formattedValue = isCurrency
            ? CurrencyFormatter.format(val)
            : val.toInt().toString();
        return Text(formattedValue, style: style);
      },
    );
  }
}
