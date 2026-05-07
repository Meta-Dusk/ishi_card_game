import 'package:esther_gift/managers/game_manager.dart';
import 'package:flutter/material.dart';

class HandControls extends StatelessWidget {
  const HandControls({
    super.key,
    required this.onEndTurn,
    required this.onFlipAllCard,
    required this.onSortHand,
    required this.onTakePenalty,
    required this.manager,
  });

  final VoidCallback onFlipAllCard;
  final VoidCallback onEndTurn;
  final void Function(bool) onSortHand;
  final VoidCallback onTakePenalty;
  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    final bool hasActed = manager.hasPlayedCard || manager.hasDrawnCard;
    final int playerIndex = manager.currentPlayer - 1;
    final bool isUnderAttack =
        manager.pendingDrawCount > 0 &&
        !manager.hasDeflected &&
        manager.actionPoints[playerIndex] > 0;

    final mainContent = [
      PopupMenuButton<bool>(
        icon: const Icon(Icons.sort),
        tooltip: "Sort Hand",
        onSelected: (byColor) => onSortHand(byColor),
        itemBuilder: (context) => const [
          PopupMenuItem(value: true, child: Text("Sort by Color")),
          PopupMenuItem(value: false, child: Text("Sort by Value")),
        ],
      ),
      TextButton.icon(
        onPressed: onFlipAllCard,
        icon: const Icon(Icons.flip),
        label: const Text("Flip Hand"),
      ),
      isUnderAttack
          ? _TakePenaltyButton(
              onTakePenalty: onTakePenalty,
              pendingDrawCount: manager.pendingDrawCount,
            )
          : _EndTurnButton(hasActed: hasActed, onEndTurn: onEndTurn),
    ];
    return Padding(
      padding: const .symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(mainAxisAlignment: .spaceBetween, children: mainContent),
    );
  }
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
        disabledBackgroundColor: Colors.grey.shade300,
        disabledForegroundColor: Colors.grey.shade500,
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
        backgroundColor: Colors.redAccent,
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
