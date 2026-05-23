import 'package:flutter/material.dart';
import 'package:ishi/screens/game_screen/imports/game_components.dart';
import 'package:ishi/screens/game_screen/imports/game_core.dart';

class RelicDisplay extends StatelessWidget {
  const RelicDisplay({
    super.key,
    required this.relics,
    required this.onTapRelic,
  });

  final List<Relic> relics;
  final void Function(bool isActiveRelic, Relic relic) onTapRelic;

  @override
  Widget build(BuildContext context) {
    if (relics.isEmpty) return _emptyRelics();

    return ListView.builder(
      scrollDirection: .horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const .symmetric(horizontal: 40, vertical: 20),
      itemCount: relics.length,
      itemBuilder: (_, index) {
        final relic = relics[index];
        return RelicChoiceCard(
          relic: relic,
          onTap: () =>
              onTapRelic(relic.types.contains(RelicEffectType.active), relic),
        );
      },
    );
  }

  Center _emptyRelics() => const Center(
    child: Text(
      "NO RELICS EQUIPPED",
      style: TextStyle(
        color: Colors.white54,
        letterSpacing: 2,
        fontWeight: .bold,
      ),
    ),
  );
}
