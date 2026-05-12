import 'package:flutter/material.dart';

class RoomCodeView extends StatelessWidget {
  final String? roomCode;

  const RoomCodeView({super.key, required this.roomCode});

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "ROOM CODE",
        style: TextStyle(
          color: Colors.white54,
          fontSize: 14,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 8),
      SelectableText(
        // Lets users copy it easily!
        roomCode ?? "???",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: .bold,
          letterSpacing: 12,
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const .symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: .circular(16),
        border: .all(color: Colors.white24, width: 2),
      ),
      child: Column(children: mainContent),
    );
  }
}
