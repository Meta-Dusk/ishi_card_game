import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game/game_manager.dart';

class OpponentStats extends StatelessWidget {
  const OpponentStats({
    super.key,
    required this.manager,
    required this.index,
    required this.handSize,
  });

  final GameManager manager;
  final int index;
  final int handSize;

  SizedBox get _iconSpacer => const SizedBox(width: 2);
  TextStyle get _defaultTextStyle =>
      const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: .bold);

  @override
  Widget build(BuildContext context) {
    final actionPoints = manager.actionPoints;
    final cardDraws = manager.cardDraws;
    final mainContent = [
      Tooltip(
        message: "Their remaining Action Points",
        triggerMode: .tap,
        preferBelow: true,
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 14),
            _iconSpacer,
            Text(
              "${actionPoints.length > index ? actionPoints[index] : 0}",
              style: _defaultTextStyle,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Tooltip(
        message: "Their remaining Card Draws",
        triggerMode: .tap,
        preferBelow: true,
        child: Row(
          children: [
            const Icon(Icons.style, color: Colors.blueAccent, size: 14),
            _iconSpacer,
            Text(
              "${cardDraws.length > index ? cardDraws[index] : 0}",
              style: _defaultTextStyle,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Tooltip(
        message: "Their total cards in hand",
        triggerMode: .tap,
        preferBelow: true,
        child: Row(
          children: [
            const Icon(Icons.front_hand_rounded, color: Colors.green, size: 14),
            _iconSpacer,
            Text("$handSize", style: _defaultTextStyle),
          ],
        ),
      ),
    ];
    return Row(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: mainContent,
    );
  }
}
