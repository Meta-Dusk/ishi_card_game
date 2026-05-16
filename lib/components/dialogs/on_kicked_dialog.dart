import 'package:flutter/material.dart';

class OnKickedDialog extends StatelessWidget {
  const OnKickedDialog({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}
