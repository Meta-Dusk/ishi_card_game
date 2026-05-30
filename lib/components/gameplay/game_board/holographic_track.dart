import 'package:flutter/material.dart';
import 'holographic_turn_track.dart';
import 'package:ishi/core/data_types.dart' show isPcPlatform;

class HolographicTrack extends StatelessWidget {
  final double radius;
  final Color? color;
  final bool isReversed;

  const HolographicTrack({
    super.key,
    required this.radius,
    this.color,
    required this.isReversed,
  });

  @override
  Widget build(BuildContext context) => Transform(
    alignment: FractionalOffset.center,
    transform: .identity()
      ..setEntry(3, 2, 0.0015)
      ..translateByVector3(.new(0.0, isPcPlatform() ? -68.0 : -40.0, -150.0))
      ..rotateX(-0.85),
    child: Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: .circle,
        gradient: RadialGradient(
          colors: [
            Colors.transparent,
            Colors.transparent,
            (color ?? Colors.white).withValues(alpha: 0.05),
            (color ?? Colors.white).withValues(alpha: 0.4),
            (color ?? Colors.white).withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.85, 0.92, 0.96, 0.99, 1.0],
        ),
      ),
      child: HolographicTurnTrack(
        size: radius,
        isReversed: isReversed,
        color: color,
      ),
    ),
  );
}
