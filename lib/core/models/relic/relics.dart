part of 'relic.dart';

/// The master pool of relics the chest can pull from.
final List<Relic> relicPool = [
  Relic(
    id: 'might_ring',
    name: 'Ring of Might',
    description: '+1 Action Point at the start of your turn.',
    icon: Assets.asImageIcon(Assets.relics.mightRing, color: Colors.amber),
    color: Colors.amber,
    effects: {.addActionPoints: 1},
  ),
  Relic(
    id: 'greed_eye',
    name: "Eye of Greed",
    description: '+1 Card Draw at the start of your turn.',
    icon: Assets.asImageIcon(Assets.relics.greedEye),
    color: Colors.purpleAccent,
    effects: {.addCardDraws: 1},
  ),
  Relic(
    id: 'golden_ticket',
    name: 'Golden Ticket',
    description: 'Instantly draw 5 cards (One-time use).',
    icon: Assets.asImageIcon(Assets.relics.goldenTicket),
    color: Colors.orange,
    effects: {.immediateDraw: 5},
    types: {.singleUse},
  ),
  Relic(
    id: 'polymorph_staff',
    name: 'Staff of Polymorphism',
    description: 'Transform a card into a card of your choice (-1 AP).',
    icon: Assets.asImageIcon(Assets.relics.polymorphStaff),
    color: Colors.pinkAccent,
    effects: {.polymorph: 1},
    types: {.active},
    maxUses: 3,
    onUseDialog: (params) => _onPolymorphDialog(
      context: params.context,
      manager: params.manager!,
      relic: params.relic!,
    ),
    onUse: (params) => _onPolymorph(
      manager: params.manager!,
      gameState: params.gameState!,
      targets: params.targets!,
      chosenTemplate: params.card!,
      playerIndex: params.playerIndex!,
    ),
    useCost: 1,
  ),
  Relic(
    id: 'obliterator',
    name: 'The Obliterator',
    description: 'Dispose of up to 5 cards from your hand (One-time use).',
    icon: Assets.asImageIcon(Assets.relics.obliterator),
    color: Colors.blueGrey,
    effects: {.immediateDiscard: 5},
    types: {.singleUse, .active},
    onUse: (params) => _onObliterate(
      manager: params.manager!,
      gameState: params.gameState!,
      targets: params.targets!,
      playerIndex: params.playerIndex!,
    ),
  ),
];
