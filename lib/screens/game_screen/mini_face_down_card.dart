import 'package:flutter/material.dart';

class MiniFaceDownCard extends StatelessWidget {
  const MiniFaceDownCard({super.key, this.widthFactor = 0.6});

  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: widthFactor,
      alignment: .centerLeft,
      child: Container(
        width: 30,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: .circular(6),
          border: .all(color: Colors.grey.shade900, width: 1.5),
        ),
        alignment: .center,
        child: Text(
          "IS",
          style: TextStyle(color: Colors.white, letterSpacing: 2),
        ),
      ),
    );
  }
}
