import 'package:flutter/material.dart';
import '../core/managers/game_manager.dart';
import '../models/uno_card.dart';
import 'cards/card_display.dart';

class PlayAndPileDeck extends StatelessWidget {
  const PlayAndPileDeck({
    super.key,
    required this.manager,
    required this.onDrawCard,
    required this.onPlayCard,
  });

  final GameManager manager;
  final VoidCallback onDrawCard;
  final void Function(IshiCard) onPlayCard;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      _AvailableCardsPile(
        onDrawCard: onDrawCard,
        deckLength: manager.deck.length,
      ),
      const SizedBox(width: 20),
      _PlayCardsPile(manager: manager, onPlayCard: onPlayCard), // DragTarget
    ];

    final stackedContent = [
      // The Turn Direction Background
      _CardAnimatedRotation(manager: manager),
      Row(mainAxisAlignment: .center, children: mainContent),
    ];
    return Stack(alignment: .center, children: stackedContent);
  }
}

class _PlayCardsPile extends StatelessWidget {
  const _PlayCardsPile({required this.manager, required this.onPlayCard});

  final GameManager manager;
  final void Function(IshiCard) onPlayCard;

  @override
  Widget build(BuildContext context) {
    return DragTarget<IshiCard>(
      onWillAcceptWithDetails: (details) =>
          manager.canPlay(details.data, manager.currentPlayer - 1),
      onAcceptWithDetails: (details) => onPlayCard(details.data),
      builder: (_, candidateCards, rejectedCards) {
        return _HoverableCard(
          isHoveringValid: candidateCards.isNotEmpty,
          isInvalidHover: rejectedCards.isNotEmpty,
          manager: manager,
        );
      },
    );
  }
}

class _HoverableCard extends StatelessWidget {
  const _HoverableCard({
    required this.isHoveringValid,
    required this.isInvalidHover,
    required this.manager,
  });

  final bool isHoveringValid;
  final bool isInvalidHover;
  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    double targetScale = 1.0;
    if (isHoveringValid) {
      targetScale = 1.1;
    } else if (isInvalidHover) {
      targetScale = 1.05;
    }

    Color tintColor = Colors.transparent;
    Color glowColor = Colors.transparent;

    if (isHoveringValid) {
      glowColor = Colors.greenAccent.withValues(alpha: 0.8);
    } else if (isInvalidHover) {
      glowColor = Colors.redAccent.withValues(alpha: 0.8);
      tintColor = Colors.red.withValues(alpha: 0.3);
    }

    final tint = Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: .circular(12),
        ),
      ),
    );

    final stackedContent = [
      CardFront(card: manager.topCard),
      if (manager.declaredColor != null)
        _DeclaredColorAura(displayColor: manager.declaredColor!.displayColor),
      tint,
    ];

    return AnimatedScale(
      scale: targetScale,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: .circular(12),
          border: .all(color: glowColor, width: 1),
        ),
        width: 120,
        height: 180,
        child: Stack(alignment: .center, children: stackedContent),
      ),
    );
  }
}

class _DeclaredColorAura extends StatelessWidget {
  const _DeclaredColorAura({required this.displayColor});

  final Color displayColor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(12),
          border: .all(color: displayColor, width: 6),
        ),
      ),
    );
  }
}

class _AvailableCardsPile extends StatelessWidget {
  const _AvailableCardsPile({
    required this.onDrawCard,
    required this.deckLength,
  });

  final VoidCallback onDrawCard;
  final int deckLength;

  @override
  Widget build(BuildContext context) {
    final stackedContent = [
      CardBack(),
      Container(
        padding: const .all(8),
        decoration: const BoxDecoration(color: Colors.black54, shape: .circle),
        child: Text(
          "$deckLength",
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
      ),
    ];
    return GestureDetector(
      onTap: onDrawCard,
      child: Stack(alignment: .center, children: stackedContent),
    );
  }
}

class _CardAnimatedRotation extends StatelessWidget {
  const _CardAnimatedRotation({required this.manager});

  final GameManager manager;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      // 0.0 is default (Clockwise)
      // -0.5 flips it 180 degrees (Counter-Clockwise)
      turns: manager.isClockwise ? 0.0 : -0.5,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutBack,
      child: Icon(
        Icons.sync,
        size: 280,
        color: Colors.grey.withValues(alpha: 0.2),
      ),
    );
  }
}
