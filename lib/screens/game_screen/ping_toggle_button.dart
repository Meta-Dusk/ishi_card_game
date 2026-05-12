import 'package:flutter/material.dart';

class PingToggleButton extends StatelessWidget {
  const PingToggleButton({
    super.key,
    required this.showPingOverlay,
    required this.onToggle,
  });

  final bool showPingOverlay;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: IconButton(
        icon: Icon(showPingOverlay ? Icons.close : Icons.network_ping),
        color: Colors.grey.shade800,
        onPressed: onToggle,
      ),
    );
  }
}
