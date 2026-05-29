import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/data_types.dart' show isPcPlatform;
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
    final mainContent = [
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
      if (isPcPlatform()) ...[
        const SizedBox(height: 8),
        MenuButton(
          title: "EXIT",
          icon: Icons.close_rounded,
          color: Colors.red,
          onTap: () => ServicesBinding.instance.exitApplication(.required),
        ),
      ],
    ];

    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
    );
  }
}
