import 'package:flutter/material.dart';
import 'package:ishi/models/uno_card.dart';

class AnimatedPlayButton extends StatelessWidget {
  const AnimatedPlayButton({
    super.key,
    required this.selectedCard,
    required this.isMyTurn,
    required this.onPlay,
  });

  final IshiCard? selectedCard;
  final bool isMyTurn;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final bool show = selectedCard != null && isMyTurn;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: show ? 48 : 0,
      curve: Curves.easeOutCubic,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          foregroundColor: Colors.black,
          padding: const .symmetric(horizontal: 32, vertical: 12),
        ),
        icon: Icon(
          Icons.arrow_upward_rounded,
          size: 24,
          color: show ? Colors.black : Colors.white,
        ),
        label: const Text(
          "PLAY SELECTED CARD",
          style: TextStyle(fontWeight: .bold, fontSize: 16),
        ),
        onPressed: onPlay,
      ),
    );
  }
}
