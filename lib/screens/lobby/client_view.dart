import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ClientView extends StatelessWidget {
  const ClientView({super.key});

  @override
  Widget build(BuildContext context) => _animatedContainer(
    Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: .circular(12),
      ),
      child: Row(mainAxisSize: .min, children: _mainContent),
    ),
  );

  Animate _animatedContainer(Container container) => container
      .animate()
      .fadeIn(duration: 300.ms)
      .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic);

  List<Widget> get _mainContent => [
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
}
