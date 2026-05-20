import 'package:ishi/components/animated_card_list/animated_card_list.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:flutter/material.dart';
import 'card_display.dart';

class RemoveTransition extends StatelessWidget {
  const RemoveTransition({
    super.key,
    required this.removedCard,
    required this.animation,
  });

  final IshiCard removedCard;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final slideTransition = SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0.2, -1.5),
          end: const Offset(0, -0.4),
        ).chain(CurveTween(curve: Curves.easeInExpo)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: CardFront(card: removedCard),
      ),
    );

    return Align(
      alignment: .bottomCenter,
      widthFactor: animation.value * 0.7,
      child: SizedBox(
        width: itemWidth,
        child: OverflowBox(
          maxWidth: 160.0,
          maxHeight: 300.0,
          alignment: .bottomCenter,
          child: slideTransition,
        ),
      ),
    );
  }
}
