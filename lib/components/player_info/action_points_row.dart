import 'package:ishi/core/managers/game_manager.dart';
import 'package:flutter/material.dart';

class ActionPointsRow extends StatelessWidget {
  const ActionPointsRow({super.key, required this.manager});

  final GameManager manager;

  bool get isOutOfAp => manager.actionPoints[manager.currentPlayer - 1] <= 0;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "ACTIONS: ",
        style: TextStyle(
          fontWeight: .w900,
          color: Colors.grey,
          letterSpacing: 1,
        ),
      ),
      ..._generateAP(),
      if (isOutOfAp) endOfTurnIndicator(),
    ];
    return Row(children: mainContent);
  }

  Text endOfTurnIndicator() {
    return const Text(
      " 0 (End your turn)",
      style: TextStyle(color: Colors.redAccent, fontWeight: .bold),
    );
  }

  /// Dynamically draws lightning bolts based on AP.
  List<Widget> _generateAP() {
    return List.generate(
      manager.actionPoints[manager.currentPlayer - 1],
      (index) => const Icon(Icons.bolt, color: Colors.amber, size: 24),
    );
  }
}
