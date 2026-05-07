import 'package:flutter/material.dart';

enum RelicEffect { addActionPoint, addCardDraw, immediateDraw3 }

class Relic {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final RelicEffect effect;

  const Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.effect,
  });
}

/// The master pool of relics the chest can pull from.
final List<Relic> relicPool = [
  const Relic(
    id: 'energy_drink',
    name: 'Energy Drink',
    description: '+1 Action Point at the start of your turn.',
    icon: Icons.bolt,
    color: Colors.amber,
    effect: .addActionPoint,
  ),
  const Relic(
    id: 'greeds_eye',
    name: "Greed's Eye",
    description: '+1 Card Draw at the start of your turn.',
    icon: Icons.visibility,
    color: Colors.purpleAccent,
    effect: .addCardDraw,
  ),
  const Relic(
    id: 'golden_ticket',
    name: 'Golden Ticket',
    description: 'Instantly draw 3 cards. (One-time use)',
    icon: Icons.local_activity,
    color: Colors.orange,
    effect: .immediateDraw3,
  ),
];
