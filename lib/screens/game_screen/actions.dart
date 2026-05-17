part of 'game_screen.dart';

extension GameScreenActions on GameScreenState {
  void drawCardAction() {
    if (!isMyTurn) return;

    if (_manager.pendingDrawCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You are under attack!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
      updateUI(() {
        _manager.drawCard(_manager.localPlayerIndex);
        getCurrentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 400),
        );
      });
      _triggerAutoSortIfNeeded();
      broadcastGameState();
    } else {
      _net.sendIntent(
        PlayIntentMessage(
          action: .drawCard,
          playerIndex: _manager.localPlayerIndex,
        ),
      );
    }
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

  void takePenaltyAction() {
    if (!isMyTurn) return;
    if (_net.isHost) {
      updateUI(() {
        int cardsToDraw = _manager.pendingDrawCount;
        _manager.resolvePendingAttack();
        for (int i = 0; i < cardsToDraw; i++) {
          getCurrentState?.insertItem(
            0,
            duration: const Duration(milliseconds: 400),
          );
        }
      });
      _triggerAutoSortIfNeeded();
      broadcastGameState();
    } else {
      _net.sendIntent(
        PlayIntentMessage(
          action: .takePenalty,
          playerIndex: _manager.localPlayerIndex,
        ),
      );
    }
  }

  void _removeCard(int cardIndex, IshiCard removedCard) {
    getCurrentState?.removeItem(
      cardIndex,
      (_, animation) =>
          RemoveTransition(removedCard: removedCard, animation: animation),
      duration: const Duration(milliseconds: 500),
    );
  }

  void _onPlayCardUpdateHost({
    required int playerIndex,
    required int cardIndex,
    required int? declaredColorIndex,
    required Relic? chosenRelic,
    required IshiCard card,
  }) {
    updateUI(() {
      final removedCard = _manager.getCardOfCurrentPlayer(card);
      _manager.playCard(playerIndex, cardIndex);

      if (declaredColorIndex != null) {
        _manager.setDeclaredColor(CardColor.values[declaredColorIndex]);
      }

      if (chosenRelic != null) {
        _manager.playerRelics[playerIndex].add(chosenRelic);
        if (chosenRelic.effect == .immediateDraw3) {
          for (int i = 0; i < 3; i++) {
            _manager.drawCard(playerIndex);
            getCurrentState?.insertItem(0);
          }
          _manager.playerRelics[playerIndex].remove(chosenRelic);
          if (playerIndex == _manager.localPlayerIndex) {
            _triggerAutoSortIfNeeded();
          }
        }
      }

      if (removedCard != null) _removeCard(cardIndex, removedCard);
    });
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

    if (card.type == .wild || card.type == .wildDraw4) {
      final CardColor? chosenColor = await showDialog<CardColor>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ColorPickerDialog(),
      );
      if (chosenColor == null) return;
      declaredColorIndex = chosenColor.index;
    } else if (card.type == .chest) {
      chosenRelic = await showDialog<Relic>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const ChestDialog(),
      );
      if (chosenRelic == null) return;
    }

    if (_net.isHost) {
      _onPlayCardUpdateHost(
        playerIndex: playerIndex,
        cardIndex: cardIndex,
        declaredColorIndex: declaredColorIndex,
        chosenRelic: chosenRelic,
        card: card,
      );
    } else {
      // CLIENT PREDICTION: Instantly remove the card locally for a smooth UI!
      _onPlayCardNonHost(
        playerIndex: playerIndex,
        cardIndex: cardIndex,
        declaredColorIndex: declaredColorIndex,
        chosenRelic: chosenRelic,
        card: card,
      );
    }
  }

  void _triggerDeckRestockEvent() {
    updateUI(() => _manager.deck = generateStandardDeck());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeckEventDialog(onDrawCard: drawCardAction),
    );
  }

  void flipAllCardsAction() {
    updateUI(() {
      final bool anyFaceDown = currentHand.any((card) => card.isFaceDown);
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
    // Determine the winner's display name
    int winner = _manager.winnerIndex!;
    String winnerName = "Player ${winner + 1}";
    if (winner == _manager.localPlayerIndex) {
      winnerName = "You";
    } else if (winner < _net.playersList.length) {
      winnerName = _net.playersList[winner].playerName;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverDialog(winnerName: winnerName, network: _net)
          .animate()
          .fadeIn(duration: 200.ms)
          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
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
}
