import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/models/relic.dart';
import 'package:flutter/material.dart';

class RelicBar extends StatelessWidget {
  const RelicBar({super.key, required this.manager});

  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    final int playerIndex = manager.currentPlayer - 1;
    final List<Relic> currentRelics = manager.playerRelics[playerIndex];

    final mainContent = [
      if (currentRelics.isNotEmpty)
        const Text(
          "RELICS",
          style: TextStyle(
            fontSize: 10,
            fontWeight: .bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),
      const SizedBox(height: 4),
      Wrap(
        alignment: .end,
        spacing: 6.0,
        runSpacing: 6.0,
        children: currentRelics
            .map((relic) => _RelicIcon(relic: relic))
            .toList(),
      ),
    ];
    return Expanded(
      child: Column(crossAxisAlignment: .end, children: mainContent),
    );
  }
}

class _RelicIcon extends StatelessWidget {
  const _RelicIcon({required this.relic});

  final Relic relic;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${relic.name}\n${relic.description}',
      triggerMode: .tap,
      preferBelow: true,
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: .circular(8),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: relic.color.withValues(alpha: 0.15),
        child: Icon(relic.icon, color: relic.color, size: 20),
      ),
    );
  }
}
