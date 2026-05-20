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
    title: "THE DECK-CANO EXPLODES!",
    effect: .redCardsBurn,
    richDescription: [
      const TextSpan(text: "All "),
      TextSpan(
        text: "Red Cards ",
        style: TextStyle(color: Colors.red.shade500, fontWeight: .bold),
      ),
      const TextSpan(text: "now has a "),
      const TextSpan(
        text: "side-effect ",
        style: TextStyle(fontStyle: .italic),
      ),
      const TextSpan(text: "upon playing: "),
      const TextSpan(
        text: "+1!",
        style: TextStyle(color: Colors.redAccent, fontWeight: .bold),
      ),
    ],
  ),
  DeckEvent(
    id: 'wilds_double_ap',
    title: "SUPPLY AND DEMAND?",
    effect: .wildsTakeDoubleAP,
    richDescription: const [
      TextSpan(text: "All "),
      TextSpan(
        text: "Wild Cards ",
        style: TextStyle(color: Colors.deepPurple, fontWeight: .bold),
      ),
      TextSpan(text: "now cost "),
      TextSpan(
        text: "double ",
        style: TextStyle(fontWeight: .bold),
      ),
      TextSpan(text: "the "),
      TextSpan(
        text: "Action Points (AP) ",
        style: TextStyle(color: Colors.amber),
      ),
      TextSpan(text: "needed to play."),
    ],
  ),
  DeckEvent(
    id: 'green_skips',
    title: "MOTHER NATURE IS ANGRY!",
    effect: .greenCardsSkipsTurns,
    richDescription: [
      const TextSpan(text: "All "),
      TextSpan(
        text: "Green Cards ",
        style: TextStyle(color: Colors.green.shade500),
      ),
      const TextSpan(text: "now also act as "),
      const TextSpan(
        text: "skips.",
        style: TextStyle(color: Colors.greenAccent, fontWeight: .bold),
      ),
    ],
  ),
];
