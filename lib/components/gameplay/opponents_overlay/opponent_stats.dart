import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';

class OpponentStats extends StatelessWidget {
  const OpponentStats({
    super.key,
    required this.manager,
    required this.index,
    required this.handSize,
  });

  final GameManager manager;
  final int index;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    final actionPoints = manager.actionPoints;
    final mainContent = [
      Tooltip(
        message: "Their remaining Action Points",
        triggerMode: .tap,
        preferBelow: true,
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              "${actionPoints.length > index ? actionPoints[index] : 0}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: .bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Tooltip(
        message: "Their total cards in hand",
        triggerMode: .tap,
        preferBelow: true,
        child: Row(
          children: [
            Icon(
              Icons.front_hand_rounded,
              color: Colors.blue.shade800,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              "$handSize",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: .bold,
              ),
            ),
          ],
        ),
      ),
    ];
    return Row(children: mainContent);
  }
}
