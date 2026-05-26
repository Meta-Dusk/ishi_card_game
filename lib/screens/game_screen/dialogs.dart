part of 'game_screen.dart';

extension GameDialogs on GameScreenState {
  void _showGameOverDialog() {
    final int winner = _manager.winnerIndex!;
    String winnerName = "Player ${winner + 1}";
    final bool isWinner = winner == _manager.localPlayerIndex;

    if (isWinner) {
      winnerName = "You";
    } else if (winner < _net.playersList.length) {
      winnerName = _net.playersList[winner].playerName;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        winnerName: winnerName,
        isWinner: isWinner,
        onExit: () async {
          // Disconnect from WebRTC/LAN and pop back to the Root Menu
          await _net.disconnect();
          if (!context.mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );
  }

  void _showDeckEventDialog() {
    final currentEventModel = deckEventPool.firstWhere(
      (e) => e.effect == _manager.activeDeckEvent,
      orElse: () => deckEventPool.first,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeckEventDialog(
        event: currentEventModel,
        useEventTitleAsTitle: _manager.manualTriggerDeckEvent,
      ),
    );
  }
}
