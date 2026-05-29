import 'package:flutter/material.dart';
import 'package:ishi/components/cards/mini_face_down_card.dart';

class AnimatedCardFan extends StatelessWidget {
  const AnimatedCardFan({
    super.key,
    required this.listKeys,
    required this.index,
    required this.handSize,
    required this.facingAngle,
  });

  final Map<int, GlobalKey<AnimatedListState>> listKeys;
  final int index;
  final int handSize;
  final double facingAngle;

  @override
  Widget build(BuildContext context) => Transform(
    alignment: FractionalOffset.center,
    transform: .identity()
      ..setEntry(3, 2, 0.002)
      ..rotateX(-0.55)
      ..rotateZ(facingAngle),
    child: Container(
      height: 80,
      width: 180,
      alignment: .center,
      child: AnimatedList(
        key: listKeys[index + 1],
        shrinkWrap: true,
        scrollDirection: .horizontal,
        initialItemCount: handSize,
        clipBehavior: .none,
        itemBuilder: (_, itemIndex, animation) {
          double middle = handSize <= 1 ? 0.0 : (handSize - 1) / 2.0;
          double offsetFromCenter = itemIndex - middle;

          double rotationAngle = offsetFromCenter * 0.15;
          double dropY = offsetFromCenter.abs() * 2.5;

          double layoutWidth = (itemIndex + 1 == handSize) ? 1.0 : 0.5;

          return _AnimatedMiniCard(
            layoutWidth: layoutWidth,
            dropY: dropY,
            rotationAngle: rotationAngle,
            animation: animation,
          );
        },
      ),
    ),
  );
}

class _AnimatedMiniCard extends StatelessWidget {
  const _AnimatedMiniCard({
    required this.layoutWidth,
    required this.dropY,
    required this.rotationAngle,
    required this.animation,
  });

  final double layoutWidth;
  final double dropY;
  final double rotationAngle;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double responsiveScale = (size.height / 400.0).clamp(0.5, 1.1);

    return Align(
      widthFactor: layoutWidth,
      alignment: .centerLeft,
      child: SlideTransition(
        position: animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: FadeTransition(
          opacity: animation,
          child: Transform(
            alignment: FractionalOffset.bottomCenter,
            transform: .identity()
              ..translateByVector3(.new(0.0, dropY, 0.0))
              ..rotateZ(rotationAngle)
              ..scaleByVector3(.all(1.35)),
            child: MiniFaceDownCard(scale: responsiveScale),
          ),
        ),
      ),
    );
  }
}
