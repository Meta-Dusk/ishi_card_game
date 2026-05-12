import 'package:flutter/material.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/services/network_service.dart';

class LivePingPanel extends StatelessWidget {
  const LivePingPanel({super.key, required this.network});

  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "NETWORK PING",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: .bold,
        ),
      ),
      const Divider(color: Colors.white24),

      ...network.playersList.map((player) {
        int ping = player.pingMs;
        Color pingColor = ping < 60
            ? Colors.greenAccent
            : (ping < 150 ? Colors.amber : Colors.redAccent);

        return _PlayerRow(player: player, pingColor: pingColor);
      }),
    ];

    return Positioned(
      top: 60,
      right: 16,
      child: Container(
        width: 220,
        padding: const .all(12),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: .circular(12),
          border: .all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: mainContent,
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.pingColor});

  final LobbyPlayer player;
  final Color pingColor;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Text(
        player.playerName,
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
      Text(
        "${player.pingMs}ms",
        style: TextStyle(color: pingColor, fontWeight: .bold, fontSize: 13),
      ),
    ];
    return Padding(
      padding: const .only(bottom: 6.0),
      child: Row(mainAxisAlignment: .spaceBetween, children: mainContent),
    );
  }
}
