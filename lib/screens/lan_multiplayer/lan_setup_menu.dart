import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final mainContent = [
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
    ];

    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
    );
  }
}
