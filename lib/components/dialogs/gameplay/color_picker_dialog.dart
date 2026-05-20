import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  const ColorPickerDialog({super.key});

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        "CHOOSE A COLOR",
        textAlign: .center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      content: SizedBox(width: 200, height: 250, child: _colorGrid()),
    ),
  );

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  GridView _colorGrid() => GridView.count(
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      _ColorOption(color: .red, displayColor: Colors.red.shade600),
      _ColorOption(color: .blue, displayColor: Colors.blue.shade600),
      _ColorOption(color: .green, displayColor: Colors.green.shade600),
      _ColorOption(color: .yellow, displayColor: Colors.amber.shade500),
    ],
  );
}

class _ColorOption extends StatelessWidget {
  const _ColorOption({required this.color, required this.displayColor});

  final CardColor color;
  final Color displayColor;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).pop(color),
    borderRadius: .circular(16),
    child: Container(
      decoration: BoxDecoration(
        color: displayColor,
        borderRadius: .circular(16),
        border: .all(color: Colors.white24, width: 2),
      ),
    ),
  );
}
