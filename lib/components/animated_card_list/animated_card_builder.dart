import 'animated_card_list.dart';
import 'draggable_card.dart';
import '../cards/card_display.dart';
import '../cards/flip_card.dart';
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
    if (scrollController.hasClients) offset = scrollController.offset;

    // --- MATH FOUNDATIONS ---
    final double centerIndex = offset / itemWidth;
    final double distFromCenter = index - centerIndex;
    final int activeIndex = (offset / itemWidth).round();
    final bool isCenter = index == activeIndex;

    // THE WAVE: Goes from 1.0 (perfectly centered) down to 0.0 (one slot away)
    // This allows the highlight effect to trigger smoothly as you scroll!
    final double highlightFactor = (1.0 - distFromCenter.abs()).clamp(0.0, 1.0);

    final double curveMultiplier = totalCards > 7 ? 25.0 / totalCards : 6.0;

    // Smoothly straightens out to 0.0 as it reaches the center!
    final double rotation = (distFromCenter * 0.15) * (1.0 - highlightFactor);

    // Y-AXIS (Pop Up): Combines the parabola curve with a 40px upward slide!
    final double baseOffsetY =
        (distFromCenter * distFromCenter) * curveMultiplier;
    final double offsetY = baseOffsetY - (40.0 * highlightFactor);

    // X-AXIS (Parting the Sea): Pushes inactive cards left and right
    double pushFactor = distFromCenter.abs().clamp(0.0, 1.0);
    double offsetX = distFromCenter.sign * 60.0 * pushFactor;

    // Smooth Scale & Opacity Gradients
    double scale = 1.15 - (distFromCenter.abs() * 0.15);
    scale = scale.clamp(0.7, 1.25);

    double opacity = 1.0 - (distFromCenter.abs() * 0.35);
    opacity = opacity.clamp(0.4, 1.0);

    final Widget cardUI = FlipCard(
      key: ValueKey('${card.id}_flip'),
      isFaceUp: card.isFaceUp,
      onTap: () => onTapCard(card),
      front: CardFront(card: card),
      back: const CardBack(),
    );

    final gestureDetector = GestureDetector(
      onTap: () => scrollController.animateTo(
        index * itemWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ),
      child: Opacity(
        opacity: opacity, // Smooth gradient fade
        child: AbsorbPointer(child: cardUI),
      ),
    );

    final cardView = isCenter
        ? DraggableCard(card: card, cardUI: cardUI)
        : gestureDetector;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: scale, child: cardView),
      ),
    );
  }
}
