import 'package:flutter/material.dart';
import '../models/uno_card.dart';
import 'card_display.dart';

class RemoveTransition extends StatelessWidget {
  const RemoveTransition({
    super.key,
    required this.removedCard,
    required this.animation,
  });

  final UnoCard removedCard;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      axis: .horizontal,
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const .only(right: 8.0, bottom: 12.0),
          child: CardFront(card: removedCard),
        ),
      ),
    );
  }
}
