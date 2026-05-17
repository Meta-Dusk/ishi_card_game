import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HostView extends StatelessWidget {
  const HostView({
    super.key,
    required this.startingHandSize,
    required this.onHandSizeChanged,
    required this.onSettingsChangeEnd,
    required this.maxPlayers,
    required this.absoluteMaxPlayers,
    required this.connectedPlayers,
    required this.onMaxPlayersChanged,
  });

  final int startingHandSize;
  final ValueChanged<int> onHandSizeChanged;
  final VoidCallback onSettingsChangeEnd;
  final int maxPlayers;
  final int absoluteMaxPlayers;
  final int connectedPlayers;
  final ValueChanged<int> onMaxPlayersChanged;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      _startingHandSizeHeader(),
      _startingHandSizeSlider(),
      const SizedBox(height: 8),
      _maxPlayersHeader(),
      _maxPlayerSlider(),
    ];

    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: .circular(16),
        border: .all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: mainContent
            .animate(interval: 100.ms)
            .fadeIn(duration: 300.ms)
            .slideY(delay: 100.ms, begin: -0.5, curve: Curves.easeOutCubic),
      ),
    );
  }

  Row _maxPlayersHeader() => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      const Text(
        "MAX PLAYERS:",
        style: TextStyle(color: Colors.white70, fontWeight: .bold),
      ),
      Text(
        "$maxPlayers",
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 18,
          fontWeight: .bold,
        ),
      ),
    ],
  );

  Row _startingHandSizeHeader() => Row(
    mainAxisAlignment: .spaceBetween,
    children: [
      const Text(
        "STARTING CARDS:",
        style: TextStyle(color: Colors.white70, fontWeight: .bold),
      ),
      Text(
        "$startingHandSize",
        style: const TextStyle(
          color: Colors.orangeAccent,
          fontSize: 18,
          fontWeight: .bold,
        ),
      ),
    ],
  );

  Slider _maxPlayerSlider() => Slider(
    value: maxPlayers.toDouble(),
    min: 2,
    max: absoluteMaxPlayers.toDouble(),
    divisions: absoluteMaxPlayers - 2,
    activeColor: Colors.greenAccent,
    onChanged: (val) {
      if (val.toInt() >= connectedPlayers) {
        onMaxPlayersChanged(val.toInt());
      }
    },
    onChangeEnd: (_) => onSettingsChangeEnd(),
  );

  Slider _startingHandSizeSlider() => Slider(
    value: startingHandSize.toDouble(),
    min: 3,
    max: 15,
    divisions: 12,
    activeColor: Colors.orangeAccent,
    onChanged: (val) => onHandSizeChanged(val.toInt()),
    onChangeEnd: (_) => onSettingsChangeEnd(),
  );
}
