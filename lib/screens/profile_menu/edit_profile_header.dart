import 'package:flutter/material.dart';

class EditProfileHeader extends StatelessWidget {
  const EditProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
      Padding(
        padding: const .symmetric(horizontal: 12.0),
        child: Text(
          "EDIT PROFILE",
          style: TextStyle(
            fontSize: 14,
            fontWeight: .bold,
            color: Colors.grey.shade600,
            letterSpacing: 1.5,
          ),
        ),
      ),
      Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
    ];
    return Row(children: mainContent);
  }
}
