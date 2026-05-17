import 'package:flutter/material.dart';

class GameSubtitle extends StatelessWidget {
  const GameSubtitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "The Unolike roguelike\ncard game.",
      textAlign: .center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: .w400,
        letterSpacing: 2.5,
        color: Colors.black,
        height: 1.4,
      ),
    );
  }
}
