import 'package:flutter/material.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/screens/main_menu/buttons.dart';

class SettingsMenu extends StatelessWidget {
  final VoidCallback onBack;
  const SettingsMenu({super.key, required this.onBack});

  Future<void> _resetPreferences(BuildContext context) async {
    // Show a confirmation dialog to prevent accidental wipes
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmationDialog(),
    );

    // If they clicked "RESET", wipe the database
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
      const _SettingsHeader(),
      const SizedBox(height: 24),
      _ResetButton(onReset: () => _resetPreferences(context)),
      const SizedBox(height: 40),
      backButton(onPressed: onBack),
    ];
    return Column(children: mainContent);
  }
}

class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("RESET"),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent, width: 2),
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
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
      Padding(
        padding: const .symmetric(horizontal: 12.0),
        child: Text(
          "SETTINGS",
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
