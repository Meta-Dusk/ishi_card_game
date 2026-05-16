import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game_manager.dart';

class HandControls extends StatelessWidget {
  const HandControls({
    super.key,
    required this.onEndTurn,
    required this.onFlipAllCard,
    required this.onSortHand,
    required this.onTakePenalty,
    required this.onToggleAutoSort,
    required this.manager,
    required this.isMyTurn,
  });

  final VoidCallback onFlipAllCard;
  final VoidCallback onEndTurn;
  final void Function(DeckSortType) onSortHand;
  final VoidCallback onTakePenalty;
  final VoidCallback onToggleAutoSort;
  final GameManager manager;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final bool hasActed = manager.hasPlayedCard || manager.hasDrawnCard;
    final int playerIndex = manager.currentPlayer - 1;
    final bool isUnderAttack =
        manager.pendingDrawCount > 0 &&
        !manager.hasDeflected &&
        manager.actionPoints[playerIndex] > 0;

    final mainContent = [
      Row(
        mainAxisSize: .min,
        children: [
          PopupMenuButton<DeckSortType>(
            icon: const Icon(Icons.sort),
            tooltip: "Sort Hand by ...",
            initialValue: manager.handSortType,
            iconColor: Colors.white,
            onSelected: onSortHand,
            itemBuilder: (_) => const [
              PopupMenuItem(value: .byColor, child: Text("Sort by Color")),
              PopupMenuItem(value: .byType, child: Text("Sort by Type")),
              PopupMenuItem(value: .byValue, child: Text("Sort by Value")),
              PopupMenuItem(value: .unsorted, child: Text("Unsorted")),
            ],
          ),
          IconButton(
            onPressed: onToggleAutoSort,
            icon: Icon(
              manager.isAutoSortEnabled ? Icons.sync : Icons.sync_disabled,
              color: manager.isAutoSortEnabled
                  ? Colors.greenAccent
                  : Colors.grey,
            ),
            tooltip: manager.isAutoSortEnabled
                ? "Auto-Sort: ON"
                : "Auto-Sort: OFF",
          ),
        ],
      ),
      TextButton.icon(
        onPressed: onFlipAllCard,
        icon: const Icon(Icons.flip, color: Colors.white),
        label: const Text("Flip Hand", style: TextStyle(color: Colors.white)),
      ),
      if (isMyTurn) _getTurnButton(isUnderAttack, hasActed),
    ];
    return Padding(
      padding: const .symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(mainAxisAlignment: .spaceBetween, children: mainContent),
    );
  }

  StatelessWidget _getTurnButton(bool isUnderAttack, bool hasActed) =>
      isUnderAttack
      ? _TakePenaltyButton(
          onTakePenalty: onTakePenalty,
          pendingDrawCount: manager.pendingDrawCount,
        )
      : _EndTurnButton(hasActed: hasActed, onEndTurn: onEndTurn);
}

class _EndTurnButton extends StatelessWidget {
  const _EndTurnButton({required this.hasActed, required this.onEndTurn});

  final bool hasActed;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: hasActed ? onEndTurn : null,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey.shade300.withValues(alpha: 0.5),
        disabledForegroundColor: Colors.grey.shade700.withValues(alpha: 0.5),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        textStyle: TextStyle(color: Colors.white),
      ),
      child: const Text("End Turn"),
    );
  }
}

class _TakePenaltyButton extends StatelessWidget {
  const _TakePenaltyButton({
    required this.onTakePenalty,
    required this.pendingDrawCount,
  });

  final VoidCallback onTakePenalty;
  final int pendingDrawCount;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.shade700,
        foregroundColor: Colors.white,
        padding: const .symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: onTakePenalty,
      icon: const Icon(Icons.warning_rounded),
      label: Text(
        "TAKE +$pendingDrawCount HIT",
        style: const TextStyle(fontWeight: .bold, fontSize: 16),
      ),
    );
  }
}
