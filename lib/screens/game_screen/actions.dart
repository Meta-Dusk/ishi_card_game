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

    if (_socket.isHost) {
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
      broadcastGameState();
    } else {
      _socket.sendIntent({
        NetKey.type: NetKey.playIntent,
        NetKey.action: NetKey.drawCard,
        NetKey.playerIndex: _manager.localPlayerIndex,
      });
    }
  }

  void endTurnAction() {
    if (!isMyTurn) return;
    if (_socket.isHost) {
      updateUI(() {
        _manager.endTurn();
      });
      broadcastGameState();
    } else {
      _socket.sendIntent({
        NetKey.type: NetKey.playIntent,
        NetKey.action: NetKey.endTurn,
        NetKey.playerIndex: _manager.localPlayerIndex,
      });
    }
  }

  void takePenaltyAction() {
    if (!isMyTurn) return;
    if (_socket.isHost) {
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
      broadcastGameState();
    } else {
      _socket.sendIntent({
        NetKey.type: NetKey.playIntent,
        NetKey.action: NetKey.takePenalty,
        NetKey.playerIndex: _manager.localPlayerIndex,
      });
    }
  }

  void _removeCard(int cardIndex, UnoCard removedCard) {
    getCurrentState?.removeItem(
      cardIndex,
      (_, animation) =>
          RemoveTransition(removedCard: removedCard, animation: animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _onPlayCardUpdateHost({
    required int playerIndex,
    required int cardIndex,
    required int? declaredColorIndex,
    required Relic? chosenRelic,
    required UnoCard card,
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
    required UnoCard card,
  }) {
    updateUI(() {
      final removedCard = _manager.playerHands[playerIndex].removeAt(cardIndex);
      _manager.hasPlayedCard = true;

      getCurrentState?.removeItem(
        cardIndex,
        (_, animation) =>
            RemoveTransition(removedCard: removedCard, animation: animation),
        duration: const Duration(milliseconds: 300),
      );
    });

    _socket.sendIntent({
      NetKey.type: NetKey.playIntent,
      NetKey.action: NetKey.playCard,
      NetKey.playerIndex: playerIndex,
      NetKey.cardId: card.id,
      NetKey.declaredColor: declaredColorIndex,
      NetKey.relicId: chosenRelic?.id,
    });
  }

  Future<void> playCardAction(UnoCard card) async {
    if (!isMyTurn) return;

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

    if (_socket.isHost) {
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
      for (UnoCard card in currentHand) {
        card.isFaceUp = anyFaceDown;
      }
    });
  }

  void sortHandAction(bool byColor) {
    updateUI(() {
      _manager.sortHand(_manager.localPlayerIndex, byColor: byColor);
      listKeys[localUIIndex] = GlobalKey<AnimatedListState>();
      final oldController = scrollControllers[localUIIndex];
      scrollControllers[localUIIndex] = ScrollController();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => oldController?.dispose(),
      );
    });
  }
}
