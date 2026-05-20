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

    if (_net.isHost) {
      if (_manager.deck.isEmpty) {
        _triggerDeckRestockEvent();
        return;
      }

      IshiCard drawnCard = _manager.drawCard(
        _manager.localPlayerIndex,
        skipHandInsertion: true,
      );

      await _staggerDrawCards([drawnCard]);
      _triggerAutoSortIfNeeded();
      broadcastGameState();
      _evaluateSmartAutoEnd();
      return;
    }

    _net.sendIntent(
      PlayIntentMessage(
        action: .drawCard,
        playerIndex: _manager.localPlayerIndex,
      ),
    );
    _evaluateSmartAutoEnd();
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
      List<IshiCard> newlyDrawnCards = _manager.resolvePendingAttack(
        skipHandInsertion: true,
      );
      await _staggerDrawCards(newlyDrawnCards);
      _triggerAutoSortIfNeeded();
      broadcastGameState();
      _evaluateSmartAutoEnd();
      return;
    }

    _net.sendIntent(
      PlayIntentMessage(
        action: .takePenalty,
        playerIndex: _manager.localPlayerIndex,
      ),
    );
    _evaluateSmartAutoEnd();
  }

  void _removeCard(int cardIndex, IshiCard removedCard) {
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

        if (freshRelic.effect == .immediateDraw3) {
          drawnCards = _manager.forceDraw(
            playerIndex,
            count: 3,
            skipHandInsertion: true,
          );
          _manager.playerRelics[playerIndex].remove(freshRelic);
        }
      }

      if (removedCard != null) _removeCard(cardIndex, removedCard);
    });

    if (drawnCards.isNotEmpty) {
      await _staggerDrawCards(drawnCards);
      if (playerIndex == _manager.localPlayerIndex) _triggerAutoSortIfNeeded();
    }

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
      _removeCard(cardIndex, removedCard);
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

    if (!_manager.canPlay(card, _manager.localPlayerIndex)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot play this card right now!"),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
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
      case .wild:
      case .wildDraw4:
        final CardColor? chosenColor = await showDialog<CardColor>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ColorPickerDialog(),
        );
        if (chosenColor == null) return;
        declaredColorIndex = chosenColor.index;
        break;

      case .chest:
        chosenRelic = await showDialog<Relic>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ChestDialog(),
        );
        if (chosenRelic == null) return;

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
      _evaluateSmartAutoEnd();
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
    _evaluateSmartAutoEnd();
  }

  void _triggerDeckRestockEvent() {
    final random = Random();
    final chosenEvent = deckEventPool[random.nextInt(deckEventPool.length)];
    _manager.activeDeckEvent = chosenEvent.effect;
    updateUI(() => _manager.deck = generateStandardDeck());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DeckEventDialog(onDrawCard: drawCardAction, event: chosenEvent),
    );
  }

  void flipAllCardsAction({bool onlyFlipIfFaceDown = false}) {
    updateUI(() {
      final bool anyFaceDown = currentHand.any((card) => card.isFaceDown);
      if (onlyFlipIfFaceDown && !anyFaceDown) return;
      for (IshiCard card in currentHand) {
        card.isFaceUp = anyFaceDown;
      }
    });
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
    await Future.delayed(const Duration(milliseconds: 300));

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
      final currentPlayer = _manager.playerHands[_manager.localPlayerIndex];

      updateUI(() => currentPlayer.add(card));

      final newIndex = currentPlayer.length - 1;

      // Fetch the list state DYNAMICALLY inside the loop!
      final listState = listKeys[localUIIndex]?.currentState;

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

      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (flipAllCardsAfter) {
      await Future.delayed(const Duration(milliseconds: 300));
      flipAllCardsAction(onlyFlipIfFaceDown: true);
    }
  }

  /// Checks if the local player is out of moves, and if so,
  /// automatically presses "End Turn"
  void _evaluateSmartAutoEnd() {
    if (!isMyTurn) return;
    if (mounted &&
        isMyTurn &&
        !_manager.hasValidMoves(_manager.localPlayerIndex)) {
      endTurnAction();
    }
  }

  Future<void> _executeActiveRelic() async {
    final relic = _activeTargetingRelic!;
    final targets = List<IshiCard>.from(_relicTargets);
    final playerIndex = _manager.localPlayerIndex;

    IshiCard? chosenTemplate;

    // POLYMORPH SPECIFIC
    if (relic.effect == .polymorph) {
      chosenTemplate = await showDialog<IshiCard>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PolymorphDialog(),
      );
      if (chosenTemplate == null) return; // Player cancelled
    }

    updateUI(() {
      _activeTargetingRelic = null;
      _relicTargets.clear();
      _isViewingRelics = false;
    });

    _applyRelicEffectLocally(
      playerIndex: playerIndex,
      relic: relic,
      targets: targets,
      chosenTemplate: chosenTemplate,
    );

    if (_net.isHost) {
      broadcastGameState();
      _evaluateSmartAutoEnd();
    } else {
      _net.sendIntent(
        PlayIntentMessage(
          action: .activateRelic,
          playerIndex: playerIndex,
          relicId: relic.id,
          targetCardIds: targets.map((c) => c.id).toList(),
          polymorphTemplate: chosenTemplate?.toJson(),
        ),
      );
      _evaluateSmartAutoEnd();
    }
  }

  /// Helper method to process the arrays and trigger UI animations
  void _applyRelicEffectLocally({
    required int playerIndex,
    required Relic relic,
    required List<IshiCard> targets,
    IshiCard? chosenTemplate,
  }) {
    updateUI(() {
      // EFFECT: TRASHCAN
      if (relic.effect == .trashcan) {
        for (IshiCard target in targets) {
          int index = _manager.playerHands[playerIndex].indexOf(target);
          if (index != -1) {
            _manager.playerHands[playerIndex].removeAt(
              index,
            ); // Remove from logic

            if (playerIndex == _manager.localPlayerIndex) {
              _removeCard(index, target); // Slide out of the AnimatedList!
            }
          }
        }
      }
      // EFFECT: POLYMORPH
      else if (relic.effect == .polymorph && chosenTemplate != null) {
        int lastModifiedIndex = 0;

        for (IshiCard target in targets) {
          final currentPlayer = _manager.playerHands[playerIndex];
          int index = currentPlayer.indexOf(target);
          if (index == -1) continue;
          lastModifiedIndex = index;
          IshiCard polymorphedCard = IshiCard(
            id: target.id,
            color: chosenTemplate.color,
            type: chosenTemplate.type,
            number: chosenTemplate.number,
          );
          currentPlayer[index] = polymorphedCard;
        }
        // Force the AnimatedList to rebuild so the new colors instantly show
        listKeys[localUIIndex] = GlobalKey<AnimatedListState>();

        if (playerIndex == _manager.localPlayerIndex) {
          final controller = scrollControllers[localUIIndex];
          if (controller != null && controller.hasClients) {
            final targetOffset = lastModifiedIndex * itemWidth;
            Future.delayed(const Duration(milliseconds: 100), () {
              controller.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            });
          }
        }
      }

      // CONSUMPTION: Remove single-use relics or decrease durability!
      try {
        final inventoryRelic = _manager.playerRelics[playerIndex].firstWhere(
          (r) => r.id == relic.id,
        );

        if (inventoryRelic.maxUses != null) {
          inventoryRelic.usesLeft =
              (inventoryRelic.usesLeft ?? inventoryRelic.maxUses!) - 1;

          if (inventoryRelic.usesLeft! <= 0) {
            _manager.playerRelics[playerIndex].remove(inventoryRelic);
          }
        } else if (inventoryRelic.types.contains(RelicEffectType.singleUse)) {
          _manager.playerRelics[playerIndex].remove(inventoryRelic);
        }
      } catch (e) {
        // Fallback safety in case the relic was already removed
      }
    });

    Future.delayed(
      const Duration(milliseconds: 400),
      () => flipAllCardsAction(onlyFlipIfFaceDown: true),
    );
  }
}
