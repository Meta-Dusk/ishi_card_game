import 'package:flutter/material.dart';

Widget backButton({required VoidCallback onPressed}) => TextButton.icon(
  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
  icon: const Icon(Icons.arrow_back),
  label: const Text(
    "BACK",
    style: TextStyle(fontWeight: .bold, letterSpacing: 1),
  ),
  onPressed: onPressed,
);
