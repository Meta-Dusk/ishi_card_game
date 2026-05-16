import 'package:flutter/material.dart';
import 'package:ishi/services/network_service.dart';

class LeaveGameDialog extends StatelessWidget {
  const LeaveGameDialog({super.key, required this.network});

  final NetworkService network;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text("Leave Game", style: TextStyle(color: Colors.white)),
      content: const Text(
        "Are you sure you want to leave the match?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent.shade700,
          ),
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await network.disconnect(); // Alert peers
            if (!context.mounted) return;
            // Back to Main Menu
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: const Text("LEAVE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
