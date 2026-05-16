import 'package:flutter/material.dart';
import 'host_online_screen.dart';
import 'join_online_screen.dart';
import '../main_menu/buttons.dart';
import '../main_menu/menu_button.dart';
import '../main_menu/section_header.dart';

class OnlineSetupMenu extends StatelessWidget {
  final VoidCallback onPrimaryBack;
  final void Function(BuildContext) onSecondaryBack;

  const OnlineSetupMenu({
    super.key,
    required this.onPrimaryBack,
    required this.onSecondaryBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "ONLINE MULTIPLAYER"),
        const SizedBox(height: 16),
        MenuButton(
          title: "HOST ONLINE GAME",
          icon: Icons.public,
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HostOnlineScreen(onBack: onSecondaryBack),
            ),
          ),
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "JOIN ONLINE GAME",
          icon: Icons.keyboard,
          color: Colors.purple.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JoinOnlineScreen(onBack: onSecondaryBack),
            ),
          ),
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onPrimaryBack),
      ],
    );
  }
}
