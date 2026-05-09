import 'package:flutter/material.dart';

enum CardColor { red, yellow, green, blue, wild }

extension CardColorExtension on CardColor {
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

enum CardType { number, skip, reverse, draw2, wild, wildDraw4, chest }

class IshiCard {
  final String id; // Unique ID for animations
  final CardColor color;
  final CardType type;
  final int? number;
  bool isFaceUp; // State controlled by the parent!

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
}

// Generates a basic standard Uno deck (simplified for testing)
List<IshiCard> generateStandardDeck() {
  List<IshiCard> deck = [];
  int idCounter = 0;

  for (CardColor color in [.red, .yellow, .green, .blue]) {
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

  //Add the standard 4 Wilds and 4 Wild Draw 4s
  for (int i = 0; i < 4; i++) {
    deck.add(IshiCard(id: 'wild_${idCounter++}', color: .wild, type: .wild));
    deck.add(
      IshiCard(id: 'wild4_${idCounter++}', color: .wild, type: .wildDraw4),
    );
  }

  // Add a couple of chests for the roguelike flavor
  deck.add(IshiCard(id: 'chest_1', color: .wild, type: .chest));
  deck.add(IshiCard(id: 'chest_2', color: .wild, type: .chest));

  deck.shuffle();
  return deck;
}
