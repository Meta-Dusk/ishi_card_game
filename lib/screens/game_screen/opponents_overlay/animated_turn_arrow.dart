import 'package:flutter/material.dart';

class AnimatedTurnArrow extends StatefulWidget {
  const AnimatedTurnArrow({super.key});

  @override
  State<AnimatedTurnArrow> createState() => _AnimatedTurnArrowState();
}

class _AnimatedTurnArrowState extends State<AnimatedTurnArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
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
      builder: (_, child) => Transform.translate(
        offset: Offset(_controller.value * -6.0, 0),
        child: child,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.orangeAccent, size: 20),
    );
  }
}
