import 'package:esther_gift/managers/game_manager.dart';
import 'package:flutter/material.dart';
import 'game_screen/game_screen.dart';
import 'host_lobby_screen.dart';
import 'join_game_screen.dart';

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
    final mainContent = [
      const Text(
        "ISHI: THE UNOLIKE ROGUELIKE",
        style: TextStyle(fontSize: 44, fontWeight: .w900, letterSpacing: 2),
        textAlign: .center,
      ),
      const SizedBox(height: 40),

      // --- LOCAL CO-OP SECTION ---
      const _SectionHeader(title: "LOCAL CO-OP"),
      const SizedBox(height: 16),
      _SettingPanel(
        title: "Players: $_playerCount",
        icon: Icons.people,
        child: Slider(
          value: _playerCount.toDouble(),
          min: 2,
          max: 10,
          divisions: 8,
          label: _playerCount.toString(),
          onChanged: (val) => setState(() => _playerCount = val.toInt()),
        ),
      ),
      const SizedBox(height: 16),
      _SettingPanel(
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
      const SizedBox(height: 24),
      _StartButton(
        playerCount: _playerCount,
        startingHandSize: _startingHandSize,
      ),

      const SizedBox(height: 48),

      // --- LAN MULTIPLAYER SECTION ---
      const _SectionHeader(title: "LAN MULTIPLAYER"),
      const SizedBox(height: 16),
      _LanMenuButton(
        title: "HOST LAN GAME",
        icon: Icons.router,
        color: Colors.green.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HostLobbyScreen()),
          );
        },
      ),
      const SizedBox(height: 16),
      _LanMenuButton(
        title: "JOIN LAN GAME",
        icon: Icons.qr_code_scanner,
        color: Colors.orange.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JoinGameScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const .symmetric(vertical: 24, horizontal: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisAlignment: .center, children: mainContent),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
      Padding(
        padding: const .symmetric(horizontal: 12.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: .bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
    ];
    return Row(children: mainContent);
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.playerCount,
    required this.startingHandSize,
  });

  final int playerCount;
  final int startingHandSize;

  void onStart(BuildContext context) {
    final manager = GameManager(
      playerCount: playerCount,
      startingHandSize: startingHandSize,
    );

    manager.initializeGame();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(manager: manager)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const .symmetric(horizontal: 48, vertical: 16),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        ),
        onPressed: () => onStart(context),
        child: const Text(
          "START LOCAL RUN",
          style: TextStyle(fontSize: 18, fontWeight: .bold, letterSpacing: 1),
        ),
      ),
    );
  }
}

class _LanMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _LanMenuButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: BorderSide(color: color, width: 2.5),
          shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          backgroundColor: Colors.white,
        ),
        icon: Icon(icon, color: color, size: 28),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: .bold,
            letterSpacing: 1,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _SettingPanel extends StatelessWidget {
  const _SettingPanel({
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
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: .bold)),
        ],
      ),
      const SizedBox(height: 8),
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
