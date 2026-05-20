import 'package:flutter/material.dart';

enum DeckEventEffect {
  blueCardsFreeze,
  redCardsBurn,
  wildsTakeDoubleAP,
  greenCardsSkipsTurns,
  none,
}

class DeckEvent {
  final String id;
  final String title;
  final DeckEventEffect effect;
  final List<InlineSpan> richDescription;

  const DeckEvent({
    required this.id,
    required this.title,
    required this.effect,
    required this.richDescription,
  });
}

final List<DeckEvent> deckEventPool = [
  DeckEvent(
    id: 'blue_freeze',
    title: "THE NORTH POLE OFFERS AID!",
    effect: .blueCardsFreeze,
    richDescription: [
      const TextSpan(text: "All "),
      TextSpan(
        text: "Blue Cards ",
        style: TextStyle(color: Colors.blue.shade500),
      ),
      const TextSpan(text: "now inflict "),
      const TextSpan(
        text: "Frozen ",
        style: TextStyle(fontWeight: .bold, color: Colors.blueAccent),
      ),
      const TextSpan(text: "skipping the next player's turn!"),
    ],
  ),
  DeckEvent(
    id: 'red_burn',
    title: "THE DECK HEATS UP!",
    effect: .redCardsBurn,
    richDescription: [
      const TextSpan(text: "Playing any "),
      const TextSpan(
        text: "Red Card ",
        style: TextStyle(color: Colors.redAccent, fontWeight: .bold),
      ),
      const TextSpan(text: "now costs an additional Action Point!"),
    ],
  ),
];
