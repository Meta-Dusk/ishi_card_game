part of 'game_manager.dart';

extension GameActions on GameManager {
  List<IshiCard> resolvePendingAttack({bool skipHandInsertion = false}) {
    int playerIndex = currentPlayer - 1;
    List<IshiCard> drawnCards = [];

    for (int i = 0; i < pendingDrawCount; i++) {
      if (deck.isEmpty) continue;

      IshiCard card = deck.removeLast();
      drawnCards.add(card);

      // Only insert instantly if the UI isn't handling it
      if (!skipHandInsertion) {
        playerHands[playerIndex].insert(0, card);
      }
    }

    pendingDrawCount = 0;
    actionPoints[playerIndex] = 0; // Force their turn to end
    cardDraws[playerIndex] = 0; // Prevent them from digging for answers
    hasDrawnCard = true;

    // Only sort if we instantly inserted the cards
    if (!skipHandInsertion && playerIndex == localPlayerIndex) {
      sortHand(playerIndex, handSortType);
    }

    return drawnCards;
  }

  /// ACTION: Play a card and apply its effects
  void playCard(int playerIndex, int cardIndex) {
    bool wasUnderAttack = pendingDrawCount > 0;
    IshiCard playedCard = playerHands[playerIndex].removeAt(cardIndex);

    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && playedCard.color == .wild) {
      apCost = 2;
    }
    actionPoints[playerIndex] -= apCost;

    playedCard = _onPlayCardEventEffect(playedCard);

    playedCard.isFaceUp = true;
    discardPile.add(playedCard);
    _applyCardEffect(playedCard);

    hasPlayedCard = true;
    declaredColor = null;
    if (wasUnderAttack) hasDeflected = true;
    if (playerHands[playerIndex].isEmpty) {
      winnerIndex = playerIndex;
      addEvent(.gameOver);
    }
  }

  /// ACTION: Draw a card
  IshiCard drawCard(int playerIndex, {bool skipHandInsertion = false}) {
    cardDraws[playerIndex]--;
    IshiCard drawn = deck.removeLast();

    // Only insert instantly if the UI isn't handling it
    if (!skipHandInsertion) playerHands[playerIndex].insert(0, drawn);

    hasDrawnCard = true;

    // Only auto-sort instantly if we inserted the card instantly
    if (!skipHandInsertion && playerIndex == localPlayerIndex) {
      sortHand(playerIndex, handSortType);
    }

    return drawn;
  }

  /// Forces a player to draw cards without consuming their CD points
  List<IshiCard> forceDraw(
    int targetPlayerIndex, {
    int count = 1,
    bool skipHandInsertion = false,
  }) {
    List<IshiCard> drawnCards = [];

    for (int i = 0; i < count; i++) {
      if (deck.isEmpty) break;
      IshiCard drawn = deck.removeLast();
      drawnCards.add(drawn);

      // Only insert instantly if the UI isn't handling it
      if (!skipHandInsertion) {
        playerHands[targetPlayerIndex].insert(0, drawn);
      }
    }

    // Only sort instantly if we inserted the cards instantly
    if (!skipHandInsertion && targetPlayerIndex == localPlayerIndex) {
      sortHand(targetPlayerIndex, handSortType);
    }

    return drawnCards;
  }

  void endTurn() {
    currentPlayer = getNextPlayer();
    _playersToSkip = 0; // Reset skips after they are consumed

    if (currentPlayer == 1) {
      roundCount++;
      if (onRoundEnd != null) onRoundEnd!();
    }

    final int playerIndex = currentPlayer - 1;

    // Calculate base economies + relic bonuses
    final int bonusAP = playerRelics[playerIndex]
        .where((r) => r.effects[RelicEffect.addActionPoints] != null)
        .fold<int>(
          0,
          (previous, current) =>
              previous + current.effects[RelicEffect.addActionPoints]!,
        );
    final int bonusCD = playerRelics[playerIndex]
        .where((r) => r.effects[RelicEffect.addCardDraws] != null)
        .fold<int>(
          0,
          (previous, current) =>
              previous + current.effects[RelicEffect.addCardDraws]!,
        );

    actionPoints[currentPlayer - 1] = 1 + bonusAP;
    cardDraws[currentPlayer - 1] = 1 + bonusCD;
    hasPlayedCard = false;
    hasDrawnCard = false;
    hasDeflected = false;
    turnDeadlineEpoch = _getTurnDeadlineEpoch;
  }
}
