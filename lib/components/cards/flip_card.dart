import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFaceUp;
  final VoidCallback? onTap;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFaceUp,
    this.onTap,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Begin = Back (pi), End = Front (0)
    _animation = Tween<double>(
      begin: math.pi,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Set initial state without animating
    if (widget.isFaceUp) _controller.value = 1.0;
  }

  // This lifecycle method fires whenever the parent (GameScreen) rebuilds
  // and passes a new 'isFaceUp' boolean to this widget.
  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFaceUp != oldWidget.isFaceUp) {
      if (widget.isFaceUp) {
        _controller.forward(); // Animate to 0 (Front)
      } else {
        _controller.reverse(); // Animate back to pi (Back)
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => _FlipTransform(animation: _animation, widget: widget),
    ),
  );
}

class _FlipTransform extends StatelessWidget {
  const _FlipTransform({required this.animation, required this.widget});

  final Animation<double> animation;
  final FlipCard widget;

  @override
  Widget build(BuildContext context) {
    bool isFrontVisible = animation.value < (math.pi / 2);
    return Transform(
      alignment: .center,
      transform: .identity()
        ..setEntry(3, 2, 0.001) // 3D Perspective
        ..rotateY(animation.value),
      child: isFrontVisible ? widget.front : _flipTransform(),
    );
  }

  Transform _flipTransform() => Transform(
    // Flip the back 180 degrees so it's not mirrored
    alignment: .center,
    transform: .identity()..rotateY(math.pi),
    child: widget.back,
  );
}
