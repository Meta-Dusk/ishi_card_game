part of 'game_screen.dart';

extension GameScreenNetwork on GameScreenState {
  void _onGameStateUpdate(GameStateMessage message) {
    updateUI(() {
      int oldSize = currentHand.length;

      _manager.applyGameStateJson(message.payload);

      int newSize = currentHand.length;

      // We only animate if cards were actually added to our hand!
      if (newSize <= oldSize) return;
      int diff = newSize - oldSize;

      for (int i = 0; i < diff; i++) {
        getCurrentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 400),
        );
      }
    });
  }

  void initializeNetworkSync() {
    socketSubscription = _socket.messages.listen((message) {
      if (!mounted) return;

      // Dart 3 Pattern Matching completely replaces the NetKey checks!
      switch (message) {
        case GameStateMessage():
          _onGameStateUpdate(message);
          break;

        case PlayIntentMessage():
          if (_socket.isHost) processClientIntent(message);
          break;

        case RequestLobbyStateMessage(:final playerIndex):
          if (_socket.isHost) {
            // Send the specific client their missing cards!
            _socket.sendToClient(
              playerIndex - 1,
              GameStateMessage(_manager.generateGameStateJson(playerIndex)),
            );
          }
          break;

        default:
          break;
      }
    });
  }

  void broadcastGameState() {
    if (!_socket.isHost) return;
    for (int i = 1; i < _manager.playerCount; i++) {
      _socket.sendToClient(
        i - 1,
        GameStateMessage(_manager.generateGameStateJson(i)),
      );
    }
  }

  void processClientIntent(PlayIntentMessage message) {
    updateUI(() {
      int pIndex = message.playerIndex;

      switch (message.action) {
        case IntentAction.drawCard:
          _clientDrawCard(pIndex);
          break;
        case IntentAction.endTurn:
          _onIntentEndTurn();
          break;
        case IntentAction.takePenalty:
          _onIntentTakePenalty();
          break;
        case IntentAction.playCard:
          _onIntentPlayCard(pIndex, message);
          break;
      }
    });
    broadcastGameState();
  }

  void _clientDrawCard(int pIndex) {
    if (_manager.deck.isEmpty) _manager.deck = generateStandardDeck();
    _manager.drawCard(pIndex);
  }

  void _onIntentEndTurn() => _manager.endTurn();

  void _onIntentTakePenalty() => _manager.resolvePendingAttack();

  void _onIntentPlayCard(int pIndex, PlayIntentMessage message) {
    if (message.cardId == null) return;

    int cIndex = _manager.playerHands[pIndex].indexWhere(
      (c) => c.id == message.cardId,
    );
    if (cIndex == -1) return;

    _manager.playCard(pIndex, cIndex);

    if (message.declaredColor != null) {
      _manager.setDeclaredColor(CardColor.values[message.declaredColor!]);
    }

    if (message.relicId == null) return;

    final relic = relicPool.firstWhere((r) => r.id == message.relicId);
    _manager.playerRelics[pIndex].add(relic);

    // Assuming your Relic model uses an enum called 'effect'
    if (relic.effect == RelicEffect.immediateDraw3) {
      for (int i = 0; i < 3; i++) {
        _manager.drawCard(pIndex);
      }
      _manager.playerRelics[pIndex].remove(relic);
    }
  }
}
