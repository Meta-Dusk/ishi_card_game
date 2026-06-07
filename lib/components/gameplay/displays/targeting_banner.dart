import 'package:flutter/material.dart';
import 'package:ishi/core/models/relic/relic.dart';

class TargetingBanner extends StatelessWidget {
  final Relic activeRelic;
  final int currentTargetsCount;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const TargetingBanner({
    super.key,
    required this.activeRelic,
    required this.currentTargetsCount,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final relicEffects = activeRelic.effects;
    final int maxTargets = relicEffects[RelicEffect.immediateDiscard] ?? 1;

    final usingRelicIndicator = Row(
      mainAxisSize: .min,
      children: [
        Text(
          "USING: ${activeRelic.name.toUpperCase()}",
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onCancel,
        ),
      ],
    );

    final targetsLeftIndicator = Row(
      mainAxisSize: .min,
      children: [
        const Icon(Icons.track_changes, color: Colors.white),
        const SizedBox(width: 12),
        Text(
          "TARGETING: $currentTargetsCount/$maxTargets",
          style: const TextStyle(color: Colors.white, fontWeight: .bold),
        ),
        if (currentTargetsCount > 0) ...[
          const SizedBox(width: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: onConfirm,
            child: const Text(
              "CONFIRM",
              style: TextStyle(color: Colors.white, fontWeight: .bold),
            ),
          ),
        ],
      ],
    );

    return Container(
      margin: const .only(bottom: 16),
      padding: const .symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.2),
        border: .all(color: Colors.redAccent, width: 2),
        borderRadius: .circular(12),
      ),
      child: Column(children: [usingRelicIndicator, targetsLeftIndicator]),
    );
  }
}
