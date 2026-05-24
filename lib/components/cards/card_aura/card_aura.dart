import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart' hide Effect;
import 'package:newton_particles/newton_particles.dart';
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/assets.dart';

part 'card_effects.dart';

class CardAura extends StatelessWidget {
  final Widget child;
  final IshiCard card;
  final DeckEventEffect activeEvent;
  final bool useParticles;
  final int pendingEvolutions;

  const CardAura({
    super.key,
    required this.child,
    required this.card,
    required this.activeEvent,
    this.useParticles = true,
    this.pendingEvolutions = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Red card effects
    if (activeEvent == .redCardsBurn && card.color == .red) {
      return useParticles
          ? Newton(effectConfigurations: [fireEffectConfig], child: fireEffect)
          : fireEffect;
    }
    // Blue card effects
    else if (activeEvent == .blueCardsFreeze && card.color == .blue) {
      return useParticles
          ? Newton(effectConfigurations: [iceEffectConfig], child: freezeEffect)
          : freezeEffect;
    }
    // Green card effects
    else if (activeEvent == .greenCardsEvolution) {
      if (card.color == .green) {
        return useParticles
            ? Newton(
                effectConfigurations: [natureEffectConfig],
                child: natureEffect,
              )
            : natureEffect;
      } else if (card.color != .green && pendingEvolutions > 0) {
        return useParticles
            ? Newton(
                effectConfigurations: [natureEffectConfig],
                child: natureEffect,
              )
            : natureEffect;
      }
    }
    // Yellow card effects
    else if (activeEvent == .yellowCardsUnflux && card.color == .yellow) {
      return useParticles ? unfluxEffectAmp : unfluxEffect;
    }
    // Wild card effects
    else if (activeEvent == .wildDoubleTrouble && card.color == .wild) {
      return wildDoubleTroubleEffect;
    }

    // NO EVENT: Just return the normal card
    return child;
  }
}
