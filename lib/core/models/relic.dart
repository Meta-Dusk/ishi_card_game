import 'package:flutter/material.dart';
import '../data_types.dart';

enum RelicEffect {
  addActionPoint,
  addCardDraw,
  immediateDraw3,
  polymorph,
  trashcan,
}

enum RelicEffectType { active, passive, singleUse }

class Relic {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final RelicEffect effect;
  final Set<RelicEffectType> types;
  final int? maxUses;
  int? usesLeft;

  Relic({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.effect,
    this.types = const {.passive},
    this.maxUses,
    this.usesLeft,
  });

  StringDynamicMap toJson() => {
    'id': id,
    if (usesLeft != null) 'usesLeft': usesLeft,
  };

  Relic clone() => Relic(
    id: id,
    name: name,
    description: description,
    icon: icon,
    color: color,
    effect: effect,
    types: Set.from(types),
    maxUses: maxUses,
    usesLeft: maxUses ?? maxUses,
  );

  factory Relic.fromJson(StringDynamicMap json) {
    final template = relicPool.firstWhere(
      (r) => r.id == json['id'],
      orElse: () => relicPool.first,
    );

    return Relic(
      id: template.id,
      name: template.name,
      description: template.description,
      icon: template.icon,
      color: template.color,
      effect: template.effect,
      types: template.types,
      maxUses: template.maxUses,
      usesLeft: json['usesLeft'] as int? ?? template.maxUses,
    );
  }
}

/// The master pool of relics the chest can pull from.
final List<Relic> relicPool = [
  Relic(
    id: 'energy_drink',
    name: 'Energy Drink',
    description: '+1 Action Point at the start of your turn.',
    icon: Icons.bolt,
    color: Colors.amber,
    effect: .addActionPoint,
  ),
  Relic(
    id: 'greeds_eye',
    name: "Greed's Eye",
    description: '+1 Card Draw at the start of your turn.',
    icon: Icons.visibility,
    color: Colors.purpleAccent,
    effect: .addCardDraw,
  ),
  Relic(
    id: 'golden_ticket',
    name: 'Golden Ticket',
    description: 'Instantly draw 3 cards. (One-time use)',
    icon: Icons.local_activity,
    color: Colors.orange,
    effect: .immediateDraw3,
    types: {.singleUse},
  ),
  Relic(
    id: 'staff_of_polymorph',
    name: 'Staff of Polymorphism',
    description:
        'Transform a card into a card of your choice. (1 Turn Cooldown)',
    icon: Icons.auto_fix_high,
    color: Colors.pinkAccent,
    effect: .polymorph,
    types: {.active},
    maxUses: 3,
  ),
  Relic(
    id: 'trashcan',
    name: 'Trashcan',
    description: 'Dispose of up to 2 cards from your hand. (One-time use)',
    icon: Icons.delete_sweep,
    color: Colors.blueGrey,
    effect: .trashcan,
    types: {.singleUse, .active},
  ),
];
