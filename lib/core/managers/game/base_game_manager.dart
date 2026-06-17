import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:ishi/core/models/deck_event.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/relic/relic.dart';
import 'package:ishi/core/network/game_state_payload.dart';

class CanPlayData {
  CanPlayData({required this.canPlay, this.reason});

  bool canPlay;
  String? reason;
}

enum DeckSortType { byColor, byType, byValue, unsorted }

enum GameManagerEvent { gameOver, deckEventTriggered }

abstract class BaseGameManager {
  // --- EVENT CALLBACKS ---
  VoidCallback? onChaosTrigger;
  VoidCallback? onWildBuffTrigger;
  VoidCallback? onFrozenTrigger;
  VoidCallback? onEvolvedTrigger;
  VoidCallback? onRoundEnd;

  // --- EVENTS ---
  final _eventController = StreamController<GameManagerEvent>.broadcast();
  Stream<GameManagerEvent> get events => _eventController.stream;

  void addEvent(GameManagerEvent eventType) => _eventController.add(eventType);
  void dispose() => _eventController.close();

  // --- SHARED UI STATE AND LOGIC STATE ---
  bool isInitialized = false;
  int localPlayerIndex = 0;
  int currentPlayer = 1;
  bool isClockwise = true;

  List<int> opponentHandSizes = [];
  List<List<IshiCard>> playerHands = [];
  List<int> actionPoints = [];
  List<int> cardDraws = [];
  List<List<Relic>> playerRelics = [];
  List<IshiCard> deck = [];

  DeckEventEffect activeDeckEvent = .none;
  int pendingDrawCount = 0;
  CardColor? declaredColor;
  List<IshiCard> discardPile = [];
  int? winnerIndex;

  bool hasPlayedCard = false;
  bool hasDrawnCard = false;
  bool hasDeflected = false;

  int turnDeadlineEpoch = 0;
  int roundCount = 1;

  // --- LOCAL UI STATE ---
  List<IshiCard> localHand = [];
  DeckSortType handSortType = .unsorted;
  bool isAutoSortEnabled = false;

  // --- SHARED LOGIC ---
  /// Gets the current active card on the play pile.
  IshiCard get topCard => discardPile.last;

