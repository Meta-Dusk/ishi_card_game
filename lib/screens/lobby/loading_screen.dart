import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black87,
    width: double.infinity,
    height: double.infinity,
    child: Center(
      child: Column(
        mainAxisSize: .min,
        children: _mainContent
            .animate(interval: 100.ms)
            .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
      ),
    ),
  );

  List<Widget> get _mainContent => [
    CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 6),
    SizedBox(height: 24),
    Text(
      "SHUFFLING DECK...",
      style: TextStyle(
        color: Colors.white,
        fontWeight: .bold,
        fontSize: 18,
        letterSpacing: 2.0,
      ),
    ),
  ];
}
