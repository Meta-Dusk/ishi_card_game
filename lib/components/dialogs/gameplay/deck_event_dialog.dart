import 'package:flutter/material.dart';

class DeckEventDialog extends StatelessWidget {
  const DeckEventDialog({super.key, required this.onDrawCard});

  final VoidCallback onDrawCard;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).pop();
          onDrawCard();
        },
        child: const Text("Accept Fate"),
      ),
    ];

    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: _DialogTitle(),
      content: _DialogContent(),
      actions: actions,
    );
  }
}

class _DialogContent extends StatelessWidget {
  const _DialogContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        Text(
          "The winds of magic shift as the deck reshuffles...",
          style: TextStyle(color: Colors.white70, fontStyle: .italic),
        ),
        SizedBox(height: 20),
        Text(
          "NEW GLOBAL RULE AQUIRED:",
          style: TextStyle(color: Colors.purpleAccent, fontWeight: .bold),
        ),
        SizedBox(height: 8),
        Text(
          "All Blue Cards now inflict 'Frozen' status,"
          "skipping the next player's draw phase!",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
        SizedBox(width: 12),
        Text(
          "DECK DEPLETED",
          style: TextStyle(
            color: Colors.white,
            fontWeight: .bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
