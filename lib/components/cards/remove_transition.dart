import 'package:flutter/material.dart';
import '../../models/uno_card.dart';
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
      axisAlignment: -1.0,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(0, -0.8),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInBack)),
        ),
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation.drive(Tween<double>(begin: 0.6, end: 1.0)),
            child: Align(
              alignment: .bottomCenter,
              child: CardFront(card: removedCard),
            ),
          ),
        ),
      ),
    );
  }
}
