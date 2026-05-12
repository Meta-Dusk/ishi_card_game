import 'package:flutter/material.dart';

class ClientView extends StatelessWidget {
  const ClientView({super.key});

  @override
  Widget build(BuildContext context) {
    const mainContent = [
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.orangeAccent,
          strokeWidth: 3,
        ),
      ),
      SizedBox(width: 16),
      Text(
        "Waiting for Host to start...",
        style: TextStyle(color: Colors.white70, fontWeight: .bold),
      ),
    ];

    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: .circular(12),
      ),
      child: const Row(mainAxisSize: .min, children: mainContent),
    );
  }
}
