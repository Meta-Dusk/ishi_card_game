import 'buttons.dart';
import 'menu_button.dart';
import 'section_header.dart';
import 'package:flutter/material.dart';

class GameModeMenu extends StatelessWidget {
  final VoidCallback onLocalTap;
  final VoidCallback onLanTap;
  final VoidCallback onOnlineTap;
  final VoidCallback onBack;

  const GameModeMenu({
    super.key,
    required this.onLocalTap,
    required this.onLanTap,
    required this.onOnlineTap,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "SELECT GAME MODE"),
        _buttonSpacer(),
        MenuButton(
          title: "LOCAL DEVICE CO-OP",
          icon: Icons.devices,
          color: Colors.blue.shade700,
          onTap: onLocalTap,
        ),
        _buttonSpacer(),
        MenuButton(
          title: "LAN MULTIPLAYER",
          icon: Icons.wifi,
          color: Colors.green.shade700,
          onTap: onLanTap,
        ),
        _buttonSpacer(),
        MenuButton(
          title: "ONLINE MULTIPLAYER",
          icon: Icons.public,
          color: Colors.blueAccent,
          onTap: onOnlineTap,
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onBack),
      ],
    );
  }

  SizedBox _buttonSpacer() => const SizedBox(height: 16);
}
