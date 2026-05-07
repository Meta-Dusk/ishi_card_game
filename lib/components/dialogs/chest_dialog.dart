import 'dart:math';

import 'package:esther_gift/models/relic.dart';
import 'package:flutter/material.dart';

class ChestDialog extends StatefulWidget {
  const ChestDialog({super.key});

  @override
  State<ChestDialog> createState() => _ChestDialogState();
}

class _ChestDialogState extends State<ChestDialog> {
  late List<Relic> _choices;

  @override
  void initState() {
    super.initState();
    final random = Random();
    final poolCopy = List<Relic>.from(relicPool)..shuffle(random);
    _choices = poolCopy.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        "CHOOSE A RELIC",
        textAlign: .center,
        style: TextStyle(
          color: Colors.amber,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: .min,
          children: _choices.map((relic) => RelicCard(relic: relic)).toList(),
        ),
      ),
    );
  }
}

class RelicCard extends StatelessWidget {
  const RelicCard({super.key, required this.relic});

  final Relic relic;

  @override
  Widget build(BuildContext context) {
    final listTile = ListTile(
      leading: Icon(relic.icon, color: relic.color, size: 36),
      title: Text(
        relic.name,
        style: const TextStyle(color: Colors.white, fontWeight: .bold),
      ),
      subtitle: Text(
        relic.description,
        style: TextStyle(color: Colors.grey.shade400),
      ),
      onTap: () => Navigator.of(
        context,
      ).pop(relic), // Returns the selected relic to GameScreen
    );
    return Card(
      color: Colors.grey.shade800,
      margin: const .symmetric(vertical: 8),
      child: listTile,
    );
  }
}
