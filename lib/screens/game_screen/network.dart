part of 'game_screen.dart';

extension GameScreenNetwork on GameScreenState {
  void _onGameStateUpdate(StringDynamicMap data) {
    updateUI(() {
      int oldSize = currentHand.length;

      _manager.applyGameStateJson(data);

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

  void _onHostListener(StringDynamicMap data) {
    if (data['type'] == 'PLAY_INTENT') {
      processClientIntent(data);
    } else if (data['type'] == 'REQUEST_STATE') {
      // Send the specific client their missing cards!
      int targetPlayer = data['playerIndex'];
      _socket.sendToClient(
        targetPlayer - 1,
        _manager.generateGameStateJson(targetPlayer),
      );
    }
  }

  void initializeNetworkSync() {
    socketSubscription = _socket.messages.listen((data) {
      if (!mounted) return;
      if (data['type'] == 'GAME_STATE_UPDATE') _onGameStateUpdate(data);
      if (_socket.isHost) _onHostListener(data);
    });
  }

  void broadcastGameState() {
    if (!_socket.isHost) return;
    for (int i = 1; i < _manager.playerCount; i++) {
      _socket.sendToClient(i - 1, _manager.generateGameStateJson(i));
    }
  }

  void processClientIntent(StringDynamicMap data) {
    updateUI(
      () => _clientIntent(
        playerIndex: data['playerIndex'],
        action: data['action'],
        data: data,
      ),
    );
    broadcastGameState();
  }

  void _clientDrawCard(int pIndex) {
    if (_manager.deck.isEmpty) _manager.deck = generateStandardDeck();
    _manager.drawCard(pIndex);
  }

  void _onIntentEndTurn() => _manager.endTurn();

  void _onIntentTakePenalty() => _manager.resolvePendingAttack();

  void _onIntentPlayCard(int pIndex, String action, StringDynamicMap data) {
    String cardId = data['cardId'];
    int cIndex = _manager.playerHands[pIndex].indexWhere((c) => c.id == cardId);

    if (cIndex == -1) return;
    _manager.playCard(pIndex, cIndex);

    if (data['declaredColor'] != null) {
      _manager.setDeclaredColor(CardColor.values[data['declaredColor'] as int]);
    }

    if (data['relicId'] == null) return;

    final relic = relicPool.firstWhere((r) => r.id == data['relicId']);
    _manager.playerRelics[pIndex].add(relic);

    if (relic.effect == RelicEffect.immediateDraw3) {
      for (int i = 0; i < 3; i++) {
        _manager.drawCard(pIndex);
      }
      _manager.playerRelics[pIndex].remove(relic);
    }
  }

  void _clientIntent({
    required int playerIndex,
    required String action,
    required StringDynamicMap data,
  }) {
    switch (action) {
      case "DRAW_CARD":
        _clientDrawCard(playerIndex);
        break;
      case "END_TURN":
        _onIntentEndTurn();
        break;
      case "TAKE_PENALTY":
        _onIntentTakePenalty();
        break;
      case "PLAY_CARD":
        _onIntentPlayCard(playerIndex, action, data);
        break;
    }
  }
}
