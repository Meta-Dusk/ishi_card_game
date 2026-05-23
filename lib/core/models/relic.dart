import 'package:flutter/material.dart';
import 'package:ishi/core/assets.dart';
import '../data_types.dart';

enum RelicEffect {
  addActionPoint,
  addCardDraw,
  immediateDraw5,
  polymorph,
  obliterate,
}

enum RelicEffectType { active, passive, singleUse }

class Relic {
  final String id;
  final String name;
  final String description;
  final Widget icon;
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
    id: 'might_ring',
    name: 'Ring of Might',
    description: '+1 Action Point at the start of your turn.',
    icon: AppAssets.asImageIcon(
      AppAssets.relics.mightRing,
      color: Colors.amber,
    ),
    color: Colors.amber,
    effect: .addActionPoint,
  ),
  Relic(
    id: 'greed_eye',
    name: "Eye of Greed",
    description: '+1 Card Draw at the start of your turn.',
    icon: AppAssets.asImageIcon(AppAssets.relics.greedEye),
    color: Colors.purpleAccent,
    effect: .addCardDraw,
  ),
  Relic(
    id: 'golden_ticket',
    name: 'Golden Ticket',
    description: 'Instantly draw 5 cards. (One-time use)',
    icon: AppAssets.asImageIcon(AppAssets.relics.goldenTicket),
    color: Colors.orange,
    effect: .immediateDraw5,
    types: {.singleUse},
  ),
  Relic(
    id: 'polymorph_staff',
    name: 'Staff of Polymorphism',
    description: 'Transform a card into a card of your choice. (-1 AP)',
    icon: AppAssets.asImageIcon(AppAssets.relics.polymorphStaff),
    color: Colors.pinkAccent,
    effect: .polymorph,
    types: {.active},
    maxUses: 3,
  ),
  Relic(
    id: 'obliterator',
    name: 'The Obliterator',
    description: 'Dispose of up to 5 cards from your hand. (One-time use)',
    icon: AppAssets.asImageIcon(AppAssets.relics.obliterator),
    color: Colors.blueGrey,
    effect: .obliterate,
    types: {.singleUse, .active},
  ),
];
