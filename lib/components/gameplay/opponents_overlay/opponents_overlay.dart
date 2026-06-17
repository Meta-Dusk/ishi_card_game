import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/managers/game/game_manager.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/services/network_service.dart';
import 'animated_card_fan.dart';
import 'animated_turn_arrow.dart';
import 'opponent_stats.dart';

class OpponentsOverlay extends StatelessWidget {
  const OpponentsOverlay({
    super.key,
    required this.manager,
    required this.net,
    required this.listKeys,
    required this.scale,
  });

  final GameManager manager;
  final NetworkService net;
  final Map<int, GlobalKey<AnimatedListState>> listKeys;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final centerX = size.width / 2;
    final centerY = (size.height / 2) - (80 * scale);

    final radiusX = size.width * 0.42;
    final radiusY = size.height * 0.28;

    List<Widget> positionedOpponents = [];
    final totalPlayers = manager.playerCount;

    double crowdScale = 1.0 + ((8 - totalPlayers) * 0.08);
    crowdScale = crowdScale.clamp(0.6, 1.6);

    for (int i = 0; i < totalPlayers; i++) {
      if (i == manager.localPlayerIndex) continue;

      int relativeSeat = (i - manager.localPlayerIndex) % totalPlayers;
      if (relativeSeat < 0) relativeSeat += totalPlayers;

      double angleStep = (2 * pi) / totalPlayers;
      double angle = (pi / 2) + (relativeSeat * angleStep);

      // The specific angle this seat needs to rotate to face the center
      double facingAngle = relativeSeat * angleStep;

      double x = centerX + radiusX * cos(angle);
      double y = centerY + radiusY * sin(angle);

      // Horizontal Edge Spread
      double edgeProximity = cos(angle).abs();
      double verticalSpread = sin(angle) * edgeProximity * (90 * scale);

      y += verticalSpread;

      double normalizedY = (sin(angle) + 1) / 2;
      double depthScale = (0.6 + (0.4 * normalizedY)) * scale * crowdScale;

      String name = "Player ${i + 1}";
      Color color = ProfileManager().avatarColor;
      if (i < net.playersList.length) {
        final player = net.playersList[i];
        name = player.playerName;
        color = ProfileManager().getAvatarColor(player.avatarColorName);
      }

      final int opponentHandSize = manager.opponentHandSizes.length > i
          ? manager.opponentHandSizes[i]
          : 0;
      final int currentHandSize = net.isHost
          ? manager.playerHands[i].length
          : opponentHandSize;

      final bool isTurn = manager.currentPlayer == (i + 1);

      final positionedOpponent = _PositionedOpponent(
        yCoord: y,
        child: Positioned(
          left: x - 120,
          top: y - 120,
          width: 240,
          height: 240,
          child: Transform.scale(
            scale: depthScale,
            child: _OpponentSeat(
              isTurn: isTurn,
              name: name,
              color: color,
              manager: manager,
              playerIndex: i,
              handSize: currentHandSize,
              listKeys: listKeys,
              facingAngle: facingAngle,
            ),
          ),
        ),
      );
      positionedOpponents.add(positionedOpponent);
    }

    positionedOpponents.sort(
      (a, b) => (a as _PositionedOpponent).yCoord.compareTo(
        (b as _PositionedOpponent).yCoord,
      ),
    );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: .none,
        children: positionedOpponents
            .map((e) => (e as _PositionedOpponent).child)
            .toList(),
      ),
    );
  }
}

class _PositionedOpponent extends StatelessWidget {
  final double yCoord;
  final Widget child;
  const _PositionedOpponent({required this.yCoord, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _OpponentSeat extends StatelessWidget {
  const _OpponentSeat({
    required this.isTurn,
    required this.name,
    required this.color,
    required this.manager,
    required this.playerIndex,
    required this.handSize,
    required this.listKeys,
    required this.facingAngle,
  });

  final bool isTurn;
  final String name;
  final Color color;
  final GameManager manager;
  final int playerIndex;
  final int handSize;
  final Map<int, GlobalKey<AnimatedListState>> listKeys;
  final double facingAngle;

  @override
  Widget build(BuildContext context) {
    // Trigonometry for radial positioning
    double dx = sin(facingAngle);
    double dy = -cos(facingAngle);

    // Cards pushed INTO the table center
    double cardsX = dx * 55;
    double cardsY = dy * 55;

    // Coaster pushed OUT towards the edge
    double coasterX = -dx * 45;
    double coasterY = -dy * 45;

    // Stats hover safely ABOVE the coaster (North in 2D screen space)
    double textY = coasterY - 55;

    return Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        // THE 3D CARDS
        Transform.translate(
          offset: Offset(cardsX, cardsY),
          child: AnimatedCardFan(
            listKeys: listKeys,
            index: playerIndex,
            handSize: handSize,
            facingAngle: facingAngle,
          ),
        ),

        // THE 3D COASTER BASE
        Transform.translate(
          offset: Offset(coasterX, coasterY),
          child: Transform(
            alignment: FractionalOffset.center,
            transform: .identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(-0.85)
              ..rotateZ(facingAngle),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: .circle,
                color: color.withValues(alpha: 0.3),
                border: .all(color: color, width: 2),
              ),
            ),
          ),
        ),

        // THE 2D HOLOGRAM ICON
        Transform.translate(
          offset: Offset(coasterX, coasterY),
          child: const Icon(Icons.person, color: Colors.white, size: 24)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                duration: 2.seconds,
                begin: 0.0,
                end: -4.0,
                curve: Curves.easeInOut,
              ),
        ),

        // THE 2D STATS BILLBOARD
        Transform.translate(
          offset: Offset(coasterX, textY),
          child: Column(
            mainAxisSize: .min,
            children: [
              _nameAndTurnIndicator,
              const SizedBox(height: 4),
              OpponentStats(
                manager: manager,
                index: playerIndex,
                handSize: handSize,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Row get _nameAndTurnIndicator => Row(
    mainAxisSize: .min,
    children: [
      if (isTurn) ...const [AnimatedTurnArrow(), SizedBox(width: 4)],
      Text(
        name,
        style: TextStyle(
          color: isTurn ? Colors.orangeAccent : Colors.white,
          fontWeight: .bold,
          fontSize: 16,
        ),
      ),
    ],
  );
}
