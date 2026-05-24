import 'package:flutter/material.dart';

typedef DeckGenerationRecord = ({
  List<IshiCard> newDeck,
  int lastDeckTotalIndex,
});

enum CardColor {
  red,
  yellow,
  green,
  blue,
  wild;

  static List<CardColor> get getNormalColors => [.red, .green, .blue, .yellow];

  Color get displayColor {
    switch (this) {
      case .red:
        return Colors.red.shade600;
      case .blue:
        return Colors.blue.shade600;
      case .green:
        return Colors.green.shade600;
      case .yellow:
        return Colors.amber.shade500;
      case .wild:
        return Colors.white;
    }
  }
}

enum CardType {
  number,
  skip,
  reverse,
  draw2,
  chooseColor,
  draw4,
  chest;

  static List<CardType> get getWildTypes => [.chest, .chooseColor, .draw4];
}

class IshiCard {
  final String id;
  final CardColor color;
  final CardType type;
  final int? number;
  bool isFaceUp;

  IshiCard({
    required this.id,
    required this.color,
    required this.type,
    this.number,
    this.isFaceUp = false,
  });

  bool get isFaceDown => !isFaceUp;

  /// Converts the card into a map that can be sent over the WebSocket
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color.index,
      'type': type.index,
      'number': number,
      'isFaceUp': isFaceUp,
    };
  }

  /// Rebuilds the card when the Client receives the JSON
  factory IshiCard.fromJson(Map<String, dynamic> json) {
    return IshiCard(
      id: json['id'],
      color: CardColor.values[json['color'] as int],
      type: CardType.values[json['type'] as int],
      number: json['number'],
      isFaceUp: json['isFaceUp'] ?? true,
    );
  }

  IshiCard clone({
    String? newId,
    CardColor? newColor,
    CardType? newType,
    int? newNumber,
    bool? isFacingUp,
  }) => IshiCard(
    id: newId ?? id,
    color: newColor ?? color,
    type: newType ?? type,
    number: newNumber ?? number,
    isFaceUp: isFacingUp ?? isFaceUp,
  );

  @override
  String toString() {
    final cardName = type == .number ? number.toString() : type.name;
    return "(${color.name}) $cardName";
  }
}

/// Generates a standard deck
DeckGenerationRecord generateStandardDeck({
  bool basicOnly = false,
  int? startingIdCount,
}) {
  List<IshiCard> deck = [];
  int idCounter = startingIdCount ?? 0;

  // Make one pass per card color
  for (CardColor color in CardColor.getNormalColors) {
    // One 0 card
    deck.add(
      IshiCard(
        id: 'card_${idCounter++}',
        color: color,
        type: .number,
        number: 0,
      ),
    );

    // Two of each 1-9
    for (int i = 1; i <= 9; i++) {
      deck.add(
        IshiCard(
          id: 'card_${idCounter++}',
          color: color,
          type: .number,
          number: i,
        ),
      );
      deck.add(
        IshiCard(
          id: 'card_${idCounter++}',
          color: color,
          type: .number,
          number: i,
        ),
      );
    }

    // Action cards
    for (int i = 0; i < 2; i++) {
      deck.add(IshiCard(id: 'card_${idCounter++}', color: color, type: .skip));
      deck.add(
        IshiCard(id: 'card_${idCounter++}', color: color, type: .reverse),
      );
      deck.add(IshiCard(id: 'card_${idCounter++}', color: color, type: .draw2));
    }
  }

  // 4 of each wilds
  for (int i = 0; i < 4; i++) {
    deck.add(
      IshiCard(id: 'wild_${idCounter++}', color: .wild, type: .chooseColor),
    );
    deck.add(IshiCard(id: 'wild4_${idCounter++}', color: .wild, type: .draw4));
  }

  if (!basicOnly) {
    // Add some chests cuz why not
    for (int i = 0; i < 10; i++) {
      deck.add(
        IshiCard(id: 'chest_${idCounter++}', color: .wild, type: .chest),
      );
    }
  }

  deck.shuffle();
  return (newDeck: deck, lastDeckTotalIndex: idCounter);
}
