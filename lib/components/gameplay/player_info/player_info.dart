import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game/game_manager.dart';
import 'package:ishi/services/network_service.dart';
import 'player_stats.dart';

class PlayerInfo extends StatelessWidget {
  const PlayerInfo({super.key, required this.manager, required this.network});

  final GameManager manager;
  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(16.0),
      child: Row(
        children: [PlayerStats(manager: manager, network: network)],
      ),
    );
  }
}
