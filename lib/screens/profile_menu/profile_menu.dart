import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'color_selection.dart';
import 'edit_profile_header.dart';
import 'save_profile_button.dart';

class ProfileMenu extends StatefulWidget {
  final VoidCallback onBack;
  const ProfileMenu({super.key, required this.onBack});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  late TextEditingController _nameController;
  late String _selectedColorName;

  @override
  void initState() {
    super.initState();
    // Load the existing data into the UI
    _nameController = TextEditingController(text: ProfileManager().playerName);
    _selectedColorName = ProfileManager().avatarColorName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    String newName = _nameController.text.trim();
    if (newName.isEmpty) newName = "Player";

    await ProfileManager().saveProfile(newName, _selectedColorName);
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      EditProfileHeader(),
      const SizedBox(height: 24),

      // --- NAME INPUT ---
      TextField(
        controller: _nameController,
        maxLength: 12,
        textAlign: .center,
        style: const TextStyle(fontSize: 24, fontWeight: .bold),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          hintText: "Enter Name",
          border: OutlineInputBorder(
            borderRadius: .circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const .symmetric(vertical: 20),
        ),
      ),
      const SizedBox(height: 24),

      // --- COLOR PICKER ---
      Column(
        mainAxisSize: .min,
        children: [
          const Text(
            "AVATAR COLOR",
            style: TextStyle(fontWeight: .bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          _ColorSelections(
            onSelect: (entry) => setState(() => _selectedColorName = entry.key),
            selectedColorName: _selectedColorName,
          ),
        ],
      ),

      const SizedBox(height: 40),

      // --- BUTTONS ---
      SaveProfileButton(onSaveProfile: _saveAndExit),
      const SizedBox(height: 16),
      _BackButton(onBack: widget.onBack),
    ];
    return Column(
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
      icon: const Icon(Icons.arrow_back),
      label: const Text(
        "BACK",
        style: TextStyle(fontWeight: .bold, letterSpacing: 1),
      ),
      onPressed: onBack,
    );
  }
}

class _ColorSelections extends StatelessWidget {
  const _ColorSelections({
    required this.onSelect,
    required this.selectedColorName,
  });

  final String selectedColorName;
  final void Function(MapEntry<String, Color>) onSelect;

  @override
  Widget build(BuildContext context) {
    final mappedColors = avatarColorPalette.entries.map((entry) {
      return ColorSelection(
        colorValue: entry.value,
        isSelected: selectedColorName == entry.key,
        onSelect: () => onSelect(entry),
      );
    });

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: .center,
      children: mappedColors.toList(),
    );
  }
}
