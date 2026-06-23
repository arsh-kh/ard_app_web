import 'package:flutter/material.dart';

class AnimatedSegmentedPill<T> extends StatefulWidget {
  final List<T> items;
  final T selectedValue;
  final ValueChanged<T> onChanged;
  final String Function(T item) labelBuilder;
  final IconData? Function(T item)? iconBuilder;

  const AnimatedSegmentedPill({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    required this.labelBuilder,
    this.iconBuilder,
  });

  @override
  State<AnimatedSegmentedPill<T>> createState() =>
      _AnimatedSegmentedPillState<T>();
}

class _AnimatedSegmentedPillState<T> extends State<AnimatedSegmentedPill<T>> {
  late List<GlobalKey> _keys;
  double _pillLeft = 0;
  double _pillWidth = 0;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.items.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePillPosition());
  }

  @override
  void didUpdateWidget(covariant AnimatedSegmentedPill<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _keys = List.generate(widget.items.length, (_) => GlobalKey());
      _isInit = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePillPosition());
  }

  void _updatePillPosition() {
    if (!mounted) return;
    final int selectedIndex = widget.items.indexOf(widget.selectedValue);
    if (selectedIndex < 0 || selectedIndex >= _keys.length) return;

    final RenderBox? selectedBox =
        _keys[selectedIndex].currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? parentBox = context.findRenderObject() as RenderBox?;

    if (selectedBox != null && parentBox != null) {
      // Get exact physical offset relative to the stack
      final offset = selectedBox.localToGlobal(
        Offset.zero,
        ancestor: parentBox,
      );
      setState(() {
        _pillLeft = offset.dx;
        _pillWidth = selectedBox.size.width;
        _isInit = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Stack(
        children: [
          if (_isInit)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: _pillLeft,
              top: 0,
              bottom: 0,
              width: _pillWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.items.length, (index) {
              final item = widget.items[index];
              final isSelected = item == widget.selectedValue;
              return GestureDetector(
                key: _keys[index],
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onChanged(item);
                  // Update position immediately on tap to keep it snappy
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _updatePillPosition(),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.iconBuilder?.call(item) != null) ...[
                        Icon(
                          widget.iconBuilder!(item),
                          size: 14,
                          color: isSelected
                              ? (Theme.of(context).colorScheme.onSurface)
                              : (Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 6),
                      ],
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter', // Assuming Inter or system font
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? (Theme.of(context).colorScheme.onSurface)
                              : Colors.grey.shade500,
                        ),
                        child: Text(widget.labelBuilder(item)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
