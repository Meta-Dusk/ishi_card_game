import 'package:flutter/material.dart';
import 'package:ishi/components/cards/mini_face_down_card.dart';

class AnimatedCardFan extends StatelessWidget {
  const AnimatedCardFan({
    super.key,
    required this.listKeys,
    required this.index,
    required this.handSize,
  });

  final Map<int, GlobalKey<AnimatedListState>> listKeys;
  final int index;
  final int handSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 130,
      alignment: .centerLeft,
      child: AnimatedList(
        key: listKeys[index + 1],
        scrollDirection: .horizontal,
        initialItemCount: handSize,
        itemBuilder: (_, index, animation) => SizeTransition(
          sizeFactor: animation,
          axis: .horizontal,
          axisAlignment: -1.0,
          child: index + 1 == handSize
              ? MiniFaceDownCard(widthFactor: 1.0)
              : const MiniFaceDownCard(),
        ),
      ),
    );
  }
}
