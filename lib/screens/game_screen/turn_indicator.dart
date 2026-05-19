import 'dart:async';

import 'package:flutter/material.dart';

class TurnIndicator extends StatefulWidget {
  const TurnIndicator({
    super.key,
    required this.isMyTurn,
    required this.turnDeadlineEpoch,
    this.fontSize = 32,
  });

  final bool isMyTurn;
  final int turnDeadlineEpoch;
  final double fontSize;

  @override
  State<TurnIndicator> createState() => _TurnIndicatorState();
}

class _TurnIndicatorState extends State<TurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Timer _uiTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = (widget.turnDeadlineEpoch - now) ~/ 1000;
    setState(() => _secondsLeft = remaining > 0 ? remaining : 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _uiTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: .center,
    child: Column(
      children: [
        _turnIndicator(),
        _TimerText(secondsLeft: _secondsLeft, fontSize: widget.fontSize * 0.6),
      ],
    ),
  );

  StatelessWidget _turnIndicator() => widget.isMyTurn
      ? _YourTurnText(controller: _controller, fontSize: widget.fontSize)
      : _OpponentTurnText(fontSize: widget.fontSize);
}

class _TimerText extends StatelessWidget {
  const _TimerText({required this.secondsLeft, required this.fontSize});

  final int secondsLeft;
  final double fontSize;

  String get timeString => "00:${secondsLeft.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) => Text(
    timeString,
    style: TextStyle(
      color: secondsLeft <= 5 ? Colors.redAccent : Colors.white70,
      fontSize: fontSize,
      fontWeight: .bold,
      letterSpacing: 2,
    ),
  );
}

class _OpponentTurnText extends StatelessWidget {
  const _OpponentTurnText({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
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

class _YourTurnText extends StatelessWidget {
  const _YourTurnText({required this.controller, required this.fontSize});

  final AnimationController controller;
  final double fontSize;

  @override
  Widget build(BuildContext context) => FadeTransition(
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
