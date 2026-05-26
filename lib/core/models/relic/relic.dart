import 'package:flutter/material.dart';
import 'package:ishi/components/animated_card_list/animated_card_list.dart';
import 'package:ishi/components/dialogs/gameplay/polymorph_dialog.dart';
import 'package:ishi/core/assets.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/screens/game_screen/game_screen.dart';
import '../../data_types.dart';

part 'relic_functions.dart';
part 'relics.dart';

typedef RelicCallback =
    Future<IshiCard?> Function({
      GameManager? manager,
      GameScreenState? gameState,
      Relic? relic,
      List<IshiCard>? targets,
      IshiCard? card,
    })?;

typedef RelicUsageDialog =
    Future<IshiCard?> Function({
      required BuildContext context,
      GameManager? manager,
      Relic? relic,
    })?;

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
  final List<String> memory;
  final RelicCallback onUse;
  final RelicUsageDialog onUseDialog;
  final int? useCost;

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
    List<String>? memory,
    this.onUse,
    this.onUseDialog,
    this.useCost,
  }) : memory = memory ?? <String>[];

  @override
  String toString() {
    final usage = types.contains(RelicEffectType.singleUse)
        ? "singleUse"
        : "$usesLeft/$maxUses uses left";
    return "'$name': $effect ($usage)";
  }

  StringDynamicMap toJson() => {
    'id': id,
    if (usesLeft != null) 'usesLeft': usesLeft,
    'memory': memory,
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
    memory: List<String>.from(memory),
    onUse: onUse,
    onUseDialog: onUseDialog,
    useCost: useCost,
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
      memory: List<String>.from(json['memory'] ?? []),
      onUse: template.onUse,
      onUseDialog: template.onUseDialog,
      useCost: template.useCost,
    );
  }
}
