import 'package:flutter/material.dart';
import 'package:ishi/core/managers/game/game_manager.dart';
import 'package:ishi/services/network_service.dart';

class TurnTimeline extends StatelessWidget {
  final GameManager manager;
  final NetworkService net;

  const TurnTimeline({super.key, required this.manager, required this.net});

  String _getName(int index) {
    // Dart's modulo operator can return negative numbers,
    // so we use this safe wrapping formula to loop around the player array
    int count = manager.playerCount;
    int safeIndex = (index % count + count) % count;

    if (safeIndex == manager.localPlayerIndex) return "YOU";
    if (safeIndex < net.playersList.length) {
      return net.playersList[safeIndex].playerName;
    }
    return "Player ${safeIndex + 1}";
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const .symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: .circular(30),
          border: .all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisSize: .min,
            children: _buildCarousel(_getSequence),
          ),
        ),
      ),
    ),
  );

  List<int> get _getSequence {
    final int currentPlayer = manager.currentPlayer - 1;
    final bool clockwise = manager.isClockwise;

    // Always display: [Previous] -> [Current] -> [Next]
    // If the direction reverses, the left and right players physically swap!
    List<int> sequence = clockwise
        ? [currentPlayer - 1, currentPlayer, currentPlayer + 1]
        : [currentPlayer + 1, currentPlayer, currentPlayer - 1];
    return sequence;
  }

  List<Widget> _buildCarousel(List<int> seq) {
    List<Widget> children = [];

    for (int i = 0; i < seq.length; i++) {
      bool isCenter = i == 1; // The middle item is the current player
      String name = _getName(seq[i]);

      // Truncate long names for the side items to prevent screen overflow
      if (name.length > 10 && !isCenter) {
        name = "${name.substring(0, 8)}...";
      }

      children.add(_AnimatedItem(isCenter: isCenter, name: name));

      // Add the directional arrows between names
      if (i < seq.length - 1) {
        children.add(const _DirectionalArrow());
      }
    }

    return children;
  }
}

class _DirectionalArrow extends StatelessWidget {
  const _DirectionalArrow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .symmetric(horizontal: 8.0),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: const Icon(
        Icons.double_arrow_rounded,
        color: Colors.white30,
        size: 16,
      ),
    ),
  );
}

class _AnimatedItem extends StatelessWidget {
  const _AnimatedItem({required this.isCenter, required this.name});

  final bool isCenter;
  final String name;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const .symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isCenter
          ? Colors.orangeAccent.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: .circular(16),
      border: isCenter ? .all(color: Colors.orangeAccent, width: 1.5) : null,
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        name.toUpperCase(),
        key: ValueKey<String>("$name-$isCenter"),
        style: TextStyle(
          color: isCenter ? Colors.orangeAccent : Colors.white54,
          fontWeight: isCenter ? .bold : .w600,
          fontSize: isCenter ? 14 : 12,
          letterSpacing: 1.0,
        ),
      ),
    ),
  );
}
