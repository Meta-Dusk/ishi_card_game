import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/cards/relic_choice_card.dart';
import 'package:ishi/core/models/relic/relic.dart';

class ChestDialog extends StatefulWidget {
  const ChestDialog({super.key});

  @override
  State<ChestDialog> createState() => _ChestDialogState();
}

class _ChestDialogState extends State<ChestDialog> {
  late List<Relic> _choices;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final random = Random();
    final poolCopy = List<Relic>.from(relicPool)..shuffle(random);
    _choices = poolCopy.take(3).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _scrollRight().then((_) => _scrollBack()),
      );
    });
  }

  Future<void> _scrollRight() async {
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      60.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollBack() async {
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
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
            controller: _scrollController,
            scrollDirection: .horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: .min,
              children: _relicChoiceCards(context),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  List<RelicChoiceCard> _relicChoiceCards(BuildContext context) => _choices
      .map(
        (relic) => RelicChoiceCard(
          relic: relic,
          onTap: () => Navigator.of(context).pop(relic),
        ),
      )
      .toList();
}
