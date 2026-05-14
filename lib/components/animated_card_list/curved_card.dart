import 'package:flutter/material.dart';
import 'animated_card.dart';
import 'animated_card_list.dart';
import 'package:ishi/models/uno_card.dart';

class CurvedCard extends StatelessWidget {
  const CurvedCard({
    super.key,
    required this.index,
    required this.animation,
    required this.card,
    required this.totalCards,
    required this.scrollController,
    required this.onTapCard,
    required this.isMyTurn,
  });

  final int index;
  final int totalCards;
  final IshiCard card;
  final Animation<double> animation;
  final ScrollController? scrollController;
  final void Function(IshiCard) onTapCard;
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    final slideAnimation = animation.drive(
      Tween<Offset>(
        begin: const Offset(0, -0.8),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) => Align(
        alignment: .center,
        widthFactor: animation.value,
        child: SizedBox(
          width: itemWidth,
          child: SlideTransition(
            position: slideAnimation,
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
      ),
      child: AnimatedCard(
        scrollController: scrollController,
        card: card,
        index: index,
        totalCards: totalCards,
        onTapCard: onTapCard,
        isMyTurn: isMyTurn,
      ),
    );
  }
}
