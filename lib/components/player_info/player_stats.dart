import 'package:flutter/material.dart';
import 'package:ishi/services/network_service.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'action_points_row.dart';
import 'card_draws_row.dart';

class PlayerStats extends StatelessWidget {
  const PlayerStats({super.key, required this.manager, required this.network});

  final GameManager manager;
  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = network.playersList[network.currentPlayer];
    final mainContent = [
      Text(
        "Player ${currentPlayer.playerName}'s Turn",
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
