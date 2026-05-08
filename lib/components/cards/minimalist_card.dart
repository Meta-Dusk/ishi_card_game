import 'dart:math' as math;
import 'package:flutter/material.dart';

class MinimalistCard extends StatelessWidget {
  final Color cardColor;
  final Widget centerWidget;
  final Widget cornerWidget;
  final double width;
  final double height;

  const MinimalistCard({
    super.key,
    required this.cardColor,
    required this.centerWidget,
    required this.cornerWidget,
    this.width = 120,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      TopLeftCorner(child: cornerWidget),
      Center(child: centerWidget),
      BottomRightCorner(child: cornerWidget),
    ];

    final boxDecoration = BoxDecoration(
      color: cardColor,
      borderRadius: .circular(12), // Slight rounding
      boxShadow: const [
        BoxShadow(color: Colors.black26, offset: Offset(2, 4), blurRadius: 4),
      ],
    );

    return Container(
      width: width,
      height: height,
      decoration: boxDecoration,
      child: Stack(children: mainContent),
    );
  }
}

class BottomRightCorner extends StatelessWidget {
  const BottomRightCorner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 10,
      right: 10,
      child: Transform.rotate(
        angle: math.pi, // 180 degrees
        child: child,
      ),
    );
  }
}

class TopLeftCorner extends StatelessWidget {
  const TopLeftCorner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(top: 10, left: 10, child: child);
  }
}
