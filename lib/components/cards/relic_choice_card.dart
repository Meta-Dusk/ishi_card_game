import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ishi/core/models/relic.dart';

class RelicChoiceCard extends StatelessWidget {
  const RelicChoiceCard({super.key, required this.relic, this.onTap});

  final Relic relic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget cardUI = Container(
      width: 120,
      height: 180,
      margin: const .symmetric(horizontal: 8, vertical: 8),
      padding: const .all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: .circular(16),
        border: .all(color: relic.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: relic.color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _RelicCardContent(relic: relic),
    );

    if (onTap != null) return GestureDetector(onTap: onTap, child: cardUI);
    return cardUI;
  }
}

class _RelicCardContent extends StatelessWidget {
  const _RelicCardContent({required this.relic});

  final Relic relic;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: .center,
    children: [
      Icon(relic.icon, color: relic.color, size: 48),
      const SizedBox(height: 12),
      AutoSizeText(
        relic.name,
        textAlign: .center,
        maxLines: 2,
        minFontSize: 10,
        overflow: .ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: .bold,
          fontSize: 15,
        ),
      ),
      if (relic.maxUses != null) ...[
        const SizedBox(height: 8),
        _UsesLeftIndicator(relic: relic),
      ],
      const SizedBox(height: 8),
      Expanded(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            relic.description,
            textAlign: .center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
          ),
        ),
      ),
    ],
  );
}

class _UsesLeftIndicator extends StatelessWidget {
  const _UsesLeftIndicator({required this.relic});

  final Relic relic;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: .center,
    children: List.generate(relic.maxUses!, (i) {
      bool isAvailable = i < (relic.usesLeft ?? relic.maxUses!);
      return Padding(
        padding: const .symmetric(horizontal: 2.0),
        child: Icon(
          isAvailable ? Icons.circle : Icons.circle_outlined,
          size: 10,
          color: relic.color,
        ),
      );
    }),
  );
}
