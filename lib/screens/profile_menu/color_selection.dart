import 'package:flutter/material.dart';

class ColorSelection extends StatelessWidget {
  const ColorSelection({
    super.key,
    required this.colorValue,
    required this.isSelected,
    required this.onSelect,
  });

  final VoidCallback onSelect;
  final bool isSelected;
  final Color colorValue;

  @override
  Widget build(BuildContext context) {
    final boxShadow = BoxShadow(
      color: colorValue.withValues(alpha: 0.5),
      blurRadius: 8,
      spreadRadius: 2,
    );

    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: colorValue,
          shape: .circle,
          border: .all(
            color: isSelected ? Colors.black87 : Colors.transparent,
            width: isSelected ? 4 : 0,
          ),
          boxShadow: [if (isSelected) boxShadow],
        ),
      ),
    );
  }
}
