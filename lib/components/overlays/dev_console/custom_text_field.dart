import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ishi/core/managers/dev_console.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.onFieldSubmitted,
  });

  final TextEditingController textController;
  final FocusNode focusNode;
  final VoidCallback onFieldSubmitted;

  KeyEventResult _handleKeyPress(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == .tab) {
      final currentText = textController.text;
      final suggestions = DevConsole().getSuggestions(currentText);

      if (suggestions.isNotEmpty) {
        // Autocomplete with the top suggestion and add a space!
        textController.text = "${suggestions.first} ";

        // Move the blinking cursor to the very end of the new text
        textController.selection = TextSelection.collapsed(
          offset: textController.text.length,
        );
      }

      // Return "handled" preventing the default focus shift
      return .handled;
    }

    // Let all other keys (like Enter, Backspace, letters) behave normally
    return .ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (_, event) => _handleKeyPress(event),
      child: TextField(
        controller: textController,
        focusNode: focusNode,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Enter command...",
          hintStyle: TextStyle(color: Colors.white30),
        ),
        onSubmitted: (value) {
          DevConsole().execute(value);
          textController.clear();
          focusNode.requestFocus(); // Keep keyboard open
        },
      ),
    );
  }
}
