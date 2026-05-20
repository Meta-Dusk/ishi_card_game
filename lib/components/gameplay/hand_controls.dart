import 'package:auto_size_text/auto_size_text.dart';
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

  bool get hasActed => manager.hasPlayedCard || manager.hasDrawnCard;
  int get playerIndex => manager.currentPlayer - 1;
  bool get isUnderAttack =>
      manager.pendingDrawCount > 0 &&
      !manager.hasDeflected &&
      manager.actionPoints[playerIndex] > 0;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(mainAxisAlignment: .spaceBetween, children: _mainContent),
  );

  List<Widget> get _mainContent => [
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
        _AutoSortButton(
          onPressed: onToggleAutoSort,
          isAutoSortEnabled: manager.isAutoSortEnabled,
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

  StatelessWidget _getTurnButton(bool isUnderAttack, bool hasActed) =>
      isUnderAttack
      ? _TakePenaltyButton(
          onTakePenalty: onTakePenalty,
          pendingDrawCount: manager.pendingDrawCount,
        )
      : _EndTurnButton(hasActed: hasActed, onEndTurn: onEndTurn);
}

class _AutoSortButton extends StatelessWidget {
  const _AutoSortButton({
    required this.onPressed,
    required this.isAutoSortEnabled,
  });

  final VoidCallback onPressed;
  final bool isAutoSortEnabled;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    icon: Icon(
      isAutoSortEnabled ? Icons.sync : Icons.sync_disabled,
      color: isAutoSortEnabled ? Colors.greenAccent : Colors.grey,
    ),
    tooltip: isAutoSortEnabled ? "Auto-Sort: ON" : "Auto-Sort: OFF",
  );
}

class _EndTurnButton extends StatelessWidget {
  const _EndTurnButton({required this.hasActed, required this.onEndTurn});

  final bool hasActed;
  final VoidCallback onEndTurn;

  @override
  Widget build(BuildContext context) => ElevatedButton(
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

class _TakePenaltyButton extends StatelessWidget {
  const _TakePenaltyButton({
    required this.onTakePenalty,
    required this.pendingDrawCount,
  });

  final VoidCallback onTakePenalty;
  final int pendingDrawCount;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent.shade700,
      foregroundColor: Colors.white,
      padding: const .symmetric(horizontal: 24, vertical: 12),
    ),
    onPressed: onTakePenalty,
    icon: const Icon(Icons.warning_rounded),
    label: AutoSizeText(
      "TAKE +$pendingDrawCount",
      style: const TextStyle(fontWeight: .bold, fontSize: 16),
      maxLines: 1,
      minFontSize: 10,
      overflow: .ellipsis,
    ),
  );
}
