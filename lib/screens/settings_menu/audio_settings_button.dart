import 'package:flutter/material.dart';

class AudioSettingsButton extends StatelessWidget {
  const AudioSettingsButton({super.key, required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
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
}
