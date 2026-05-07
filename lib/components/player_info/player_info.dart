import 'package:flutter/material.dart';
import 'package:esther_gift/managers/game_manager.dart';
import 'player_stats.dart';
import 'relic_bar.dart';

class PlayerInfo extends StatelessWidget {
  const PlayerInfo({super.key, required this.manager});

  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .all(16.0),
      child: Row(
        mainAxisAlignment: .spaceBetween,
        children: [
          PlayerStats(manager: manager),
          // const Chip(
          //   avatar: Icon(Icons.shield, size: 16),
          //   label: Text("Shield Active"),
          // ),
          RelicBar(manager: manager),
        ],
      ),
    );
  }
}
