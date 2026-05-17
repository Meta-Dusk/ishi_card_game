import 'package:flutter/material.dart';

class GameTitle extends StatelessWidget {
  const GameTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final innerText = const Text(
      "ISHI",
      style: TextStyle(
        fontSize: 80,
        fontWeight: .w900,
        letterSpacing: 16,
        color: Colors.white,
      ),
    );

    final outerText = Text(
      "ISHI",
      style: TextStyle(
        fontSize: 80,
        fontWeight: .w900,
        letterSpacing: 16,
        foreground: Paint()
          ..style = .stroke
          ..strokeWidth = 8.0
          ..color = Colors.black,
      ),
    );

    return Stack(children: [outerText, innerText]);
  }
}
