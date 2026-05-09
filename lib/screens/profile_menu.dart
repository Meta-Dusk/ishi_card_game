import 'package:flutter/material.dart';
import 'package:ishi/core/managers/profile_manager.dart';

class ProfileMenu extends StatefulWidget {
  final VoidCallback onBack;
  const ProfileMenu({super.key, required this.onBack});

  @override
  State<ProfileMenu> createState() => _ProfileMenuState();
}

class _ProfileMenuState extends State<ProfileMenu> {
  late TextEditingController _nameController;
  late Color _selectedColor;

  final List<Color> _availableColors = [
    Colors.blue.shade600,
    Colors.red.shade600,
    Colors.green.shade600,
    Colors.orange.shade600,
    Colors.purple.shade600,
    Colors.pink.shade600,
  ];

  @override
  void initState() {
    super.initState();
    // Load the existing data into the UI
    _nameController = TextEditingController(text: ProfileManager().playerName);
    _selectedColor = ProfileManager().avatarColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    String newName = _nameController.text.trim();
    if (newName.isEmpty) newName = "Player"; // Fallback

    await ProfileManager().saveProfile(newName, _selectedColor);
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey.shade400, thickness: 1.5),
            ),
            Padding(
              padding: const .symmetric(horizontal: 12.0),
              child: Text(
                "EDIT PROFILE",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: .bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey.shade400, thickness: 1.5),
            ),
          ],
        ),
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
              borderSide: .none,
            ),
            contentPadding: const .symmetric(vertical: 20),
          ),
        ),
        const SizedBox(height: 24),

        // --- COLOR PICKER ---
        const Text(
          "AVATAR COLOR",
          style: TextStyle(fontWeight: .bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: .center,
          children: _availableColors.map((color) {
            bool isSelected = _selectedColor.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: .circle,
                  border: .all(
                    color: isSelected ? Colors.black87 : Colors.transparent,
                    width: isSelected ? 4 : 0,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 40),

        // --- BUTTONS ---
        SaveProfileButton(onSaveProfile: _saveAndExit),
        const SizedBox(height: 16),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
          icon: const Icon(Icons.arrow_back),
          label: const Text(
            "CANCEL",
            style: TextStyle(fontWeight: .bold, letterSpacing: 1),
          ),
          onPressed: widget.onBack,
        ),
      ],
    );
  }
}

class SaveProfileButton extends StatelessWidget {
  const SaveProfileButton({super.key, required this.onSaveProfile});

  final VoidCallback onSaveProfile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        ),
        icon: const Icon(Icons.save),
        label: const Text(
          "SAVE PROFILE",
          style: TextStyle(fontSize: 18, fontWeight: .bold, letterSpacing: 1),
        ),
        onPressed: onSaveProfile,
      ),
    );
  }
}
