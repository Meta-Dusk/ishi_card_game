import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/components/cards/card_display.dart';

class PolymorphDialog extends StatefulWidget {
  final List<String> usedCardIds;

  const PolymorphDialog({super.key, required this.usedCardIds});

  @override
  State<PolymorphDialog> createState() => _PolymorphDialogState();
}

class _PolymorphDialogState extends State<PolymorphDialog> {
  late List<IshiCard> _allCards;

  @override
  void initState() {
    super.initState();
    _allCards = [];

    // Generate all colored cards
    final colors = CardColor.getNormalColors;
    for (CardColor color in colors) {
      for (int i = 0; i <= 9; i++) {
        _allCards.add(
          IshiCard(
            id: '${color.name}_$i',
            color: color,
            type: .number,
            number: i,
          ),
        );
      }
      _allCards.add(
        IshiCard(id: '${color.name}_skip', color: color, type: .skip),
      );
      _allCards.add(
        IshiCard(id: '${color.name}_reverse', color: color, type: .reverse),
      );
      _allCards.add(
        IshiCard(id: '${color.name}_draw2', color: color, type: .draw2),
      );
    }

    // Generate Wilds
    _allCards.add(
      IshiCard(id: 'wild_choose', color: .wild, type: .chooseColor),
    );
    _allCards.add(IshiCard(id: 'wild_draw4', color: .wild, type: .draw4));
  }

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        "SELECT NEW CARD",
        textAlign: .center,
        style: TextStyle(
          color: Colors.pinkAccent,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        child: _cardsGrid(),
      ),
    ),
  );

  GridView _cardsGrid() => GridView.builder(
    physics: const BouncingScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      childAspectRatio: 0.65,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: _allCards.length,
    itemBuilder: (context, index) {
      final card = _allCards[index];
      final isUsed = widget.usedCardIds.contains(card.id);
      card.isFaceUp = true;

      return GestureDetector(
        onTap: isUsed ? null : () => Navigator.of(context).pop(card),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isUsed ? 0.25 : 1.0,
          child: FittedBox(
            fit: .contain,
            child: AbsorbPointer(child: CardFront(card: card)),
          ),
        ),
      );
    },
  );
}
