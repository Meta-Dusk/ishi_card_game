import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'buttons.dart';
import 'menu_button.dart';
import 'section_header.dart';

class GameModeMenu extends StatelessWidget {
  final VoidCallback onLocalTap;
  final VoidCallback onLanTap;
  final VoidCallback onOnlineTap;
  final VoidCallback onBack;
  final bool showLocalMultiplayer;

  const GameModeMenu({
    super.key,
    required this.onLocalTap,
    required this.onLanTap,
    required this.onOnlineTap,
    required this.onBack,
    required this.showLocalMultiplayer,
  });

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const SectionHeader(title: "SELECT GAME MODE"),
      if (showLocalMultiplayer) ...[
        _buttonSpacer(),
        MenuButton(
          title: "LOCAL DEVICE CO-OP",
          icon: Icons.devices,
          color: Colors.deepPurple,
          onTap: onLocalTap,
        ),
      ],
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
      textBackButton(onPressed: onBack),
    ];

    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }

  SizedBox _buttonSpacer() => const SizedBox(height: 16);
}
