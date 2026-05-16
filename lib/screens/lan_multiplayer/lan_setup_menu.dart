import 'package:flutter/material.dart';
import 'host_lan_screen.dart';
import 'join_lan_screen.dart';
import '../main_menu/buttons.dart';
import '../main_menu/menu_button.dart';
import '../main_menu/section_header.dart';

class LanSetupMenu extends StatelessWidget {
  final VoidCallback onPrimaryBack;
  final void Function(BuildContext) onSecondaryBack;

  const LanSetupMenu({
    super.key,
    required this.onPrimaryBack,
    required this.onSecondaryBack,
  });

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
            MaterialPageRoute(
              builder: (_) => HostLANLobbyScreen(onBack: onSecondaryBack),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "JOIN LAN GAME",
          icon: Icons.qr_code_scanner,
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JoinLANGameScreen(onBack: onSecondaryBack),
            ),
          ),
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onPrimaryBack),
      ],
    );
  }
}
