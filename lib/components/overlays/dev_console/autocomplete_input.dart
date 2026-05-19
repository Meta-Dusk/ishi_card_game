import 'package:flutter/material.dart';
import 'package:ishi/core/dev/dev_console.dart';
import 'dev_console_overlay.dart';
import 'custom_dropdown_box.dart';
import 'custom_text_field.dart';

class AutocompleteInput extends StatelessWidget {
  const AutocompleteInput({super.key, required this.devConsoleOverlay});

  final DevConsoleOverlay devConsoleOverlay;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        ">",
        style: TextStyle(
          color: Colors.greenAccent,
          fontWeight: .bold,
          fontSize: 18,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Autocomplete<String>(
          optionsBuilder: (textEditingValue) =>
              DevConsole().getSuggestions(textEditingValue.text),
          onSelected: (selection) {
            // Optional: Execute immediately upon tapping the suggestion,
            // or just let it populate the text field to add arguments.
          },
          optionsViewBuilder: (_, onSelected, options) =>
              CustomDropdownBox(onSelected: onSelected, options: options),
          fieldViewBuilder: (_, textController, focusNode, onFieldSubmitted) =>
              CustomTextField(
                textController: textController,
                focusNode: focusNode,
                onFieldSubmitted: onFieldSubmitted,
              ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        onPressed: devConsoleOverlay.onClose,
        tooltip: "Close Dev Console",
      ),
    ];

    return Container(
      color: Colors.black,
      padding: const .symmetric(horizontal: 8, vertical: 4),
      child: Row(children: mainContent),
    );
  }
}
