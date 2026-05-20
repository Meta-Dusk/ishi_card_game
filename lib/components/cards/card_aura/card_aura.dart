import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:newton_particles/newton_particles.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/core/models/ishi_card.dart';

part 'card_effects.dart';

class CardAura extends StatelessWidget {
  final Widget child;
  final IshiCard card;
  final DeckEventEffect activeEvent;
  final bool useParticles;

  const CardAura({
    super.key,
    required this.child,
    required this.card,
    required this.activeEvent,
    this.useParticles = true,
  });

  @override
  Widget build(BuildContext context) {
    if (activeEvent == .redCardsBurn && card.color == .red) {
      return useParticles
          ? Newton(effectConfigurations: [fireEffectConfig], child: fireEffect)
          : fireEffect;
    }

    if (activeEvent == .blueCardsFreeze && card.color == .blue) {
      return useParticles
          ? Newton(effectConfigurations: [iceEffectConfig], child: freezeEffect)
          : freezeEffect;
    }

    if (activeEvent == .greenCardsSkipsTurns && card.color == .green) {
      return useParticles
          ? Newton(
              effectConfigurations: [natureEffectConfig],
              child: natureSkipEffect,
            )
          : natureSkipEffect;
    }

    if (activeEvent == .wildsTakeDoubleAP && card.color == .wild) {
      return wildDoubleApEffect;
    }

    // NO EVENT: Just return the normal card
    return child;
  }
}
