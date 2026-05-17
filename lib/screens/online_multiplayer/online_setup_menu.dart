import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final mainContent = [
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
    ];

    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
    );
  }
}
