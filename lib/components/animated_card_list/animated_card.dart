import 'animated_card_builder.dart';
import 'package:esther_gift/components/card_display.dart';
import 'package:esther_gift/models/uno_card.dart';
import 'package:flutter/material.dart';

class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    super.key,
    required this.scrollController,
    required this.card,
    required this.index,
    required this.totalCards,
    required this.onTapCard,
  });

  final ScrollController? scrollController;
  final UnoCard card;
  final int index;
  final int totalCards;
  final void Function(UnoCard) onTapCard;

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
    ),
  );
}
