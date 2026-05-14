import 'package:ishi/components/cards/card_display.dart';
import 'package:ishi/models/uno_card.dart';
import 'package:flutter/material.dart';

class DraggableCard extends StatelessWidget {
  const DraggableCard({
    super.key,
    required this.card,
    required this.cardUI,
    required this.isMyTurn,
  });

  final IshiCard card;
  final Widget cardUI;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<IshiCard>(
      data: card,
      delay: const Duration(milliseconds: 150),
      maxSimultaneousDrags: (card.isFaceUp && isMyTurn) ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.25, child: CardFront(card: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardUI),
      child: cardUI,
    );
  }
}
