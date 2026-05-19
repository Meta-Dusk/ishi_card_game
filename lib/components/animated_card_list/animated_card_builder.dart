import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'animated_card_list.dart';
import 'draggable_card.dart';
import 'package:ishi/components/cards/card_display.dart';
import 'package:ishi/components/cards/flip_card.dart';
import 'package:ishi/models/ishi_card.dart';

class AnimatedCardBuilder extends StatelessWidget {
  const AnimatedCardBuilder({
    super.key,
    required this.scrollController,
    required this.index,
    required this.totalCards,
    required this.card,
    required this.onTapCard,
    required this.isMyTurn,
    required this.isSelected,
  });

  final ScrollController scrollController;
  final int index;
  final int totalCards;
  final IshiCard card;
  final void Function(IshiCard) onTapCard;
  final bool isMyTurn;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${card.id}_tween'),
      tween: Tween<double>(end: index.toDouble()),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (_, value, _) => _animatedCardBuilder(animatedIndex: value),
    );
  }

  Widget _animatedCardBuilder({required double animatedIndex}) {
    double offset = 0.0;
    if (scrollController.hasClients && scrollController.positions.length == 1) {
      offset = scrollController.offset;
    }

    // --- MATH FOUNDATIONS ---
    final double centerIndex = offset / itemWidth;
    // Use the animatedIndex for all physical calculations!
    final double distFromCenter = animatedIndex - centerIndex;
    final int activeIndex = (offset / itemWidth).round();

    // Keep the raw integer index for user interaction logic
    final bool isCenter = index == activeIndex;

    // Parabola Drop & Rotation
    final double highlightFactor = (1.0 - distFromCenter.abs()).clamp(0.0, 1.0);

    final double curveMultiplier = totalCards > 7 ? 25.0 / totalCards : 6.0;

    final double rotation = (distFromCenter * 0.15) * (1.0 - highlightFactor);

    final double baseOffsetY =
        (distFromCenter * distFromCenter) * curveMultiplier;
    final double offsetY = baseOffsetY - (40.0 * highlightFactor);

    // X-Axis Push
    double pushFactor = distFromCenter.abs().clamp(0.0, 1.0);
    double offsetX = distFromCenter.sign * 45.0 * pushFactor;

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

    final interactableCard = GestureDetector(
      onTap: () {
        scrollController.animateTo(
          index * itemWidth,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      },
      child: Opacity(
        opacity: opacity,
        child: AbsorbPointer(child: cardUI),
      ),
    );

    final draggableCard = DraggableCard(
      card: card,
      cardUI: cardUI,
      isMyTurn: isMyTurn,
    );

    Widget cardView = isCenter ? draggableCard : interactableCard;

    if (isSelected) cardView = _applySelectionEffect(draggableCard);

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(scale: scale, child: cardView),
      ),
    );
  }

  Animate _applySelectionEffect(Widget child) => child
      .animate(onPlay: (controller) => controller.repeat(reverse: true))
      .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.4))
      .boxShadow(
        begin: const BoxShadow(color: Colors.transparent),
        end: BoxShadow(
          color: Colors.amberAccent.withValues(alpha: 0.4),
          blurRadius: 16,
          spreadRadius: 4,
        ),
      )
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        curve: Curves.easeInOut,
      );
}
