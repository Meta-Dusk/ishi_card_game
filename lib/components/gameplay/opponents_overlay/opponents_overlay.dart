import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/services/network_service.dart';
import 'animated_card_fan.dart';
import 'animated_turn_arrow.dart';
import 'opponent_stats.dart';

class OpponentsOverlay extends StatefulWidget {
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
  State<OpponentsOverlay> createState() => _OpponentsOverlayState();
}

class _OpponentsOverlayState extends State<OpponentsOverlay> {
  final ScrollController _scrollController = ScrollController();
  int _lastTurn = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant OpponentsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-Scroll Logic: Check if the turn has changed!
    if (widget.manager.currentPlayer != _lastTurn) {
      _lastTurn = widget.manager.currentPlayer;

      // Wait for the frame to render before calculating the scroll position
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentPlayer();
      });
    }
  }

  void _scrollToCurrentPlayer() {
    if (!_scrollController.hasClients) return;

    int opponentIndex = -1;
    int drawnIndex = 0;

    // Find out which slot the current player occupies in the UI list
    for (int i = 0; i < widget.manager.playerCount; i++) {
      if (i == widget.manager.localPlayerIndex) continue;
      if ((i + 1) == widget.manager.currentPlayer) {
        opponentIndex = drawnIndex;
        break;
      }
      drawnIndex++;
    }

    if (opponentIndex != -1) {
      double targetOffset = opponentIndex * 61.0;
      final maxScroll = _scrollController.position.maxScrollExtent;

      if (targetOffset > maxScroll) targetOffset = maxScroll;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collect valid opponent indices (skipping the local player)
    List<int> opponentIndices = [];
    for (int i = 0; i < widget.manager.playerCount; i++) {
      if (i == widget.manager.localPlayerIndex) continue;
      opponentIndices.add(i);
    }

    return Container(
      width: 300,
      height: 120,
      margin: const .only(right: 16, top: 16, bottom: 16),
      alignment: .centerRight,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: .vertical,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemExtent: 61.0,
        itemCount: opponentIndices.length,
        itemBuilder: (context, listIndex) {
          int i = opponentIndices[listIndex];

          String name = "Player ${i + 1}";
          if (i < widget.net.playersList.length) {
            name = widget.net.playersList[i].playerName;
          }

          // Safe hand count
          int handSize = 0;
          if (widget.net.isHost) {
            handSize = widget.manager.playerHands[i].length;
          } else if (widget.manager.opponentHandSizes.length > i) {
            handSize = widget.manager.opponentHandSizes[i];
          }

          bool isTurn = widget.manager.currentPlayer == (i + 1);

          return Padding(
            padding: const .only(bottom: 16.0),
            child: Row(
              mainAxisSize: .min,
              mainAxisAlignment: .end,
              children: [
                _OpponentStatsColumn(
                  isTurn: isTurn,
                  name: name,
                  manager: widget.manager,
                  playerIndex: i,
                  handSize: handSize,
                ),
                const SizedBox(width: 12),
                AnimatedCardFan(
                  listKeys: widget.listKeys,
                  index: i,
                  handSize: handSize,
                ),
              ],
            ),
          );
        },
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

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .end,
      children: mainContent,
    );
  }
}
