import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;

  const MenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryStyledButton = _PrimaryStyledButton(
      color: color,
      icon: icon,
      title: title,
      onTap: onTap,
    );

    final secondaryStyledButton = _SecondaryStyledButton(
      color: color,
      icon: icon,
      title: title,
      onTap: onTap,
    );

    return SizedBox(
      width: double.infinity,
      height: isPrimary ? 65 : 55,
      child: isPrimary ? primaryStyledButton : secondaryStyledButton,
    );
  }
}

class _SecondaryStyledButton extends StatelessWidget {
  const _SecondaryStyledButton({
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: color, width: 2.5),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        backgroundColor: Colors.white,
      ),
      icon: Icon(icon, color: color, size: 28),
      label: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: .bold,
          letterSpacing: 1,
        ),
      ),
      onPressed: onTap,
    );
  }
}

class _PrimaryStyledButton extends StatelessWidget {
  const _PrimaryStyledButton({
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      ),
      icon: Icon(icon, size: 32),
      label: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: .bold,
          letterSpacing: 1,
        ),
      ),
      onPressed: onTap,
    );
  }
}
