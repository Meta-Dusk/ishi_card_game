import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The style of animation applied to the gradient
enum GradientAnimation { spin, scroll, breathe }

class AnimatedGradientBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget? child;
  final Duration duration;
  final GradientAnimation animationType;

  const AnimatedGradientBackground({
    super.key,
    required this.colors,
    this.child,
    this.duration = const Duration(seconds: 15),
    this.animationType = .breathe,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animatedBuilder = AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final val = _controller.value;
        final angle = val * 2 * math.pi; // Used for circular math

        late Gradient gradient;

        switch (widget.animationType) {
          // THE SPIN: Rotates the begin and end points in a circle
          case .spin:
            gradient = LinearGradient(
              colors: widget.colors,
              begin: Alignment(math.cos(angle), math.sin(angle)),
              end: Alignment(
                math.cos(angle + math.pi),
                math.sin(angle + math.pi),
              ),
            );
            break;

          // THE SCROLL: Pans diagonally.
          case .scroll:
            gradient = LinearGradient(
              colors: widget.colors,
              begin: Alignment(-1.0 + (val * 2), -1.0 + (val * 2)),
              end: Alignment(1.0 + (val * 2), 1.0 + (val * 2)),
              tileMode: .repeated,
            );
            break;

          // THE BREATHE: A radial gradient that softly pulses and shifts its focal point.
          case .breathe:
            // Smoothly oscillates from -1.0 to 1.0
            final pulse = math.sin(angle);
            gradient = RadialGradient(
              colors: widget.colors,
              center: .center,
              // Slowly drift the bright core around the center
              focal: Alignment(0.15 * pulse, 0.15 * math.cos(angle)),
              // Expand and contract the radius
              radius: 1.2 + (0.2 * pulse),
            );
            break;
        }

        return Container(decoration: BoxDecoration(gradient: gradient));
      },
    );

    return Stack(
      children: [
        Positioned.fill(child: animatedBuilder),

        // Foreground Content
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}
