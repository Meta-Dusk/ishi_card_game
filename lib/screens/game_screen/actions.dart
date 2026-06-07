part of 'game_screen.dart';

extension GameScreenActions on GameScreenState {
  Future<void> drawCardAction() async {
    if (!isMyTurn) return;

    if (_manager.cardDraws[_manager.localPlayerIndex] <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No card draws left!")));
      return;
    }

    if (_manager.deck.isEmpty && !_net.isHost) {
      _net.sendIntent(
        PlayIntentMessage(
          action: .requestDeckRestock,
          playerIndex: _manager.localPlayerIndex,
        ),
      );
      return;
    }

    if (_net.isHost && _manager.deck.isEmpty) {
      final random = Random();
      final chosenEvent = deckEventPool[random.nextInt(deckEventPool.length)];

      updateUI(() {
        final generatedDeck = generateStandardDeck(
          startingIdCount: _manager.lastDeckTotalIndex,
        );
        _manager.deck = generatedDeck.newDeck;
        _manager.lastDeckTotalIndex = generatedDeck.lastDeckTotalIndex;
      });

      // Broadcast the change so clients update their local activeDeckEvent
      _net.broadcast(DeckEventSyncMessage(chosenEvent.effect));
      return;
    }

    if (_net.isHost) {
      IshiCard drawnCard = _manager.drawCard(
        _manager.localPlayerIndex,
        skipHandInsertion: true,
      );

      await _staggerDrawCards([drawnCard]);
      _triggerAutoSortIfNeeded();
      broadcastGameState();
      await _evaluateSmartAutoEnd();
      return;
    }

    _net.sendIntent(
      PlayIntentMessage(
        action: .drawCard,
        playerIndex: _manager.localPlayerIndex,
      ),
    );
  }

  void endTurnAction() {
    if (!isMyTurn) return;
    if (_net.isHost) {
      updateUI(() => _manager.endTurn());
      broadcastGameState();
    } else {
      _net.sendIntent(
        PlayIntentMessage(
          action: .endTurn,
          playerIndex: _manager.localPlayerIndex,
        ),
      );
    }
  }

  Future<void> takePenaltyAction() async {
    if (!isMyTurn) return;

    if (_net.isHost) {
      final List<IshiCard> newlyDrawnCards = _manager.resolvePendingAttack(
        skipHandInsertion: true,
      );
      await _staggerDrawCards(newlyDrawnCards);
      _triggerAutoSortIfNeeded();
      broadcastGameState();
      await _evaluateSmartAutoEnd();
      return;
    }

    _net.sendIntent(
      PlayIntentMessage(
        action: .takePenalty,
        playerIndex: _manager.localPlayerIndex,
      ),
    );
  }

