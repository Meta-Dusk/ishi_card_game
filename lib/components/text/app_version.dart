import 'package:flutter/material.dart';

class AppVersion extends StatelessWidget {
  const AppVersion({super.key, required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context) => Text(
    appVersion,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: .w300,
      color: Colors.blueGrey,
      letterSpacing: 4,
    ),
  );
}
