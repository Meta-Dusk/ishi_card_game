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
      // Snapshot EVERY opponent's hand size before applying the new state
      oldOpponentSizes = List.generate(
        _manager.playerCount,
        (i) => _getHandSize(i),
      );

      // Apply Master State
      newlyDealtCards = _manager.applyGameStateJson(message.payload);

      _animateOpponentHands(oldOpponentSizes);
    });

    if (newlyDealtCards.isNotEmpty) {
      await _staggerDrawCards(newlyDealtCards);
      _triggerAutoSortIfNeeded();
    }

    await _evaluateSmartAutoEnd();
  }

  void initializeNetworkSync() {
    _gameEventSubscription = _manager.events.listen(_processGameEvents);
    _netSubscription = _net.messages.listen(_processNetworkMessage);
    _pingSubscription = _net.messages.listen((message) {
      if (message is LobbyStateMessage && _showPingOverlay) updateUI(() {});
    });
  }

  void _processGameEvents(GameManagerEvent event) {
    if (!mounted) return;
    switch (event) {
      case .gameOver:
        _showGameOverDialog();
        break;
      case .deckEventTriggered:
        _showDeckEventDialog();
        break;
    }
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

      case DeckEventSyncMessage(:final effect):
        if (_manager.activeDeckEvent == effect) return;
        updateUI(() => _manager.activeDeckEvent = effect);
        _manager.addEvent(.deckEventTriggered);
        break;

      case SystemNotificationMessage(:final text):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text, style: const TextStyle(fontWeight: .bold)),
            backgroundColor: Colors.blueGrey.shade800,
            duration: const Duration(seconds: 3),
            behavior: .floating,
          ),
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
          _onClientDrawCard(pIndex);
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
        case .activateRelic:
          _onActivateRelic(pIndex, message);
          break;
        case .requestDeckRestock:
          if (_manager.deck.isEmpty) {
            final random = Random();
            final chosenEvent =
                deckEventPool[random.nextInt(deckEventPool.length)];

            _manager.activeDeckEvent = chosenEvent.effect;
            updateUI(() {
              final generatedDeck = generateStandardDeck(
                startingIdCount: _manager.lastDeckTotalIndex,
              );
              _manager.deck = generatedDeck.newDeck;
              _manager.lastDeckTotalIndex = generatedDeck.lastDeckTotalIndex;
            });

            // Broadcast the sync AND the trigger to all clients
            _net.broadcast(DeckEventSyncMessage(chosenEvent.effect));
            _manager.addEvent(.deckEventTriggered); // Host triggers self
          }
          break;
      }
    });

    _animateOpponentHands(oldOpponentSizes);
    broadcastGameState();
  }

  void _onClientDrawCard(int pIndex) {
    if (_manager.deck.isEmpty) {
      final generatedDeck = generateStandardDeck(
        startingIdCount: _manager.lastDeckTotalIndex,
      );
      _manager.deck = generatedDeck.newDeck;
      _manager.lastDeckTotalIndex = generatedDeck.lastDeckTotalIndex;
    }
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

    final template = relicPool.firstWhere(
      (relic) => relic.id == message.relicId,
    );
    final freshRelic = template.clone();

    _manager.playerRelics[playerIndex].add(freshRelic);

    if (freshRelic.effects.containsKey(RelicEffect.immediateDraw)) {
      final drawCount = freshRelic.effects[RelicEffect.immediateDraw]!;
      _manager.forceDraw(playerIndex, count: drawCount);
      _manager.playerRelics[playerIndex].remove(freshRelic);
    }
  }

  void _onActivateRelic(int playerIndex, PlayIntentMessage message) {
    final relic = _manager.playerRelics[playerIndex].firstWhere(
      (r) => r.id == message.relicId,
    );

    // Find the actual physical cards in the Host's master array
    List<IshiCard> targetCards = [];
    for (String id in message.targetCardIds ?? []) {
      final card = _manager.playerHands[playerIndex].firstWhere(
        (c) => c.id == id,
      );
      targetCards.add(card);
    }

    IshiCard? template = message.polymorphTemplate != null
        ? IshiCard.fromJson(message.polymorphTemplate!)
        : null;

    if (relic.useCost != null) {
      _manager.actionPoints[playerIndex] -= relic.useCost!;
    }
    if (template != null) {
      relic.memory.add(template.id);
    }

    // Apply it on the master state and broadcast!
    _applyRelicEffectLocally(
      playerIndex: playerIndex,
      relic: relic,
      targets: targetCards,
      chosenTemplate: template,
    );
    broadcastGameState();
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
        triggerCombatMessages(_manager.topCard);

        // Opponent Played Cards
        for (int j = 0; j < -diff; j++) {
          listKeys[i + 1]?.currentState?.removeItem(
            0,
            (_, animation) => SizeTransition(
              sizeFactor: animation,
              axis: .horizontal,
              axisAlignment: -1.0,
              child: const MiniFaceDownCard(),
            ),
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    }
  }
}
