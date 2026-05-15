import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/screens/game_screen/mini_face_down_card.dart';
import 'package:ishi/services/network_service.dart';

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
          index: i,
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
    required this.index,
    required this.handSize,
    required this.listKeys,
  });

  final String name;
  final bool isTurn;
  final GameManager manager;
  final int index;
  final int handSize;
  final Map<int, GlobalKey<AnimatedListState>> listKeys;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      _OpponentStatsColumn(
        isTurn: isTurn,
        name: name,
        manager: manager,
        index: index,
        handSize: handSize,
      ),
      const SizedBox(width: 12),
      _AnimatedCardFan(listKeys: listKeys, index: index, handSize: handSize),
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
    required this.index,
    required this.handSize,
  });

  final bool isTurn;
  final String name;
  final GameManager manager;
  final int index;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Row(
        children: [
          if (isTurn) const _AnimatedTurnArrow(),
          if (isTurn) const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: isTurn ? Colors.orangeAccent : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      _OpponentStats(manager: manager, index: index, handSize: handSize),
    ];
    return Column(crossAxisAlignment: .end, children: mainContent);
  }
}

class _OpponentStats extends StatelessWidget {
  const _OpponentStats({
    required this.manager,
    required this.index,
    required this.handSize,
  });

  final GameManager manager;
  final int index;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    final actionPoints = manager.actionPoints;
    final mainContent = [
      const Icon(Icons.bolt, color: Colors.amber, size: 14),
      Text(
        "${actionPoints.length > index ? actionPoints[index] : 0}",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: .bold,
        ),
      ),
      const SizedBox(width: 8),
      const Icon(Icons.style, color: Colors.blueAccent, size: 14),
      Text(
        "$handSize",
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: .bold,
        ),
      ),
    ];
    return Row(children: mainContent);
  }
}

class _AnimatedCardFan extends StatelessWidget {
  const _AnimatedCardFan({
    required this.listKeys,
    required this.index,
    required this.handSize,
  });

  final Map<int, GlobalKey<AnimatedListState>> listKeys;
  final int index;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 130,
      alignment: .centerLeft,
      child: AnimatedList(
        key: listKeys[index + 1],
        scrollDirection: .horizontal,
        initialItemCount: handSize,
        itemBuilder: (_, index, animation) => SizeTransition(
          sizeFactor: animation,
          axis: .horizontal,
          axisAlignment: -1.0,
          child: index + 1 == handSize
              ? MiniFaceDownCard(widthFactor: 1.0)
              : const MiniFaceDownCard(),
        ),
      ),
    );
  }
}

class _AnimatedTurnArrow extends StatefulWidget {
  const _AnimatedTurnArrow();

  @override
  State<_AnimatedTurnArrow> createState() => _AnimatedTurnArrowState();
}

class _AnimatedTurnArrowState extends State<_AnimatedTurnArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.translate(
        offset: Offset(_controller.value * -6.0, 0),
        child: child,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.orangeAccent, size: 20),
    );
  }
}
