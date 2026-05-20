import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnKickedDialog extends StatelessWidget {
  const OnKickedDialog({super.key, required this.reason});

  final String reason;

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        "You have been kicked",
        style: TextStyle(color: Colors.redAccent),
      ),
      content: Text(reason, style: const TextStyle(color: Colors.white)),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: const Text("OK", style: TextStyle(color: Colors.black)),
        ),
      ],
    ),
  );
}
