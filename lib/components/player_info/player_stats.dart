import 'action_points_row.dart';
import 'card_draws_row.dart';
import 'package:esther_gift/managers/game_manager.dart';
import 'package:flutter/material.dart';

class PlayerStats extends StatelessWidget {
  const PlayerStats({super.key, required this.manager});

  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Text(
        "Player ${manager.currentPlayer}'s Turn",
        style: const TextStyle(fontSize: 24, fontWeight: .bold),
      ),
      const SizedBox(height: 4),
      ActionPointsRow(manager: manager),
      const SizedBox(height: 4),
      CardDrawsRow(manager: manager),
    ];
    return Column(crossAxisAlignment: .start, children: mainContent);
  }
}
