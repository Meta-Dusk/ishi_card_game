import 'package:flutter/material.dart';

class ClientView extends StatelessWidget {
  const ClientView({
    super.key,
    required this.startingHandSize,
    required this.maxPlayers,
  });

  final int startingHandSize;
  final int maxPlayers;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Text(
        "STARTING CARDS: $startingHandSize",
        style: const TextStyle(color: Colors.orangeAccent, fontWeight: .bold),
      ),
      Text(
        "MAX PLAYERS: $maxPlayers",
        style: const TextStyle(color: Colors.greenAccent, fontWeight: .bold),
      ),
    ];

    return Container(
      padding: const .all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: .circular(12),
      ),
      child: Row(mainAxisAlignment: .spaceAround, children: mainContent),
    );
  }
}
