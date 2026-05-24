import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/dialogs/menus/settings_dialog.dart';
import 'package:ishi/core/audio.dart';
import 'package:ishi/core/managers/audio_manager.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/screens/main_menu/buttons.dart';
import 'package:ishi/screens/settings_menu/settings_header.dart';

class SettingsMenu extends StatelessWidget {
  final VoidCallback onBack;
  const SettingsMenu({super.key, required this.onBack});

  Future<void> _resetPreferences(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmationDialog(),
    );

    if (confirm != true) return;
    await ProfileManager().resetToDefaults();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Preferences reset to default.",
          style: TextStyle(fontWeight: .bold),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const SettingsHeader(),
      const SizedBox(height: 24),
      _AudioSettingsButton(
        onShow: () => showDialog(
          context: context,
          builder: (_) => const SettingsDialog()
              .animate()
              .fadeIn(duration: 200.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
        ),
      ),
      const SizedBox(height: 24),
      _ResetButton(
        onReset: () {
          AudioManager().playSFX(Audio.sfx.itemSelect);
          _resetPreferences(context);
        },
      ),
      const SizedBox(height: 40),
      textBackButton(onPressed: onBack),
    ];
    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
    );
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog();

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: Colors.grey.shade900,
    title: const Text(
      "Reset Preferences?",
      style: TextStyle(color: Colors.white, fontWeight: .bold),
    ),
    content: const Text(
      "This will reset your avatar color and "
      "player name back to their default states.",
      style: TextStyle(color: Colors.white70),
    ),
    actions: [
      TextButton(
        onPressed: () {
          AudioManager().playSFX(Audio.sfx.itemSelect);
          Navigator.pop(context, false);
        },
        child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          AudioManager().playSFX(Audio.sfx.itemSelect);
          Navigator.pop(context, true);
        },
        child: const Text("RESET"),
      ),
    ],
  );
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 60,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent.shade700,
        side: BorderSide(color: Colors.redAccent.shade700, width: 2),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      ),
      icon: const Icon(Icons.delete_forever),
      label: const Text(
        "RESET ALL PREFERENCES",
        style: TextStyle(fontSize: 18, fontWeight: .bold, letterSpacing: 1),
      ),
      onPressed: onReset,
    ),
  );
}

class _AudioSettingsButton extends StatelessWidget {
  const _AudioSettingsButton({required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 60,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: .circular(12)),
      ),
      icon: const Icon(Icons.multitrack_audio_rounded),
      label: const Text(
        "AUDIO SETTINGS",
        style: TextStyle(fontSize: 18, fontWeight: .bold, letterSpacing: 1),
      ),
      onPressed: onShow,
    ),
  );
}