  /// Animated card removal
  void removeCard(int cardIndex, IshiCard removedCard) {
    getCurrentState?.removeItem(
      cardIndex,
      (_, animation) =>
          RemoveTransition(removedCard: removedCard, animation: animation),
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _onPlayCardUpdateHost({
    required int playerIndex,
    required int cardIndex,
    required int? declaredColorIndex,
    required Relic? chosenRelic,
    required IshiCard card,
  }) async {
    List<IshiCard> drawnCards = [];

    updateUI(() {
      final removedCard = _manager.getCardOfCurrentPlayer(card);
      _manager.playCard(playerIndex, cardIndex);

      if (declaredColorIndex != null) {
        _manager.setDeclaredColor(CardColor.values[declaredColorIndex]);
      }

      if (chosenRelic != null) {
        final freshRelic = chosenRelic.clone();
        _manager.playerRelics[playerIndex].add(freshRelic);

        if (freshRelic.effects.containsKey(RelicEffect.immediateDraw)) {
          final drawCount = freshRelic.effects[RelicEffect.immediateDraw]!;
          drawnCards = _manager.forceDraw(
            playerIndex,
            count: drawCount,
            skipHandInsertion: true,
          );
          _manager.playerRelics[playerIndex].remove(freshRelic);
        }
      }

      if (removedCard != null) removeCard(cardIndex, removedCard);
    });

    if (drawnCards.isNotEmpty) {
      await _staggerDrawCards(drawnCards);
      if (playerIndex == _manager.localPlayerIndex) _triggerAutoSortIfNeeded();
    }

    AudioManager().playSFX(Audio.sfx.cards.place);
    triggerCombatMessages(_manager.topCard);
    broadcastGameState();
  }

  void _onPlayCardNonHost({
    required int playerIndex,
    required int cardIndex,
    required int? declaredColorIndex,
    required Relic? chosenRelic,
    required IshiCard card,
  }) {
    updateUI(() {
      final removedCard = _manager.playerHands[playerIndex].removeAt(cardIndex);
      _manager.hasPlayedCard = true;

      bool isStandardReverse = card.type == .reverse;
      bool isYellowUnflux =
          _manager.activeDeckEvent == .yellowCardsUnflux &&
          card.color == .yellow;

      if ((isStandardReverse || isYellowUnflux) && _manager.playerCount > 2) {
        _manager.isClockwise = !_manager.isClockwise;
      }

      removeCard(cardIndex, removedCard);
    });

    _net.sendIntent(
      PlayIntentMessage(
        action: .playCard,
        playerIndex: playerIndex,
        cardId: card.id,
        declaredColor: declaredColorIndex,
        relicId: chosenRelic?.id,
      ),
    );
  }

  Future<void> playCardAction(IshiCard card) async {
    if (!isMyTurn) return;

    final canPlayCheck = _manager.canPlay(card, _manager.localPlayerIndex);

    if (!canPlayCheck.canPlay) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            canPlayCheck.reason ?? "You cannot play this card right now!",
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
          behavior: .floating,
        ),
      );

      // Clear the invalid selection so the button hides
      if (_selectedCard != null) updateUI(() => _selectedCard = null);
      return;
    }

    if (_selectedCard != null) updateUI(() => _selectedCard = null);

    final int playerIndex = _manager.localPlayerIndex;
    final int cardIndex = _manager.playerHands[playerIndex].indexOf(card);
    if (cardIndex == -1) return;

    int? declaredColorIndex;
    Relic? chosenRelic;

    switch (card.type) {
      case .chooseColor:
      case .draw4:
        if (!mounted) return;
        final CardColor? chosenColor = await showDialog<CardColor>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ColorPickerDialog(),
        );
        if (chosenColor == null) break;
        declaredColorIndex = chosenColor.index;
        break;

