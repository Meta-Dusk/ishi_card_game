import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ishi/components/cards/relic_choice_card.dart';
import 'package:ishi/core/models/relic.dart';

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
  Widget build(BuildContext context) => AlertDialog(
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
      width: MediaQuery.of(context).size.width * 0.9,
      child: Align(
        alignment: .center,
        heightFactor: 1,
        child: SingleChildScrollView(
          scrollDirection: .horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(mainAxisSize: .min, children: _relicChoiceCards(context)),
        ),
      ),
    ),
  );

  List<RelicChoiceCard> _relicChoiceCards(BuildContext context) => _choices
      .map(
        (relic) => RelicChoiceCard(
          relic: relic,
          onTap: () => Navigator.of(context).pop(relic),
        ),
      )
      .toList();
}
