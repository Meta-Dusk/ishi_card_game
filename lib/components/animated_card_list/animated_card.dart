import 'package:ishi/core/models/deck_event.dart';

import 'animated_card_builder.dart';
import 'package:ishi/components/cards/card_display.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:flutter/material.dart';

class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    super.key,
    required this.scrollController,
    required this.card,
    required this.index,
    required this.totalCards,
    required this.onTapCard,
    required this.isMyTurn,
    required this.isSelected,
    required this.event,
  });

  final ScrollController? scrollController;
  final IshiCard card;
  final int index;
  final int totalCards;
  final void Function(IshiCard) onTapCard;
  final bool isMyTurn;
  final bool isSelected;
  final DeckEventEffect event;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      maxWidth: 160.0,
      maxHeight: 300.0,
      child: scrollController == null
          ? CardFront(card: card)
          : _animatedCardView(),
    );
  }

  AnimatedBuilder _animatedCardView() => AnimatedBuilder(
    animation: scrollController!,
    builder: (_, _) => AnimatedCardBuilder(
      scrollController: scrollController!,
      index: index,
      totalCards: totalCards,
      card: card,
      onTapCard: onTapCard,
      isMyTurn: isMyTurn,
      isSelected: isSelected,
      event: event,
    ),
  );
}
