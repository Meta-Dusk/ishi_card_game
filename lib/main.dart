import 'package:flutter/material.dart';
import 'screens/main_menu.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
