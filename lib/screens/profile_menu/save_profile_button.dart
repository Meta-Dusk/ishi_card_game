import 'package:flutter/material.dart';

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