  CanPlayData canPlay(IshiCard card, int playerIndex) {
    final CanPlayData canPlayNoReason = .new(canPlay: true);

    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && card.color == .wild) {
      apCost = 2;
    }
    if (actionPoints[playerIndex] < apCost) {
      return .new(canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (pendingDrawCount > 0) {
      if (card.type == topCard.type) {
        if (card.type == .number) {
          // If a number card caused the attack (like in redCardsBurn),
          // the deflection MUST still be a valid match!
          if (card.color == topCard.color || card.number == topCard.number) {
            return canPlayNoReason;
          }
        } else {
          // +2s and +4s can still stack freely on their own types!
          return canPlayNoReason;
        }
      }

      // DEFLECTION MECHANICS
      bool isNaturalSkip = card.type == .skip;
      bool isBlueFreezeSkip =
          activeDeckEvent == .blueCardsFreeze && card.color == .blue;

      if ((isNaturalSkip || isBlueFreezeSkip) &&
          (topCard.color == .wild || card.color == topCard.color)) {
        return canPlayNoReason;
      }
      return .new(
        canPlay: false,
        reason: "Card cannot deflect incoming attack!",
      );
    }

    if (actionPoints[playerIndex] <= 0) {
      return .new(canPlay: false, reason: "Insufficient Action Points (AP)!");
    }

    if (card.color == .wild) return canPlayNoReason;

    if (activeDeckEvent == .redCardsBurn && card.color == .red) {
      return canPlayNoReason;
    }

    if (declaredColor != null) {
      final isSameColor = card.color == declaredColor;
      return .new(
        canPlay: isSameColor,
        reason: isSameColor ? null : "Card color doesn't match!",
      );
    }

    if (topCard.color == .wild) return canPlayNoReason;
    if (card.color == topCard.color) return canPlayNoReason;

    if (card.type == topCard.type) {
      if (card.type == .number) {
        final isSameNumber = card.number == topCard.number;
        return .new(
          canPlay: isSameNumber,
          reason: isSameNumber ? null : "Card number doesn't match!",
        );
      }
      return canPlayNoReason; // Skips, Reverses, etc. match type
    }
    return .new(canPlay: false, reason: "Invalid card!");
  }

  // --- STATE APPLICATION ---
  List<IshiCard> applyGameState(GameStatePayload state) {
    bool wasWinnerNull = !isInitialized || winnerIndex == null;

    localPlayerIndex = state.myPlayerIndex;
    currentPlayer = state.currentPlayer;
    isClockwise = state.direction;
    pendingDrawCount = state.pendingDrawCount;

    declaredColor = state.declaredColorIndex != null
        ? CardColor.values[state.declaredColorIndex!]
        : null;

    if (opponentHandSizes.isEmpty) {
      opponentHandSizes = state.opponentHandSizes;
      playerHands = List.generate(opponentHandSizes.length, (_) => []);
      playerRelics = List.generate(opponentHandSizes.length, (_) => []);
    } else {
      opponentHandSizes = state.opponentHandSizes;
    }

    actionPoints = state.actionPoints;
    cardDraws = state.cardDraws;
    playerRelics = state.playerRelics;

    if (state.topCard != null) {
      discardPile = [state.topCard!];
    }

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

    // Hand Syncing
    List<IshiCard> newlyDealtCards = [];
    List<IshiCard> incomingHand = state.myHand;
    List<IshiCard> preservedLocalHand = [];

    for (IshiCard localCard in localHand) {
      if (incomingHand.any((c) => c.id == localCard.id)) {
        preservedLocalHand.add(localCard);
      }
    }

    for (IshiCard incomingCard in incomingHand) {
      if (!preservedLocalHand.any((c) => c.id == incomingCard.id)) {
        newlyDealtCards.add(incomingCard);
      }
    }

    localHand = preservedLocalHand..addAll(newlyDealtCards);

    if (isAutoSortEnabled) sortHand(localPlayerIndex, handSortType);

    hasPlayedCard = state.hasPlayedCard;
    hasDrawnCard = state.hasDrawnCard;
    turnDeadlineEpoch = state.turnDeadline;
    roundCount = state.roundCount;
    activeDeckEvent = DeckEventEffect.values[state.activeDeckEventIndex];

    if (wasWinnerNull && state.winnerIndex != null) {
      winnerIndex = state.winnerIndex;
      addEvent(.gameOver);
    } else {
      winnerIndex = state.winnerIndex;
    }

    isInitialized = true;
    return newlyDealtCards;
  }

  void sortHand(int playerIndex, DeckSortType sortType) {
    handSortType = sortType;

    if (sortType == .unsorted) return;

    playerHands[playerIndex].sort((a, b) {
      switch (sortType) {
        case .byColor:
          // 1. Color -> 2. Type -> 3. Number
          int colorComp = a.color.index.compareTo(b.color.index);
          if (colorComp != 0) return colorComp;

          int typeComp = a.type.index.compareTo(b.type.index);
          if (typeComp != 0) return typeComp;

          return (a.number ?? -1).compareTo(b.number ?? -1);

        case .byType:
          // 1. Type -> 2. Number -> 3. Color
          int typeComp = a.type.index.compareTo(b.type.index);
          if (typeComp != 0) return typeComp;

          int numComp = (a.number ?? -1).compareTo(b.number ?? -1);
          if (numComp != 0) return numComp;

          return a.color.index.compareTo(b.color.index);

        case .byValue:
          // 1. Number -> 2. Color -> 3. Type
          //? Note: Action cards (number == null) become -1
          //? and will group neatly together at the front!
          int numComp = (a.number ?? -1).compareTo(b.number ?? -1);
          if (numComp != 0) return numComp;

          int colorComp = a.color.index.compareTo(b.color.index);
          if (colorComp != 0) return colorComp;

          return a.type.index.compareTo(b.type.index);

        case .unsorted:
          return 0;
      }
    });
  }

  // --- SHARED UTILITIES
  int getCardIndexByPlayerIndex(IshiCard card) =>
      playerHands[currentPlayer - 1].indexOf(card);

  IshiCard? getCardOfCurrentPlayer(IshiCard card) {
    final int playerIndex = currentPlayer - 1;
    final int cardIndex = getCardIndexByPlayerIndex(card);
    if (cardIndex == -1) return null;
    return playerHands[playerIndex][cardIndex];
  }

  void setDeclaredColor(CardColor color) => declaredColor = color;

  bool hasValidMoves(int playerIndex) {
    // If they are under attack, they must either deflect or take the penalty
    if (pendingDrawCount > 0) return true;

    final playerAP = actionPoints[playerIndex];
    final playerCD = cardDraws[playerIndex];

    // If they have action points, check if ANY card in their hand is playable
    if (playerAP > 0) {
      for (IshiCard card in playerHands[playerIndex]) {
        if (canPlay(card, playerIndex).canPlay) return true;
      }
    }

    // If they can still draw a card, they have a valid move
    if (playerCD > 0 && deck.isNotEmpty) return true;

    if (playerAP <= 0 && playerCD <= 0) return false;

    // Otherwise, they are completely out of options
    return false;
  }

  // --- THE CONTRACT ---
  void playCard(String cardId);
  void drawCard();
  void endTurn();
  void takePenalty();
}
