import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerListLoader extends StatelessWidget {
  final int itemCount;
  final double height;
  final EdgeInsets padding;

  const ShimmerListLoader({
    super.key,
    this.itemCount = 5,
    this.height = 80.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Shimmer.fromColors(
            baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        );
      },
    );
  }
}
