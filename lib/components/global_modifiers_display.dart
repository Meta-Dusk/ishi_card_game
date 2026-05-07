import 'package:flutter/material.dart';

class GlobalModifiersDisplay extends StatelessWidget {
  const GlobalModifiersDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .all(12),
      color: Colors.purple.withValues(alpha: 0.1),
      child: const Row(
        mainAxisAlignment: .center,
        children: [
          Icon(Icons.public, color: Colors.purple),
          SizedBox(width: 8),
          Text(
            "Global Rules: Red cards burn for 1HP",
            style: TextStyle(fontWeight: .bold),
          ),
        ],
      ),
    );
  }
}
