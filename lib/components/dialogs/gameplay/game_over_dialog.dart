import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameOverDialog extends StatelessWidget {
  const GameOverDialog({
    super.key,
    required this.winnerName,
    required this.isWinner,
    required this.onExit,
  });

  final String winnerName;
  final bool isWinner;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: _dialogTitle(),
      content: Column(
        mainAxisSize: .min,
        children: [
          if (isWinner) _AnimatedTrophy(),
          if (!isWinner) _AnimatedLoss(),
          const SizedBox(height: 16),
          Text(
            winnerName,
            textAlign: .center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: .bold,
            ),
          ),
          const Text(
            "Won the match!",
            textAlign: .center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
      actionsAlignment: .center,
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.exit_to_app),
          label: const Text("RETURN TO MENU"),
          onPressed: onExit,
        ),
      ],
    ),
  );

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  Text _dialogTitle() => Text(
    isWinner ? "VICTORY" : "DEFEAT",
    textAlign: .center,
    style: TextStyle(
      color: isWinner ? Colors.white : Colors.red,
      fontSize: 24,
      fontWeight: .bold,
      letterSpacing: 2,
    ),
  );
}

class _AnimatedLoss extends StatelessWidget {
  const _AnimatedLoss();

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.sentiment_dissatisfied_outlined,
      color: Colors.red,
      size: 160,
    );
    return icon
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          delay: 1.seconds,
          begin: Offset(1.0, 1.0),
          end: Offset(1.2, 1.2),
        );
  }
}

class _AnimatedTrophy extends StatelessWidget {
  const _AnimatedTrophy();

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.emoji_events, color: Colors.amber, size: 160);
    return icon
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.4));
  }
}
