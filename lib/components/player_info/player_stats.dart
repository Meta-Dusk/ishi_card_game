import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';

class PlayerStats extends StatelessWidget {
  const PlayerStats({super.key, required this.manager, required this.network});

  final GameManager manager;
  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    final int localIndex = manager.localPlayerIndex;

    final int actionPoints = manager.actionPoints.length > localIndex
        ? manager.actionPoints[localIndex]
        : 0;

    final int cardDraws = manager.cardDraws.length > localIndex
        ? manager.cardDraws[localIndex]
        : 0;

    // Safely fetch the local player's name from the network profile
    String playerName = "PLAYER ${localIndex + 1}";
    if (localIndex < network.playersList.length) {
      playerName = network.playersList[localIndex].playerName;
    }

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Text(
          playerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: .bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              "$actionPoints",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: .bold,
              ),
            ),

            const SizedBox(width: 16),

            const Icon(Icons.style, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 4),
            Text(
              "$cardDraws",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: .bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
