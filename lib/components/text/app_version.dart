import 'package:flutter/material.dart';

class AppVersion extends StatelessWidget {
  const AppVersion({super.key, required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) {
    return Text(
      appVersion,
      style: TextStyle(
        fontSize: 16,
        fontWeight: .w300,
        color: Colors.grey.shade500,
        letterSpacing: 4,
      ),
    );
  }
}
