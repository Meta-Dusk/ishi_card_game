import 'package:flutter/material.dart';

class MiniFaceDownCard extends StatelessWidget {
  const MiniFaceDownCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      widthFactor: 0.6,
      alignment: .centerLeft,
      child: Container(
        width: 30,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: .circular(4),
          border: .all(color: Colors.grey.shade900, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 3,
              offset: Offset(-2, 2),
            ),
          ],
        ),
        alignment: .center,
        child: Text("IS", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
