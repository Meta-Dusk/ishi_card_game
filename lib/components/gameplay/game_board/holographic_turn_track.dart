import 'dart:math';
import 'package:flutter/material.dart';

class HolographicTurnTrack extends StatefulWidget {
  final double size;
  final bool isReversed;
  final Color? color;

  const HolographicTurnTrack({
    super.key,
    required this.size,
    required this.isReversed,
    this.color,
  });

  @override
  State<HolographicTurnTrack> createState() => _HolographicTurnTrackState();
}

class _HolographicTurnTrackState extends State<HolographicTurnTrack>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _cumulativeAngle = 0.0;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      final now = DateTime.now();
      final dt = now.difference(_lastUpdate).inMilliseconds / 1000.0;
      _lastUpdate = now;

      if (mounted) {
        setState(() {
          // Speed: radians per second.
          // Reversing simply negates the speed, allowing a perfectly smooth turnaround!
          final speed = pi / 3.5;
          _cumulativeAngle += widget.isReversed ? -speed * dt : speed * dt;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: _cumulativeAngle,
    child: Stack(
      alignment: .center,
      children: List.generate(
        4,
        (index) => Transform.rotate(
          angle: (pi / 2) * index,
          child: Align(
            alignment: .topCenter,
            child: CustomPaint(
              size: const Size(40, 20),
              painter: _HolographicArrowPainter(
                color: widget.color,
                isReversed: widget.isReversed,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _HolographicArrowPainter extends CustomPainter {
  const _HolographicArrowPainter({this.color, required this.isReversed});

  final Color? color;
  final bool isReversed;

  @override
  void paint(Canvas canvas, Size size) {
    if (isReversed) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(-1.0, 1.0);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    final arrowColor = color ?? Colors.white;
    final paint = Paint()
      ..color = arrowColor.withValues(alpha: 0.8)
      ..style = .stroke
      ..strokeWidth = 4.0
      ..strokeCap = .round
      ..strokeJoin = .round;

    final path = Path();

    // Draws a wide, flat chevron pointing arrow
    // Left Top
    path.moveTo(0, 0);
    // Center Tip
    path.lineTo(size.width, size.height / 2);
    // Left Bottom
    path.lineTo(0, size.height);

    canvas.drawPath(path, paint);

    // Draws a smaller secondary chevron inside it for a "double arrow" look
    final innerPath = Path();
    innerPath.moveTo(0 - 12.0, 0 + 4.0);
    innerPath.lineTo(size.width - 12.0, size.height / 2);
    innerPath.lineTo(0 - 12.0, size.height - 4.0);

    paint.strokeWidth = 2.0;
    paint.color = arrowColor.withValues(alpha: 0.4);
    canvas.drawPath(innerPath, paint);

    if (isReversed) canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolographicArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isReversed != isReversed;
}
