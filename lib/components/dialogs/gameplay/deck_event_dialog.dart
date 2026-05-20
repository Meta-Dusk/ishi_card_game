import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/models/deck_event.dart';

class DeckEventDialog extends StatelessWidget {
  const DeckEventDialog({super.key, required this.event});

  final DeckEvent event;

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: const _DialogTitle(),
      content: _DialogContent(event: event),
      actions: _dialogActions(context),
    ),
  );

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  List<ElevatedButton> _dialogActions(BuildContext context) => [
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      onPressed: () => Navigator.of(context).pop(),
      child: const Text("Accept Fate"),
    ),
  ];
}

class _DialogContent extends StatelessWidget {
  const _DialogContent({required this.event});
  final DeckEvent event;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      const Text(
        "The winds of magic shift as the deck reshuffles...",
        style: TextStyle(color: Colors.white70, fontStyle: .italic),
      ),
      const SizedBox(height: 20),
      Text(
        event.title,
        style: TextStyle(color: Colors.purpleAccent, fontWeight: .bold),
      ),
      const SizedBox(height: 8),
      Text.rich(
        TextSpan(
          style: TextStyle(color: Colors.white, fontSize: 16),
          children: event.richDescription,
        ),
      ),
    ],
  );
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle();

  @override
  Widget build(BuildContext context) => const Row(
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
