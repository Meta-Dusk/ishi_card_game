part of 'relic.dart';

/// The master pool of relics the chest can pull from.
final List<Relic> relicPool = [
  Relic(
    id: 'might_ring',
    name: 'Ring of Might',
    description: '+1 Action Point at the start of your turn.',
    icon: Assets.asImageIcon(Assets.relics.mightRing, color: Colors.amber),
    color: Colors.amber,
    effect: .addActionPoint,
  ),
  Relic(
    id: 'greed_eye',
    name: "Eye of Greed",
    description: '+1 Card Draw at the start of your turn.',
    icon: Assets.asImageIcon(Assets.relics.greedEye),
    color: Colors.purpleAccent,
    effect: .addCardDraw,
  ),
  Relic(
    id: 'golden_ticket',
    name: 'Golden Ticket',
    description: 'Instantly draw 5 cards (One-time use).',
    icon: Assets.asImageIcon(Assets.relics.goldenTicket),
    color: Colors.orange,
    effect: .immediateDraw5,
    types: {.singleUse},
  ),
  Relic(
    id: 'polymorph_staff',
    name: 'Staff of Polymorphism',
    description: 'Transform a card into a card of your choice (-1 AP).',
    icon: Assets.asImageIcon(Assets.relics.polymorphStaff),
    color: Colors.pinkAccent,
    effect: .polymorph,
    types: {.active},
    maxUses: 3,
    onUseDialog: ({required context, manager, relic}) =>
        _onPolymorphDialog(context: context, manager: manager!, relic: relic!),
    onUse: ({gameState, manager, relic, targets, card, playerIndex}) =>
        _onPolymorph(
          manager: manager!,
          gameState: gameState!,
          targets: targets!,
          chosenTemplate: card!,
          playerIndex: playerIndex!,
        ),
    useCost: 1,
  ),
  Relic(
    id: 'obliterator',
    name: 'The Obliterator',
    description: 'Dispose of up to 5 cards from your hand (One-time use).',
    icon: Assets.asImageIcon(Assets.relics.obliterator),
    color: Colors.blueGrey,
    effect: .obliterate,
    types: {.singleUse, .active},
    onUse: ({manager, gameState, relic, targets, card, playerIndex}) =>
        _onObliterate(
          manager: manager!,
          gameState: gameState!,
          targets: targets!,
        ),
  ),
];
