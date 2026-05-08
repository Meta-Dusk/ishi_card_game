import 'package:esther_gift/managers/game_manager.dart';
import '../game_screen/game_screen.dart';
import 'buttons.dart';
import 'menu_button.dart';
import 'section_header.dart';
import 'setting_panel.dart';
import 'package:flutter/material.dart';

class LocalSetupMenu extends StatelessWidget {
  final int playerCount;
  final int startingHandSize;
  final ValueChanged<int> onPlayerCountChanged;
  final ValueChanged<int> onHandSizeChanged;
  final VoidCallback onBack;

  const LocalSetupMenu({
    super.key,
    required this.playerCount,
    required this.startingHandSize,
    required this.onPlayerCountChanged,
    required this.onHandSizeChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(title: "LOCAL SETUP"),
        const SizedBox(height: 16),
        SettingPanel(
          title: "Players: $playerCount",
          icon: Icons.people,
          child: Slider(
            value: playerCount.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: playerCount.toString(),
            onChanged: (val) => onPlayerCountChanged(val.toInt()),
          ),
        ),
        const SizedBox(height: 16),
        SettingPanel(
          title: "Starting Hand Size: $startingHandSize",
          icon: Icons.style,
          child: Slider(
            value: startingHandSize.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            label: startingHandSize.toString(),
            onChanged: (val) => onHandSizeChanged(val.toInt()),
          ),
        ),
        const SizedBox(height: 24),
        MenuButton(
          title: "START LOCAL RUN",
          icon: Icons.sports_esports,
          color: Colors.black87,
          isPrimary: true,
          onTap: () {
            final manager = GameManager(
              playerCount: playerCount,
              startingHandSize: startingHandSize,
            );
            manager.initializeGame();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GameScreen(manager: manager)),
            );
          },
        ),
        const SizedBox(height: 32),
        backButton(onPressed: onBack),
      ],
    );
  }
}
