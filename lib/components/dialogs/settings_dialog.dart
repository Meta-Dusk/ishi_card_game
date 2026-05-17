import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/managers/audio_manager.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _masterVol;
  late double _bgmVol;
  late double _sfxVol;

  @override
  void initState() {
    super.initState();
    _masterVol = AudioManager().masterVolume;
    _bgmVol = AudioManager().musicVolume;
    _sfxVol = AudioManager().sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      title: const Row(
        children: [
          Icon(Icons.multitrack_audio_rounded, color: Colors.white),
          SizedBox(width: 16),
          Text("Audio Settings", style: TextStyle(color: Colors.white)),
        ],
      ),
      titlePadding: .all(16),
      content: _settingsSliders(),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Column _settingsSliders() {
    final mainContent = [
      _VolumeSlider(
        label: "Master Volume",
        icon: Icons.volume_up,
        value: _masterVol,
        onChanged: (val) {
          setState(() => _masterVol = val);
          AudioManager().setMasterVolume(val);
        },
      ),
      _VolumeSlider(
        label: "Music",
        icon: Icons.music_note,
        value: _bgmVol,
        onChanged: (val) {
          setState(() => _bgmVol = val);
          AudioManager().setMusicVolume(val);
        },
      ),
      _VolumeSlider(
        label: "Sound Effects",
        icon: Icons.speaker,
        value: _sfxVol,
        onChanged: (val) {
          setState(() => _sfxVol = val);
          AudioManager().setSfxVolume(val);
        },
      ),
    ];

    return Column(
      mainAxisSize: .min,
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            "${(value * 100).toInt()}%",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      Slider(
        value: value,
        min: 0.0,
        max: 1.0,
        activeColor: Colors.orangeAccent,
        inactiveColor: Colors.white24,
        onChanged: onChanged,
      ),
      const SizedBox(height: 8),
    ];

    return Column(crossAxisAlignment: .start, children: mainContent);
  }
}
