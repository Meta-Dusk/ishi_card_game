import 'package:flutter/material.dart';

class OutlineCard extends StatelessWidget {
  final Color color;

  const OutlineCard({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25,
      height: 35,
      decoration: BoxDecoration(
        border: .all(color: color, width: 2),
        borderRadius: .circular(4),
        color: Colors.transparent,
      ),
    );
  }
}
