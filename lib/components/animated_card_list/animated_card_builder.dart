import 'animated_card_list.dart';
import 'draggable_card.dart';
import 'package:esther_gift/components/card_display.dart';
import 'package:esther_gift/components/flip_card.dart';
import 'package:esther_gift/models/uno_card.dart';
import 'package:flutter/material.dart';

class AnimatedCardBuilder extends StatelessWidget {
  const AnimatedCardBuilder({
    super.key,
    required this.scrollController,
    required this.index,
    required this.totalCards,
    required this.card,
    required this.onTapCard,
  });

  final ScrollController scrollController;
  final int index;
  final int totalCards;
  final UnoCard card;
  final void Function(UnoCard) onTapCard;

  @override
  Widget build(BuildContext context) {
    double offset = 0.0;
    if (scrollController.hasClients) {
      offset = scrollController.offset;
    }

    // Math Foundations
    final double centerIndex = offset / itemWidth;
    final double distFromCenter = index - centerIndex;

    // Calculate exactly the active index to prevent opacity flickering!
    final int activeIndex = (offset / itemWidth).round();
    final bool isCenter = index == activeIndex;

    // Parabola Drop & Rotation
    final double curveMultiplier = totalCards > 7 ? 25.0 / totalCards : 6.0;
    final double rotation = distFromCenter * 0.15;
    final double offsetY = (distFromCenter * distFromCenter) * curveMultiplier;

    // Smooth Scale & Opacity Gradients
    double scale = 1.15 - (distFromCenter.abs() * 0.15);
    scale = scale.clamp(0.7, 1.25);

    double opacity = 1.0 - (distFromCenter.abs() * 0.35);
    opacity = opacity.clamp(0.4, 1.0);

    // THE Z-INDEX FIX: "Parting the Sea"
    // Pushes inactive cards outward on the X-axis to make room for the active card
    double pushFactor = distFromCenter.abs().clamp(0.0, 1.0);
    double offsetX = distFromCenter.sign * 45.0 * pushFactor;

    final Widget cardUI = FlipCard(
      key: ValueKey('${card.id}_flip'),
      isFaceUp: card.isFaceUp,
      onTap: () => onTapCard(card),
      front: CardFront(card: card),
      back: CardBack(),
    );

    final gestureDetector = GestureDetector(
      onTap: () {
        scrollController.animateTo(
          index * itemWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },
      child: Opacity(
        opacity: opacity, // Smooth gradient fade
        child: AbsorbPointer(child: cardUI),
      ),
    );

    final cardView = isCenter
        ? DraggableCard(card: card, cardUI: cardUI)
        : gestureDetector;

    // Apply all transformations
    final transformScale = Transform.scale(scale: scale, child: cardView);
    final transformRotate = Transform.rotate(
      angle: rotation,
      child: transformScale,
    );
    return Transform.translate(
      offset: Offset(offsetX, offsetY), // Applied the new X offset!
      child: transformRotate,
    );
  }
}
