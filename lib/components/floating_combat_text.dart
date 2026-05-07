import 'package:flutter/material.dart';

class FloatingCombatText extends StatelessWidget {
  final String text;
  final Color color;

  const FloatingCombatText({
    super.key,
    required this.text,
    this.color = Colors.redAccent,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      // Animates from 0.0 to 1.0
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeOutCubic, // Starts fast, slows down smoothly
      builder: (_, value, child) {
        return Transform.translate(
          // Moves up by 120 pixels as value goes from 0 to 1
          offset: Offset(0, -120 * value),
          child: Opacity(
            // Fades out as value approaches 1
            opacity: 1.0 - value,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: 48,
          fontWeight: .w900,
          color: color,
          letterSpacing: 2,
          shadows: const [
            Shadow(color: Colors.black87, offset: Offset(2, 4), blurRadius: 4),
            Shadow(
              color: Colors.black87,
              offset: Offset(-2, -2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
