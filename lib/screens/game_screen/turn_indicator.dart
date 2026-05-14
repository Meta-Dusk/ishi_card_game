import 'package:flutter/material.dart';

class TurnIndicator extends StatefulWidget {
  const TurnIndicator({super.key, required this.isMyTurn, this.fontSize = 32});
  final bool isMyTurn;
  final double fontSize;

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .center,
      child: widget.isMyTurn
          ? _YourTurnText(controller: _controller, fontSize: widget.fontSize)
          : _OpponentTurnText(fontSize: widget.fontSize),
    );
  }
}

class _OpponentTurnText extends StatelessWidget {
  const _OpponentTurnText({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      "WAITING...",
      style: TextStyle(
        color: Colors.orangeAccent,
        fontSize: fontSize,
        fontWeight: .bold,
        letterSpacing: 4,
        shadows: const [BoxShadow(color: Colors.black, blurRadius: 4)],
      ),
    );
  }
}

class _YourTurnText extends StatelessWidget {
  const _YourTurnText({required this.controller, required this.fontSize});

  final AnimationController controller;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(controller),
      child: Text(
        "YOUR TURN",
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: fontSize,
          fontWeight: .bold,
          letterSpacing: 4,
          shadows: const [BoxShadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    );
  }
}
