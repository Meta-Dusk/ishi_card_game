import 'package:flutter/material.dart';

class DevConsoleToggleDialog extends StatelessWidget {
  const DevConsoleToggleDialog({
    super.key,
    required this.showDevConsole,
    required this.onChanged,
  });

  final bool showDevConsole;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Dev Console"),
      content: const Text("You can enable/disable the console here."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            onChanged(!showDevConsole);
          },
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          ),
          child: Text(!showDevConsole ? "Enable" : "Disable"),
        ),
      ],
    );
  }
}
