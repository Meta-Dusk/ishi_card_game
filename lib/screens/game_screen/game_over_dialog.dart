import 'package:flutter/material.dart';
import 'package:ishi/services/network_service.dart';

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.winnerName,
    required this.network,
  });

  final String winnerName;
  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: const Text(
        "GAME OVER",
        textAlign: .center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      content: Column(
        mainAxisSize: .min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          const SizedBox(height: 16),
          Text(
            "$winnerName\nWon the match!",
            textAlign: .center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: .bold,
            ),
          ),
        ],
      ),
      actionsAlignment: .center,
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.exit_to_app),
          label: const Text("RETURN TO MENU"),
          onPressed: () async {
            // Disconnect from WebRTC/LAN and pop back to the Root Menu
            await network.disconnect();
            if (!context.mounted) return;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ],
    );
  }
}
