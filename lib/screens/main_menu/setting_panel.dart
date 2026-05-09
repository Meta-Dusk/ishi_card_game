import 'package:flutter/material.dart';

class SettingPanel extends StatelessWidget {
  const SettingPanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Row(
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: .bold)),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ];
    return Container(
      padding: const .all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: .circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(children: mainContent),
    );
  }
}
