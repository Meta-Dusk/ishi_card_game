import 'package:flutter/material.dart';

class CustomDropdownBox extends StatelessWidget {
  const CustomDropdownBox({
    super.key,
    required this.onSelected,
    required this.options,
  });

  final void Function(String) onSelected;
  final Iterable<String> options;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .topLeft,
      child: Material(
        color: Colors.grey.shade900,
        child: SizedBox(
          width: 250,
          child: ListView.builder(
            padding: .zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (_, index) => _DropdownOption(
              options: options,
              index: index,
              onSelected: onSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownOption extends StatelessWidget {
  const _DropdownOption({
    required this.options,
    required this.index,
    required this.onSelected,
  });

  final Iterable<String> options;
  final int index;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    final option = options.elementAt(index);
    return ListTile(
      title: Text(option, style: const TextStyle(color: Colors.white)),
      onTap: () => onSelected(option),
    );
  }
}
