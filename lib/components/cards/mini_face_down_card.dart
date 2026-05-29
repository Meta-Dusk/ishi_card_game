import 'package:flutter/material.dart';

class MiniFaceDownCard extends StatelessWidget {
  const MiniFaceDownCard({super.key, this.scale = 1.0});

  final double scale;

  @override
  Widget build(BuildContext context) => Container(
    width: 30 * scale,
    height: 45 * scale,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: .circular(6),
      border: .all(color: Colors.grey.shade900, width: 1.5),
    ),
    alignment: .center,
    child: Text(
      "ISHI",
      style: TextStyle(
        color: Colors.white,
        letterSpacing: 2,
        fontSize: 8 * scale,
      ),
    ),
  );
}
