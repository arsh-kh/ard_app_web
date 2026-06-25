import 'dart:math' show pi;
import 'package:flutter/material.dart';

class AnimatedCardStack extends StatefulWidget {
  final List<Widget> cards;
  final List<Animation<Offset>> slideAnimations;
  final int? activeIndex;

  const AnimatedCardStack({
    super.key,
    required this.cards,
    required this.slideAnimations,
    this.activeIndex,
  });

  @override
  State<AnimatedCardStack> createState() => _AnimatedCardStackState();
}

class _AnimatedCardStackState extends State<AnimatedCardStack> {
  late int _internalIndex;

  @override
  void initState() {
    super.initState();
    _internalIndex = widget.activeIndex ?? 0;
  }

  @override
  void didUpdateWidget(AnimatedCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeIndex != null && widget.activeIndex != oldWidget.activeIndex) {
      _internalIndex = widget.activeIndex!;
    }
  }

  void _nextCard() {
    if (widget.activeIndex != null) return;
    if (widget.cards.length <= 1) return;
    setState(() {
      _internalIndex = (_internalIndex + 1) % widget.cards.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int N = widget.cards.length;
    if (N == 0) return const SizedBox();

    final List<_CardRenderData> renderData = [];

    for (int i = 0; i < N; i++) {
      // Calculate relative position: 0 is front, 1 is middle, 2 is back...
      // To make them stack in the specific order requested (Kurdish front, English middle, Arabic back)
      int relativePos = (_internalIndex - i) % N;
      if (relativePos < 0) relativePos += N;

      final double x = relativePos * -15.0;
      final double y = relativePos * -30.0;
      final double angle = relativePos * (-pi / 18);
      final double scale = 1.0 - (relativePos * 0.05);

      renderData.add(_CardRenderData(
        index: i,
        widget: widget.cards[i],
        slideAnimation: widget.slideAnimations[i % widget.slideAnimations.length],
        x: x,
        y: y,
        angle: angle,
        scale: scale,
        relativePos: relativePos,
      ));
    }

    // Sort descending by relativePos so the largest relativePos (furthest back) is rendered first (bottom of stack)
    // relativePos = 0 (front) is rendered last (top of stack)
    renderData.sort((a, b) => b.relativePos.compareTo(a.relativePos));

    return GestureDetector(
      onTap: _nextCard,
      onPanEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx.abs() > 200) {
          _nextCard();
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: renderData.map((data) {
          return SlideTransition(
            key: ValueKey(data.index),
            position: data.slideAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(data.x, data.y, 0.0)
                ..rotateZ(data.angle)
                ..multiply(Matrix4.diagonal3Values(data.scale, data.scale, 1.0)),
              alignment: Alignment.center,
              child: data.widget,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CardRenderData {
  final int index;
  final Widget widget;
  final Animation<Offset> slideAnimation;
  final double x;
  final double y;
  final double angle;
  final double scale;
  final int relativePos;

  _CardRenderData({
    required this.index,
    required this.widget,
    required this.slideAnimation,
    required this.x,
    required this.y,
    required this.angle,
    required this.scale,
    required this.relativePos,
  });
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const GlassCard({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);
    
    return Container(
      width: 220,
      height: 310,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: child,
    );
  }
}
