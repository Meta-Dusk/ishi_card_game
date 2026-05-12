import 'package:flutter/material.dart';

class CardCounter extends StatelessWidget {
  const CardCounter({super.key, required this.currentHandLength});
  final int currentHandLength;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: .circular(20),
        border: .all(color: Colors.white24),
      ),
      child: Text(
        "CARDS IN HAND: $currentHandLength",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: .bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
    );
  }
}