      case .chest:
        if (!mounted) return;
        chosenRelic = await showDialog<Relic>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ChestDialog(),
        );
        if (chosenRelic == null) break;

      default:
        break;
    }

    if (_net.isHost) {
      await _onPlayCardUpdateHost(
        playerIndex: playerIndex,
        cardIndex: cardIndex,
        declaredColorIndex: declaredColorIndex,
        chosenRelic: chosenRelic,
        card: card,
      );
      await _evaluateSmartAutoEnd();
      return;
    }

    // CLIENT PREDICTION: Instantly remove the card locally for a smooth UI!
    _onPlayCardNonHost(
      playerIndex: playerIndex,
      cardIndex: cardIndex,
      declaredColorIndex: declaredColorIndex,
      chosenRelic: chosenRelic,
      card: card,
    );
  }

  void flipAllCardsAction({bool onlyFlipIfFaceDown = false}) {
    final bool anyFaceDown = currentHand.any((card) => card.isFaceDown);
    if (onlyFlipIfFaceDown && !anyFaceDown) return;

    updateUI(() {
      for (IshiCard card in currentHand) {
        card.isFaceUp = anyFaceDown;
      }
    });

    AudioManager().playSFX(Audio.sfx.cards.mix, allowOverlap: true);
  }

  void sortHandAction(bool byColor) {
    updateUI(() {
      _manager.sortHand(_manager.localPlayerIndex, _manager.handSortType);
      listKeys[localUIIndex] = GlobalKey<AnimatedListState>();
      final oldController = scrollControllers[localUIIndex];
      scrollControllers[localUIIndex] = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => oldController?.dispose(),
      );
    });
  }

  Future<void> animatedSort(DeckSortType sortType) async {
    final controller = scrollControllers[localUIIndex];
    if (controller == null || sortType == .unsorted) return;

    // Glides the camera to the first card over 400ms
    await controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );

    // Flip all cards face down
    updateUI(() {
      for (IshiCard card in currentHand) {
        card.isFaceUp = false;
      }
    });

    /// Wait for the 3D flip animation to physically finish
    AudioManager().playSFX(Audio.sfx.cards.mix, allowOverlap: true);
    await Future.delayed(const Duration(milliseconds: 300));
    AudioManager().playSFX(Audio.sfx.cards.mix, allowOverlap: true);

    updateUI(() {
      _manager.sortHand(_manager.localPlayerIndex, sortType);

      // Swap the GlobalKey to force the AnimatedList to cleanly rebuild
      // the new sorted order without throwing index errors
      listKeys[localUIIndex] = GlobalKey<AnimatedListState>();
    });

    for (int i = 0; i < currentHand.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      updateUI(() => currentHand[i].isFaceUp = true);
    }
  }

  void _triggerAutoSortIfNeeded() {
    if (_manager.handSortType == .unsorted || !_manager.isAutoSortEnabled) {
      return;
    }

    // Wait for the AnimatedList's insertItem(0) animation to finish (400ms)
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) animatedSort(_manager.handSortType);
    });
  }

  Future<void> _staggerDrawCards(
    List<IshiCard> incomingCards, {
    bool flipAllCardsAfter = true,
  }) async {
    final controller = scrollControllers[localUIIndex];

    for (IshiCard card in incomingCards) {
      final currentPlayer = currentHand;

      updateUI(() => currentPlayer.add(card));

      final newIndex = currentPlayer.length - 1;

      final listState = getCurrentState;

      // Only animate if the list has successfully mounted
      if (listState != null) {
        listState.insertItem(
          newIndex,
          duration: const Duration(milliseconds: 300),
        );
      }

      if (controller != null && controller.hasClients) {
        final targetOffset = newIndex * itemWidth;

        controller.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }

      AudioManager().playSFX(Audio.sfx.cards.take, allowOverlap: true);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (flipAllCardsAfter) {
      await Future.delayed(const Duration(milliseconds: 300));
      flipAllCardsAction(onlyFlipIfFaceDown: true);
    }
  }

  /// Checks if the local player is out of moves, and if so,
  /// automatically attempts to take a penalty, draw a card, or press "End Turn"
  Future<void> _evaluateSmartAutoEnd() async {
    if (!isMyTurn || !mounted) return;

    if (_manager.hasValidMoves(_manager.localPlayerIndex)) return;

    if (_manager.pendingDrawCount > 0) {
      await takePenaltyAction();
      return;
    }

    if (_manager.cardDraws[_manager.localPlayerIndex] > 0) {
      await drawCardAction();
      return;
    }

    endTurnAction();
  }

  void _handleCardTap(IshiCard card) {
    if (!isMyTurn) return;

    updateUI(() {
      if (_activeTargetingRelic != null) {
        if (_relicTargets.contains(card)) {
          _relicTargets.remove(card);
        } else {
          final relicEffects = _activeTargetingRelic!.effects;
          final int maxTargets =
              relicEffects[RelicEffect.immediateDiscard] ?? 1;
          if (_relicTargets.length < maxTargets) _relicTargets.add(card);
        }
        return;
      }
      _selectedCard = _selectedCard == card ? null : card;
    });
  }

  bool? _handleRelicTap(bool isActiveRelic, Relic relic) {
    if (!isMyTurn || !isActiveRelic) return null;

    bool shouldSwitchToCards = false;

    updateUI(() {
      if (_activeTargetingRelic == relic) {
        _activeTargetingRelic = null;
        _relicTargets.clear();
      } else {
        _activeTargetingRelic = relic;
        _relicTargets.clear();
        shouldSwitchToCards = true;
      }
    });
    if (shouldSwitchToCards) return false;
    return null;
  }

  void _handleCancelRelicTargeting() => updateUI(() {
    _activeTargetingRelic = null;
    _relicTargets.clear();
  });

  void _handleAutoSortToggle() =>
      updateUI(() => _manager.isAutoSortEnabled = !_manager.isAutoSortEnabled);
}
