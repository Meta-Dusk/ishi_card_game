import 'package:flutter/material.dart';
import 'screens/main_menu/main_menu_screen.dart';

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
