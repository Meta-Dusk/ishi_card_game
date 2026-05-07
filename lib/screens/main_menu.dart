import 'package:flutter/material.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _playerCount = 2;
  int _startingHandSize = 7;

  @override
  Widget build(BuildContext context) {
    final playerCountSlider = Slider(
      value: _playerCount.toDouble(),
      min: 2,
      max: 10,
      divisions: 8,
      label: _playerCount.toString(),
      onChanged: (val) => setState(() => _playerCount = val.toInt()),
    );

    final mainContent = Column(
      mainAxisAlignment: .center,
      children: [
        const Text(
          "ISHI: THE UNOLIKE ROGUELIKE",
          style: TextStyle(fontSize: 48, fontWeight: .w900, letterSpacing: 2),
          textAlign: .center,
        ),
        const SizedBox(height: 50),
        SettingPanel(
          title: "Players: $_playerCount",
          icon: Icons.people,
          child: playerCountSlider,
        ),
        const SizedBox(height: 20),
        SettingPanel(
          title: "Starting Hand Size: $_startingHandSize",
          icon: Icons.style,
          child: Slider(
            value: _startingHandSize.toDouble(),
            min: 3,
            max: 15,
            divisions: 12,
            label: _startingHandSize.toString(),
            onChanged: (val) => setState(() => _startingHandSize = val.toInt()),
          ),
        ),
        const SizedBox(height: 50),
        StartButton(
          playerCount: _playerCount,
          startingHandSize: _startingHandSize,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: mainContent,
          ),
        ),
      ),
    );
  }
}

class StartButton extends StatelessWidget {
  const StartButton({
    super.key,
    required this.playerCount,
    required this.startingHandSize,
  });

  final int playerCount;
  final int startingHandSize;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const .symmetric(horizontal: 48, vertical: 16),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              playerCount: playerCount,
              startingHandSize: startingHandSize,
            ),
          ),
        );
      },
      child: const Text(
        "START RUN",
        style: TextStyle(fontSize: 20, fontWeight: .bold),
      ),
    );
  }
}

class SettingPanel extends StatelessWidget {
  const SettingPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: .bold)),
        ],
      ),
      child,
    ];
    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: mainContent),
    );
  }
}
