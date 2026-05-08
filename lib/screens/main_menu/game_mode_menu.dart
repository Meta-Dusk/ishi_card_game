import 'buttons.dart';
import 'menu_button.dart';
import 'section_header.dart';
import 'package:flutter/material.dart';

class GameModeMenu extends StatelessWidget {
  final VoidCallback onLocalTap;
  final VoidCallback onLanTap;
  final VoidCallback onBack;

  const GameModeMenu({
    super.key,
    required this.onLocalTap,
    required this.onLanTap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "SELECT GAME MODE"),
        const SizedBox(height: 16),
        MenuButton(
          title: "LOCAL DEVICE CO-OP",
          icon: Icons.devices,
          color: Colors.blue.shade700,
          onTap: onLocalTap,
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "LAN MULTIPLAYER",
          icon: Icons.wifi,
          color: Colors.green.shade700,
          onTap: onLanTap,
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onBack),
      ],
    );
  }
}
