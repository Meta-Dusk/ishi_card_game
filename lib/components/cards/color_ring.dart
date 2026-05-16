import 'package:flutter/material.dart';

class ColorRing extends StatelessWidget {
  /// Creates the 4-color ring for Wild cards
  const ColorRing({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: .circle,
        // Use hard stops to create discrete color blocks instead of a blend
        gradient: SweepGradient(
          colors: [
            Colors.red,
            Colors.red,
            Colors.blue,
            Colors.blue,
            Colors.amber,
            Colors.amber,
            Colors.green,
            Colors.green,
          ],
          stops: [
            0.0, 0.25, // Red quadrant
            0.25, 0.5, // Blue quadrant
            0.5, 0.75, // Amber quadrant
            0.75, 1.0, // Green quadrant
          ],
        ),
      ),
      // The inner black circle makes it look like a hollow ring
      child: Padding(
        padding: .all(size * 0.15),
        child: Container(
          decoration: const BoxDecoration(
            shape: .circle,
            color: Colors.black, // Matches the wild card background
          ),
        ),
      ),
    );
  }
}
