import 'package:flutter/material.dart';

class StartGameButton extends StatelessWidget {
  const StartGameButton({super.key, required this.onStartGame});

  final VoidCallback onStartGame;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const .symmetric(horizontal: 40, vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: onStartGame,
      icon: const Icon(Icons.play_arrow),
      label: const Text(
        "START MATCH",
        style: TextStyle(fontSize: 18, fontWeight: .bold),
      ),
    );
  }
}
