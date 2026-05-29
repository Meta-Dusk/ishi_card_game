import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DevConsoleToggleDialog extends StatelessWidget {
  const DevConsoleToggleDialog({
    super.key,
    required this.showDevConsole,
    required this.onToggle,
  });

  final bool showDevConsole;
  final void Function(bool isToggled) onToggle;

  Widget _animatedDialog(AlertDialog dialog) => dialog
      .animate()
      .fadeIn(duration: 200.ms)
      .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);

  @override
  Widget build(BuildContext context) => _animatedDialog(
    AlertDialog(
      title: const Text("Dev Console", style: TextStyle(color: Colors.black)),
      content: const Text(
        "You can enable/disable the console here.",
        style: TextStyle(color: Colors.blueGrey),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close", style: TextStyle(color: Colors.black)),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onToggle(!showDevConsole);
          },
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          ),
          child: Text(!showDevConsole ? "Enable" : "Disable"),
        ),
      ],
    ),
  );
}
