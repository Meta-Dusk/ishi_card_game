import 'package:flutter/material.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'curved_card.dart';
import 'package:ishi/core/models/ishi_card.dart';

const double itemWidth = 80.0;

class AnimatedCardList extends StatelessWidget {
  const AnimatedCardList({
    super.key,
    required this.animatedListKey,
    required this.currentHand,
    required this.onTapCard,
    required this.scrollController,
    required this.isMyTurn,
    this.selectedCards = const [],
    required this.event,
  });

  final void Function(IshiCard) onTapCard;
  final Key? animatedListKey;
  final ScrollController? scrollController;
  final List<IshiCard> currentHand;
  final bool isMyTurn;
  final List<IshiCard> selectedCards;
  final DeckEventEffect event;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final controller = scrollController;
      if (controller == null || !controller.hasClients) return false;
      final offset = controller.offset;
      final target = (offset / itemWidth).round() * itemWidth;

      if ((offset - target).abs() <= 1.0) return false;
      Future.microtask(
        () => controller.animateTo(
          target,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
        ),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth / 2) - (itemWidth / 2);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: AnimatedList(
        key: animatedListKey,
        controller: scrollController,
        scrollDirection: .horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: .none,
        padding: .symmetric(horizontal: horizontalPadding, vertical: 20),
        initialItemCount: currentHand.length,
        itemBuilder: (_, index, animation) {
          if (index >= currentHand.length) return const SizedBox.shrink();
          final card = currentHand[index];
          return CurvedCard(
            key: ValueKey(card.id),
            index: index,
            animation: animation,
            card: card,
            totalCards: currentHand.length,
            scrollController: scrollController,
            onTapCard: onTapCard,
            isMyTurn: isMyTurn,
            isSelected: selectedCards.contains(card),
            event: event,
          );
        },
      ),
    );
  }
}
