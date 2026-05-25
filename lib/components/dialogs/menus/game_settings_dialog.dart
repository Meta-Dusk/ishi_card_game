import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/screens/game_screen/imports/game_components.dart';

class GameSettingsDialog extends StatelessWidget {
  final VoidCallback onExitGame;
  final VoidCallback onDevConsoleToggle;
  final bool showDevConsoleToggle;

  const GameSettingsDialog({
    super.key,
    required this.onExitGame,
    required this.onDevConsoleToggle,
    required this.showDevConsoleToggle,
  });

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: const Row(
        children: [
          Icon(Icons.settings, color: Colors.white),
          SizedBox(width: 16),
          Text("Settings", style: TextStyle(color: Colors.white)),
        ],
      ),
      titlePadding: .all(16),
      content: _dialogContent(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  ButtonStyle get _outlinedButtonStyle => OutlinedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    side: const BorderSide(color: Colors.black, width: 1),
    shape: RoundedRectangleBorder(borderRadius: .circular(12)),
  );

  Column _dialogContent(BuildContext context) {
    final buttons = [
      SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton.icon(
          style: _outlinedButtonStyle,
          icon: const Icon(Icons.multitrack_audio_rounded),
          label: const Row(
            mainAxisAlignment: .center,
            children: [
              Text(
                "AUDIO SETTINGS",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: .bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const AudioSettingsDialog(),
          ),
        ),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton.icon(
          style: _outlinedButtonStyle,
          icon: const Icon(Icons.exit_to_app_rounded),
          label: const Row(
            mainAxisAlignment: .center,
            children: [
              Text(
                "LEAVE GAME",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: .bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          onPressed: onExitGame,
        ),
      ),
      if (showDevConsoleToggle) ...[
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            style: _outlinedButtonStyle,
            icon: const Icon(Icons.terminal),
            label: const Row(
              mainAxisAlignment: .center,
              children: [
                Text(
                  "OPEN DEV CONSOLE",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: .bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            onPressed: onDevConsoleToggle,
          ),
        ),
      ],
    ];

    return Column(
      mainAxisAlignment: .center,
      mainAxisSize: .min,
      children: buttons
          .animate(interval: 100.ms, delay: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
    );
  }
}
