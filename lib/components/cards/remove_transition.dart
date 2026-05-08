import 'package:esther_gift/models/uno_card.dart';
import 'package:flutter/material.dart';
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
    return Align(
      alignment: .center,
      widthFactor: 0.7 * animation.value,
      child: SizedBox(
        width: 120,
        child: SlideTransition(
          position: animation.drive(
            Tween<Offset>(
              begin: const Offset(0, -0.8),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOut)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: CardFront(card: removedCard),
          ),
        ),
      ),
    );
  }
}
