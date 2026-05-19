import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';
import 'animated_card_fan.dart';
import 'animated_turn_arrow.dart';
import 'opponent_stats.dart';

class OpponentsOverlay extends StatelessWidget {
  const OpponentsOverlay({
    super.key,
    required this.manager,
    required this.net,
    required this.listKeys,
  });

  final GameManager manager;
  final NetworkService net;
  final Map<int, GlobalKey<AnimatedListState>> listKeys;

  @override
  Widget build(BuildContext context) {
    List<Widget> rows = [];
    for (int i = 0; i < manager.playerCount; i++) {
      if (i == manager.localPlayerIndex) continue;

      String name = "Player ${i + 1}";
      if (i < net.playersList.length) name = net.playersList[i].playerName;

      // Safe hand count
      int handSize = 0;
      if (net.isHost) {
        handSize = manager.playerHands[i].length;
      } else if (manager.opponentHandSizes.length > i) {
        handSize = manager.opponentHandSizes[i];
      }

      bool isTurn = manager.currentPlayer == (i + 1);

      rows.add(
        _OpponentOverlayRow(
          name: name,
          isTurn: isTurn,
          manager: manager,
          playerIndex: i,
          handSize: handSize,
          listKeys: listKeys,
        ),
      );
    }

    return Column(crossAxisAlignment: .end, children: rows);
  }
}

class _OpponentOverlayRow extends StatelessWidget {
  const _OpponentOverlayRow({
    required this.name,
    required this.isTurn,
    required this.manager,
    required this.playerIndex,
    required this.handSize,
    required this.listKeys,
  });

  final String name;
  final bool isTurn;
  final GameManager manager;
  final int playerIndex;
  final int handSize;
  final Map<int, GlobalKey<AnimatedListState>> listKeys;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      _OpponentStatsColumn(
        isTurn: isTurn,
        name: name,
        manager: manager,
        playerIndex: playerIndex,
        handSize: handSize,
      ),
      const SizedBox(width: 12),
      AnimatedCardFan(
        listKeys: listKeys,
        index: playerIndex,
        handSize: handSize,
      ),
    ];

    return Container(
      margin: const .only(bottom: 16),
      child: Row(
        mainAxisSize: .min,
        crossAxisAlignment: .center,
        children: mainContent,
      ),
    );
  }
}

class _OpponentStatsColumn extends StatelessWidget {
  const _OpponentStatsColumn({
    required this.isTurn,
    required this.name,
    required this.manager,
    required this.playerIndex,
    required this.handSize,
  });

  final bool isTurn;
  final String name;
  final GameManager manager;
  final int playerIndex;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Row(
        children: [
          if (isTurn) const AnimatedTurnArrow(),
          if (isTurn) const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: isTurn ? Colors.orangeAccent : Colors.white,
              fontWeight: .bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      OpponentStats(manager: manager, index: playerIndex, handSize: handSize),
    ];
    return Column(crossAxisAlignment: .end, children: mainContent);
  }
}
