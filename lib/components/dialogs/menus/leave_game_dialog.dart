import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/services/network_service.dart';

class LeaveGameDialog extends StatelessWidget {
  const LeaveGameDialog({super.key, required this.network});

  final NetworkService network;

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text("Leave Game", style: TextStyle(color: Colors.white)),
      content: const Text(
        "Are you sure you want to leave the match?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: _dialogActions(context),
    ),
  );

  List<Widget> _dialogActions(BuildContext context) => [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
    ),
    ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.shade700,
      ),
      onPressed: () async {
        Navigator.pop(context);
        await network.disconnect();
        if (!context.mounted) return;
        // Back to Main Menu
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: const Text("LEAVE", style: TextStyle(color: Colors.white)),
    ),
  ];
}
