import 'package:flutter/material.dart';
import 'package:ishi/components/cards/card_aura/card_aura.dart';
import '../../../core/managers/game/game_manager.dart';
import '../../../core/models/ishi_card.dart';
import '../../cards/card_display.dart';

class PlayAndPileDeck extends StatelessWidget {
  const PlayAndPileDeck({
    super.key,
    required this.manager,
    required this.onDrawCard,
    required this.onPlayCard,
    this.playPileKey,
  });

  final GameManager manager;
  final VoidCallback onDrawCard;
  final void Function(IshiCard card) onPlayCard;
  final GlobalKey<PlayCardsPileState>? playPileKey;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: .center, children: _mainContent);

  List<Widget> get _mainContent => [
    _AvailableCardsPile(
      onDrawCard: onDrawCard,
      deckLength: manager.deck.length,
    ),
    const SizedBox(width: 20),
    PlayCardsPile(
      key: playPileKey,
      manager: manager,
      onPlayCard: onPlayCard,
    ), // DragTarget
  ];
}

class PlayCardsPile extends StatefulWidget {
  const PlayCardsPile({
    super.key,
    required this.manager,
    required this.onPlayCard,
  });

  final GameManager manager;
  final void Function(IshiCard card) onPlayCard;

  @override
  State<PlayCardsPile> createState() => PlayCardsPileState();
}

class PlayCardsPileState extends State<PlayCardsPile>
    with SingleTickerProviderStateMixin {
  late AnimationController _dropController;

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..value = 1.0; // Start at 1.0 (fully rested)
  }

  @override
  void dispose() {
    _dropController.dispose();
    super.dispose();
  }

  // WE WILL CALL THIS FROM THE NETWORK!
  void animateOpponentDrop() => _dropController.forward(from: 0.0);

  @override
  Widget build(BuildContext context) => DragTarget<IshiCard>(
    onWillAcceptWithDetails: (details) => widget.manager
        .canPlay(details.data, widget.manager.currentPlayer - 1)
        .canPlay,
    onAcceptWithDetails: (details) => widget.onPlayCard(details.data),
    builder: (_, candidateCards, rejectedCards) => _AnimatedHoverableCard(
      dropController: _dropController,
      manager: widget.manager,
      candidateCards: candidateCards,
      rejectedCards: rejectedCards,
    ),
  );
}

class _AnimatedHoverableCard extends StatelessWidget {
  const _AnimatedHoverableCard({
    required this.dropController,
    required this.manager,
    required this.candidateCards,
    required this.rejectedCards,
  });

  final AnimationController dropController;
  final GameManager manager;
  final List<IshiCard?> candidateCards;
  final List<dynamic> rejectedCards;

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: dropController, curve: Curves.easeOutBack),
    ),
    child: FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 1.0).animate(dropController),
      child: _HoverableCard(
        isHoveringValid: candidateCards.isNotEmpty,
        isInvalidHover: rejectedCards.isNotEmpty,
        manager: manager,
      ),
    ),
  );
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

    final topCard = manager.topCard;

    final stackedContent = [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: RotationTransition(
            turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: CardAura(
          key: ValueKey(
            "${topCard.id}_${topCard.color.name}_"
            "${topCard.type.name}_${topCard.number}",
          ),
          card: topCard,
          activeEvent: manager.activeDeckEvent,
          pendingEvolutions: manager.pendingEvolutions,
          child: CardFront(card: topCard),
        ),
      ),
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
  Widget build(BuildContext context) => Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: .circular(12),
        border: .all(color: displayColor, width: 6),
      ),
    ),
  );
}

class _AvailableCardsPile extends StatelessWidget {
  const _AvailableCardsPile({
    required this.onDrawCard,
    required this.deckLength,
  });

  final VoidCallback onDrawCard;
  final int deckLength;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onDrawCard,
    child: Stack(alignment: .center, children: _stackedContent),
  );

  List<StatelessWidget> get _stackedContent => [
    const CardBack(),
    Container(
      padding: const .all(8),
      decoration: const BoxDecoration(color: Colors.black54, shape: .circle),
      child: Text(
        "$deckLength",
        style: const TextStyle(color: Colors.white, fontWeight: .bold),
      ),
    ),
  ];
}
