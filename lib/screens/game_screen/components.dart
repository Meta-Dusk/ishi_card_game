part of 'game_screen.dart';

extension GameComponents on GameScreenState {
  StatelessWidget _playPileAndDeck({required double scale}) =>
      TransformedPlayPileAndDeck(
        scale: scale,
        manager: _manager,
        onDrawCard: drawCardAction,
        onPlayCard: playCardAction,
        playPileKey: playPileKey,
        currentCombatMessages: _currentCombatMessages,
        combatMessagesKey: _combatMessagesKey,
      );

  /// LOCAL PLAYER DASHBOARD (Bottom)
  StatefulWidget get _lowerPanel => LowerPanel(
    manager: _manager,
    currentHand: currentHand,
    isMyTurn: isMyTurn,
    activeTargetingRelic: _activeTargetingRelic,
    selectedCard: _selectedCard,
    animatedListKey: listKeys[localUIIndex],
    relicTargets: _relicTargets,
    scrollController: scrollControllers[localUIIndex],
    onEndTurn: endTurnAction,
    onFlipAllCards: flipAllCardsAction,
    onTakePenalty: takePenaltyAction,
    onSortHand: animatedSort,
    onToggleAutoSort: _handleAutoSortToggle,
    onPlayCard: playCardAction,
    onTapCard: _handleCardTap,
    onTapRelic: _handleRelicTap,
    onCancelRelicTargeting: _handleCancelRelicTargeting,
    onConfirmRelicTargeting: _executeActiveRelic,
  );

  StatelessWidget get _settingsButton => SettingsButton(
    onExitGame: promptLeaveGame,
    onDevConsoleToggle: () {
      Navigator.pop(context);
      updateUI(
        () => _showDevConsoleNotifier.value = !_showDevConsoleNotifier.value,
      );
    },
    showDevConsoleToggle: _showDevConsoleToggleNotifier.value,
  );

  StatelessWidget get _pingToggleButton => PingToggleButton(
    showPingOverlay: _showPingOverlayNotifier.value,
    onToggle: () => updateUI(
      () => _showPingOverlayNotifier.value = !_showPingOverlayNotifier.value,
    ),
    onLongPress: () => showDialog(
      context: context,
      builder: (_) => DevConsoleToggleDialog(
        showDevConsole: _showDevConsoleToggleNotifier.value,
        onToggle: (val) =>
            updateUI(() => _showDevConsoleToggleNotifier.value = val),
      ),
    ),
  );
}

class TransformedPlayPileAndDeck extends StatelessWidget {
  final double scale;
  final GameManager manager;
  final VoidCallback onDrawCard;
  final void Function(IshiCard) onPlayCard;
  final GlobalKey<PlayCardsPileState>? playPileKey;
  final List<CombatMessage> currentCombatMessages;
  final Key? combatMessagesKey;

  const TransformedPlayPileAndDeck({
    super.key,
    required this.scale,
    required this.manager,
    required this.onDrawCard,
    required this.onPlayCard,
    required this.playPileKey,
    required this.currentCombatMessages,
    required this.combatMessagesKey,
  });

  @override
  Widget build(BuildContext context) => Transform(
    alignment: FractionalOffset.center,
    transform: .identity()
      ..setEntry(3, 2, 0.002)
      ..rotateX(-0.5)
      ..scaleByVector3(.all(scale)),
    child: Stack(
      alignment: .center,
      clipBehavior: .none,
      children: [
        Transform.translate(
          offset: isPc ? const Offset(0, 0) : const Offset(0, 40),
          child: Transform.scale(
            scale: isPc ? 1 : 0.6,
            child: PlayAndPileDeck(
              manager: manager,
              onDrawCard: onDrawCard,
              onPlayCard: onPlayCard,
              playPileKey: playPileKey,
            ),
          ),
        ),
        if (currentCombatMessages.isNotEmpty)
          CombatMessages(
            key: combatMessagesKey,
            messages: currentCombatMessages,
          ),
      ],
    ),
  );
}

class CombatMessages extends StatelessWidget {
  final List<CombatMessage> messages;

  const CombatMessages({super.key, required this.messages});

  @override
  Widget build(BuildContext context) => Positioned(
    top: -20,
    child: Transform(
      alignment: .center,
      transform: .identity()..rotateX(0.5),
      child: FloatingCombatTextGroup(
        key: key,
        interval: const Duration(milliseconds: 500),
        messages: messages,
      ),
    ),
  );
}

class SettingsButton extends StatelessWidget {
  final VoidCallback onExitGame;
  final VoidCallback onDevConsoleToggle;
  final bool showDevConsoleToggle;

  const SettingsButton({
    super.key,
    required this.onExitGame,
    required this.onDevConsoleToggle,
    required this.showDevConsoleToggle,
  });

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.settings, color: Colors.white),
    tooltip: "Show Settings",
    onPressed: () => showDialog(
      context: context,
      builder: (context) => GameSettingsDialog(
        onExitGame: onExitGame,
        onDevConsoleToggle: onDevConsoleToggle,
        showDevConsoleToggle: showDevConsoleToggle,
      ),
    ),
  );
}

class RoundIndicator extends StatelessWidget {
  final int roundCount;

  const RoundIndicator({super.key, required this.roundCount});

  @override
  Widget build(BuildContext context) => Container(
    padding: const .symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.6),
      borderRadius: .circular(16),
      border: .all(color: Colors.white24, width: 1),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.5, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Text(
        "ROUND $roundCount",
        key: ValueKey<int>(roundCount),
        style: const TextStyle(
          color: Colors.amber,
          fontWeight: .bold,
          letterSpacing: 2,
          fontSize: 16,
        ),
      ),
    ),
  );
}

class DrawCardButton extends StatelessWidget {
  final VoidCallback onDrawCard;

  const DrawCardButton({super.key, required this.onDrawCard});

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueGrey,
      foregroundColor: Colors.white,
      padding: const .symmetric(horizontal: 24, vertical: 12),
    ),
    onPressed: onDrawCard,
    icon: const Icon(Icons.style),
    label: const Text("Draw Card"),
  );
}
