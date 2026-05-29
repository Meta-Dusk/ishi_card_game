import 'package:flutter/material.dart';
import 'package:ishi/components/gameplay/game_board/holographic_turn_track.dart';

class HolographicTrack extends StatelessWidget {
  final Size size;
  final double responsiveScale;
  final Color? color;
  final bool isReversed;

  const HolographicTrack({
    super.key,
    required this.size,
    required this.responsiveScale,
    this.color,
    required this.isReversed,
  });

  @override
  Widget build(BuildContext context) {
    final double tableWidth = size.width * 0.25;
    final double tableHeight = tableWidth;

    return Transform(
      alignment: FractionalOffset.center,
      transform: .identity()
        ..setEntry(3, 2, 0.0015)
        ..translateByVector3(.new(0.0, 0.0, -150.0))
        ..rotateX(-0.85),
      child: Container(
        width: tableWidth,
        height: tableHeight,
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
          size: tableHeight,
          isReversed: isReversed,
          color: color,
        ),
      ),
    );
  }
}
