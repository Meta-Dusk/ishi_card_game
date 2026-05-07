import 'package:esther_gift/components/card_display.dart';
import 'package:esther_gift/models/uno_card.dart';
import 'package:flutter/material.dart';

class DraggableCard extends StatelessWidget {
  const DraggableCard({super.key, required this.card, required this.cardUI});

  final UnoCard card;
  final Widget cardUI;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<UnoCard>(
      data: card,
      delay: const Duration(milliseconds: 150),
      maxSimultaneousDrags: card.isFaceUp ? 1 : 0,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.25, child: CardFront(card: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardUI),
      child: cardUI,
    );
  }
}
