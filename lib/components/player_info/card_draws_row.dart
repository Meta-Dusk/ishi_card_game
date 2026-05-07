import 'package:esther_gift/managers/game_manager.dart';
import 'package:flutter/material.dart';

class CardDrawsRow extends StatelessWidget {
  const CardDrawsRow({super.key, required this.manager});

  final GameManager manager;

  bool get isOutOfCd => manager.cardDraws[manager.currentPlayer - 1] <= 0;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const SizedBox(
        width: 70,
        child: Text(
          "DRAWS: ",
          style: TextStyle(
            fontWeight: .w900,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      ),
      ..._generateCD(),
      if (isOutOfCd) endOfTurnIndicator(),
    ];
    return Row(children: mainContent);
  }

  Text endOfTurnIndicator() {
    return const Text(
      " 0",
      style: TextStyle(color: Colors.redAccent, fontWeight: .bold),
    );
  }

  /// Dynamically draws card draws based on CD.
  List<Widget> _generateCD() {
    return List.generate(
      manager.cardDraws[manager.currentPlayer - 1],
      (index) => const Icon(Icons.style, color: Colors.blueAccent, size: 20),
    );
  }
}
