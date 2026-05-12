import 'package:flutter/material.dart';
import 'package:ishi/screens/main_menu/menu_button.dart';

class RootMenu extends StatelessWidget {
  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final VoidCallback onProfile;

  const RootMenu({
    super.key,
    required this.onPlay,
    required this.onSettings,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuButton(
          title: "PLAY",
          icon: Icons.play_arrow_rounded,
          color: Colors.black87,
          isPrimary: true,
          onTap: onPlay,
        ),
        const SizedBox(height: 16),
        MenuButton(
          title: "SETTINGS",
          icon: Icons.settings,
          color: Colors.grey.shade800,
          onTap: onSettings,
        ),
        const SizedBox(height: 8),
        MenuButton(
          title: "EDIT PROFILE",
          icon: Icons.person,
          color: Colors.grey.shade800,
          onTap: onProfile,
        ),
      ],
    );
  }
}
