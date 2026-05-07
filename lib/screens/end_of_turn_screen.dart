import 'package:flutter/material.dart';

class EndOfTurnScreen extends StatelessWidget {
  const EndOfTurnScreen({
    super.key,
    required this.nextPlayer,
    required this.onStartNextTurn,
  });

  final VoidCallback onStartNextTurn;
  final int nextPlayer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: ElevatedButton(
          onPressed: onStartNextTurn,
          style: ElevatedButton.styleFrom(
            padding: const .symmetric(horizontal: 40, vertical: 20),
          ),
          child: Text(
            "Pass to Player $nextPlayer\nTap to Start Turn",
            textAlign: .center,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
