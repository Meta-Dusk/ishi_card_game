import '../host_lobby_screen.dart';
import '../join_game_screen.dart';
import 'buttons.dart';
import 'menu_button.dart';
import 'section_header.dart';
import 'package:flutter/material.dart';

class LanSetupMenu extends StatelessWidget {
  final VoidCallback onBack;
  const LanSetupMenu({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "LAN MULTIPLAYER"),
        const SizedBox(height: 16),
        MenuButton(
          title: "HOST LAN GAME",
          icon: Icons.router,
          color: Colors.green.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
          ),
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "JOIN LAN GAME",
          icon: Icons.qr_code_scanner,
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinGameScreen()),
          ),
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onBack),
      ],
    );
  }
}
