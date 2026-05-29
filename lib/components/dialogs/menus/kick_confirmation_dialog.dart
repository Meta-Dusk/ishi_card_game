import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/network/network_messages.dart';

class KickConfirmationDialog extends StatelessWidget {
  const KickConfirmationDialog({
    super.key,
    required this.player,
    required this.textController,
    required this.onKick,
    required this.playerIndex,
  });

  final LobbyPlayer player;
  final TextEditingController textController;
  final void Function(int playerIndex, {String? reason})? onKick;
  final int playerIndex;

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text("KICK PLAYER", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: _dialogContent(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onKick!(playerIndex, reason: textController.text.trim());
          },
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent.shade700,
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          ),
          child: const Text("Kick"),
        ),
      ],
    ),
  );

  List<Widget> _dialogContent(BuildContext context) => [
    Text(
      "Are you sure you want to kick ${player.playerName}?",
      style: const TextStyle(color: Colors.white70),
    ),
    const SizedBox(height: 16),
    TextField(
      controller: textController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: "Reason (Optional)",
        hintStyle: TextStyle(color: Colors.white30),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orangeAccent),
        ),
      ),
      onSubmitted: (value) {
        Navigator.pop(context);
        onKick!(playerIndex, reason: value.trim());
      },
    ),
  ];
}
