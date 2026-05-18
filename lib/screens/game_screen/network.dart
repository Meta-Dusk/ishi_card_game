part of 'game_screen.dart';

extension GameScreenNetwork on GameScreenState {
  /// Safe helper to get any player's hand size whether we are Host or Client
  int _getHandSize(int index) {
    if (_net.isHost) return _manager.playerHands[index].length;
    if (_manager.opponentHandSizes.length > index) {
      return _manager.opponentHandSizes[index];
    }
    return 0;
  }

  Future<void> _onGameStateUpdate(GameStateMessage message) async {
    if (_net.isHost) return;

    List<int> oldOpponentSizes = [];
    List<IshiCard> newlyDealtCards = [];

    updateUI(() {
      int oldLocalSize = currentHand.length;

      // Snapshot EVERY opponent's hand size before applying the new state
      oldOpponentSizes = List.generate(
        _manager.playerCount,
        (i) => _getHandSize(i),
      );

      // Apply Master State
      newlyDealtCards = _manager.applyGameStateJson(message.payload);

      if (_manager.winnerIndex != null) {
        _showGameOverDialog();
        return;
      }

      int newLocalSize = currentHand.length;
      if (newLocalSize <= oldLocalSize) {
        _manager.sortHand(_manager.localPlayerIndex, _manager.handSortType);
      }

      _animateOpponentHands(oldOpponentSizes);
    });

    if (newlyDealtCards.isNotEmpty) {
      await _staggerDrawCards(newlyDealtCards);
      _triggerAutoSortIfNeeded();
    }
  }

  void initializeNetworkSync() {
    _manager.eventStream.listen((event) {
      if (!mounted) return;
      switch (event) {
        case .gameOver:
          _showGameOverDialog();
          break;
      }
    });

    _netSubscription = _net.messages.listen(
      (message) => _processNetworkMessage(message),
    );
  }

  void _processNetworkMessage(NetMessage message) {
    if (!mounted) return;
    switch (message) {
      case GameStateMessage():
        _onGameStateUpdate(message);
        break;

      case PlayIntentMessage():
        if (_net.isHost) _processClientIntent(message);
        break;

      case RequestLobbyStateMessage(:final playerIndex):
        if (!_net.isHost) break;
        // Send the specific client their missing cards!
        _net.sendToClient(
          playerIndex - 1,
          GameStateMessage(_manager.generateGameStateJson(playerIndex)),
        );
        break;

      default:
        break;
    }
  }

  void broadcastGameState() {
    if (!_net.isHost) return;
    for (int i = 1; i < _manager.playerCount; i++) {
      _net.sendToClient(
        i - 1,
        GameStateMessage(_manager.generateGameStateJson(i)),
      );
    }
  }

  void _processClientIntent(PlayIntentMessage message) {
    List<int> oldOpponentSizes = List.generate(
      _manager.playerCount,
      (i) => _getHandSize(i),
    );

    updateUI(() {
      int pIndex = message.playerIndex;

      switch (message.action) {
        case .drawCard:
          _clientDrawCard(pIndex);
          break;
        case .endTurn:
          _onIntentEndTurn();
          break;
        case .takePenalty:
          _onIntentTakePenalty();
          break;
        case .playCard:
          _onIntentPlayCard(pIndex, message);
          break;
      }
    });

    _animateOpponentHands(oldOpponentSizes);

    if (_manager.winnerIndex != null) {
      _showGameOverDialog();
    }

    broadcastGameState();
  }

  void _clientDrawCard(int pIndex) {
    if (_manager.deck.isEmpty) _manager.deck = generateStandardDeck();
    _manager.drawCard(pIndex);
  }

  void _onIntentEndTurn() => _manager.endTurn();

  void _onIntentTakePenalty() => _manager.resolvePendingAttack();

  void _onIntentPlayCard(int playerIndex, PlayIntentMessage message) {
    if (message.cardId == null) return;

    int cardIndex = _manager.playerHands[playerIndex].indexWhere(
      (card) => card.id == message.cardId,
    );
    if (cardIndex == -1) return;

    playPileKey.currentState?.animateOpponentDrop();

    _manager.playCard(playerIndex, cardIndex);

    if (message.declaredColor != null) {
      _manager.setDeclaredColor(CardColor.values[message.declaredColor!]);
    }

    if (message.relicId == null) return;

    final relic = relicPool.firstWhere((relic) => relic.id == message.relicId);
    _manager.playerRelics[playerIndex].add(relic);

    if (relic.effect == .immediateDraw3) {
      _manager.forceDraw(playerIndex, count: 3);
      _manager.playerRelics[playerIndex].remove(relic);
    }

    if (_manager.winnerIndex != null) _showGameOverDialog();
  }

  void _animateOpponentHands(List<int> oldOpponentSizes) {
    for (int i = 0; i < _manager.playerCount; i++) {
      if (i == _manager.localPlayerIndex) continue; // Skip local player

      int newOppSize = _getHandSize(i);
      int oldOppSize = oldOpponentSizes[i];
      int diff = newOppSize - oldOppSize;

      if (diff > 0) {
        // Opponent Drew Cards
        for (int j = 0; j < diff; j++) {
          listKeys[i + 1]?.currentState?.insertItem(
            0,
            duration: const Duration(milliseconds: 300),
          );
        }
      } else if (diff < 0) {
        playPileKey.currentState?.animateOpponentDrop();

        // Opponent Played Cards
        for (int j = 0; j < -diff; j++) {
          listKeys[i + 1]?.currentState?.removeItem(
            0,
            (_, animation) => SizeTransition(
              sizeFactor: animation,
              axis: .horizontal,
              axisAlignment: -1.0,
              child: MiniFaceDownCard(),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }
  }
}
