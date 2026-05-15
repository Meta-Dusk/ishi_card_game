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
    return IconButton(
      icon: Icon(showPingOverlay ? Icons.close : Icons.network_ping),
      color: Colors.grey.shade600,
      onPressed: onToggle,
    );
  }
}
