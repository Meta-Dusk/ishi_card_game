part of 'game_manager.dart';

extension GameSync on GameManager {
  /// HOST ONLY: Generates a strictly personalized JSON package
  /// for a specific player.
  GameStatePayload generateGameState(int targetPlayerIndex) => GameStatePayload(
    myPlayerIndex: targetPlayerIndex,
    currentPlayer: currentPlayer,
    direction: isClockwise,
    topCard: discardPile.isNotEmpty ? discardPile.last : null,
    deckSize: deck.length,
    myHand: playerHands[targetPlayerIndex],
    opponentHandSizes: playerHands.map((hand) => hand.length).toList(),
    pendingDrawCount: pendingDrawCount,
    declaredColorIndex: declaredColor?.index,
    actionPoints: actionPoints,
    cardDraws: cardDraws,
    hasPlayedCard: hasPlayedCard,
    hasDrawnCard: hasDrawnCard,
    playerRelics: playerRelics,
    winnerIndex: winnerIndex,
    turnDeadline: turnDeadlineEpoch,
    roundCount: roundCount,
    activeDeckEventIndex: activeDeckEvent.index,
  );

  /// CLIENT ONLY: Takes the typed state payload from
  /// the Host and forces the local UI to match it.
  List<IshiCard> applyGameState(GameStatePayload state) {
    localPlayerIndex = state.myPlayerIndex;
    currentPlayer = state.currentPlayer;
    isClockwise = state.direction;

    if (state.topCard != null) {
      discardPile = [state.topCard!];
    }

    if (opponentHandSizes.isEmpty) {
      opponentHandSizes = state.opponentHandSizes;
      playerHands = List.generate(opponentHandSizes.length, (_) => []);
      playerRelics = List.generate(opponentHandSizes.length, (_) => []);
    } else {
      opponentHandSizes = state.opponentHandSizes;
    }

    List<IshiCard> newlyDealtCards = [];
    List<IshiCard> incomingHand = state.myHand;
    List<IshiCard> preservedLocalHand = [];

    for (IshiCard localCard in playerHands[localPlayerIndex]) {
      if (incomingHand.any((c) => c.id == localCard.id)) {
        preservedLocalHand.add(localCard);
      }
    }

    for (IshiCard incomingCard in incomingHand) {
      if (!preservedLocalHand.any((c) => c.id == incomingCard.id)) {
        newlyDealtCards.add(incomingCard);
      }
    }

    playerHands[localPlayerIndex] = preservedLocalHand;

    pendingDrawCount = state.pendingDrawCount;

    declaredColor = state.declaredColorIndex != null
        ? CardColor.values[state.declaredColorIndex!]
        : null;

    actionPoints = state.actionPoints;
    cardDraws = state.cardDraws;
    hasPlayedCard = state.hasPlayedCard;
    hasDrawnCard = state.hasDrawnCard;
    playerRelics = state.playerRelics;

    if (winnerIndex == null && state.winnerIndex != null) {
      winnerIndex = state.winnerIndex;
      addEvent(.gameOver);
    } else {
      winnerIndex = state.winnerIndex;
    }

    turnDeadlineEpoch = state.turnDeadline;
    roundCount = state.roundCount;
    activeDeckEvent = DeckEventEffect.values[state.activeDeckEventIndex];

    // Deck dummy sync
    if (deck.length != state.deckSize) {
      deck.clear();
      deck.addAll(
        List.generate(
          state.deckSize,
          (i) => IshiCard(id: 'dummy_$i', color: .wild, type: .number),
        ),
      );
    }

    return newlyDealtCards;
  }
}
