import 'package:flutter/material.dart';

enum DeckEventEffect {
  none,
  blueCardsFreeze,
  redCardsBurn,
  wildDoubleTrouble,
  greenCardsEvolution,
  butterFlyEffect,
  yellowCardsUnflux,
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
    id: 'wilds_double_trouble',
    title: "THE WILDEST WEST?",
    effect: .wildDoubleTrouble,
    richDescription: const [
      TextSpan(text: "All "),
      TextSpan(
        text: "Wild Cards ",
        style: TextStyle(color: Colors.deepPurple, fontWeight: .bold),
      ),
      TextSpan(text: "now inflict "),
      TextSpan(
        text: "double ",
        style: TextStyle(fontWeight: .bold),
      ),
      TextSpan(text: "their effect, but will now also cost "),
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
    id: 'green_evolves',
    title: "MOTHER NATURE IS ANGRY!",
    effect: .greenCardsEvolution,
    richDescription: [
      const TextSpan(text: "All "),
      TextSpan(
        text: "Green Cards ",
        style: TextStyle(color: Colors.green.shade500),
      ),
      const TextSpan(text: "can now induce "),
      const TextSpan(
        text: "evolution, ",
        style: TextStyle(color: Colors.lightGreen, fontWeight: .bold),
      ),
      const TextSpan(text: "which makes all green cards played, "),
      const TextSpan(
        text: "evolve ",
        style: TextStyle(color: Colors.lightGreenAccent, fontStyle: .italic),
      ),
      const TextSpan(text: "the next "),
      const TextSpan(
        text: "non-green card, ",
        style: TextStyle(fontStyle: .italic),
      ),
      const TextSpan(text: "which can either increment their value "),
      const TextSpan(
        text: "(if below 9), ",
        style: TextStyle(color: Colors.grey),
      ),
      const TextSpan(text: "cycle to the next color "),
      const TextSpan(
        text: "(if 9, or skip), ",
        style: TextStyle(color: Colors.grey),
      ),
      const TextSpan(text: "or just "),
      const TextSpan(
        text: "upgrade ",
        style: TextStyle(fontWeight: .bold),
      ),
      const TextSpan(text: "to a +4, if it's already a +2 of "),
      const TextSpan(
        text: "any ",
        style: TextStyle(fontStyle: .italic),
      ),
      const TextSpan(text: "color."),
    ],
  ),
  DeckEvent(
    id: 'yellow_unflux',
    title: "TESLA LIKES AC/DC?",
    effect: .yellowCardsUnflux,
    richDescription: [
      const TextSpan(text: "All played "),
      TextSpan(
        text: "yellow cards ",
        style: TextStyle(color: Colors.amber.shade500),
      ),
      const TextSpan(text: "now inflict "),
      const TextSpan(
        text: "unflux ",
        style: TextStyle(fontWeight: .bold, color: Colors.amberAccent),
      ),
      const TextSpan(text: "which "),
      const TextSpan(
        text: "reverses ",
        style: TextStyle(fontStyle: .italic),
      ),
      const TextSpan(text: "the turn order."),
    ],
  ),
  DeckEvent(
    id: 'buttefly_effect',
    title: "CHAOS ENSUES...",
    effect: .butterFlyEffect,
    richDescription: const [
      TextSpan(text: "Played cards may change into something "),
      TextSpan(
        text: "entirely different ",
        style: TextStyle(fontWeight: .bold),
      ),
      TextSpan(text: "once per round."),
    ],
  ),
];
