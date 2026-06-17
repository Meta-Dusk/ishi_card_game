import 'dart:math';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/relic/relic.dart';
import 'base_game_manager.dart';

part 'host_events_manager.dart';

class HostGameManager extends BaseGameManager {
  final Function() broadcastState;
  final int playerCount;

  static const int turnDurationSeconds = 60;
  int get _getTurnDeadlineEpoch =>
      DateTime.now().millisecondsSinceEpoch + (turnDurationSeconds * 1000);

  // Host-only authoritative states needed for events
  int _playersToSkip = 0;
  int pendingEvolutions = 0;
  final double chaosEffectChance = 0.25;

  HostGameManager({required this.broadcastState, required this.playerCount});

  void initializeGame() {
    final generatedDeck = generateStandardDeck();
    deck = generatedDeck.newDeck;
    discardPile.add(deck.removeLast());
    discardPile.last.isFaceUp = true;

    playerHands = List.generate(playerCount, (_) => []);
    actionPoints = List.generate(playerCount, (_) => 1);
    cardDraws = List.generate(playerCount, (_) => 1);
    playerRelics = List.generate(playerCount, (_) => []);

    turnDeadlineEpoch = _getTurnDeadlineEpoch;
    roundCount = 1;
  }

  int getNextPlayer() {
    int next = currentPlayer;
    // Calculate steps based on normal turn + any stacked skips
    int steps = 1 + _playersToSkip;

    for (int i = 0; i < steps; i++) {
      if (isClockwise) {
        next++;
        if (next > playerCount) next = 1;
      } else {
        next--;
        if (next < 1) next = playerCount;
      }
    }
    return next;
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

  // The Host simply processes their own UI interaction
  // exactly like an incoming network intent.
  @override
  void playCard(String cardId) => processPlayIntent(localPlayerIndex, cardId);

  @override
  void drawCard() => processDrawIntent(localPlayerIndex);

  @override
  void endTurn() => processEndTurnIntent(localPlayerIndex);

  @override
  void takePenalty() => processTakePenaltyIntent(localPlayerIndex);

  void processPlayIntent(int targetPlayerIndex, String cardId) {
    final cardIndex = playerHands[targetPlayerIndex].indexWhere(
      (c) => c.id == cardId,
    );

    if (cardIndex == -1) return; // Card does not exist in their hand

    IshiCard playedCard = playerHands[targetPlayerIndex][cardIndex];
    if (!canPlay(playedCard, targetPlayerIndex).canPlay) return;

    bool wasUnderAttack = pendingDrawCount > 0;
    playerHands[targetPlayerIndex].removeAt(cardIndex);

    int apCost = 1;
    if (activeDeckEvent == .wildDoubleTrouble && playedCard.color == .wild) {
      apCost = 2;
    }
    actionPoints[targetPlayerIndex] -= apCost;

    // Apply any card event effects before throwing it on the pile
    playedCard = _onPlayCardEventEffect(playedCard);

    playedCard.isFaceUp = true;
    discardPile.add(playedCard);

    // Apply core UNO mechanics (Skip, Reverse, Draw 4)
    _applyCardEffect(playedCard);

    hasPlayedCard = true;
    declaredColor = null;
    if (wasUnderAttack) hasDeflected = true;

    if (playerHands[targetPlayerIndex].isEmpty) {
      winnerIndex = targetPlayerIndex;
      // Trigger game over logic
    }

    broadcastState();
  }

  void processDrawIntent(int targetPlayerIndex) {
    if (cardDraws[targetPlayerIndex] <= 0 || deck.isEmpty) return;

    cardDraws[targetPlayerIndex]--;
    IshiCard drawn = deck.removeLast();

    playerHands[targetPlayerIndex].insert(0, drawn);
    hasDrawnCard = true;

    broadcastState();
  }

  void processEndTurnIntent(int targetPlayerIndex) {
    // Prevent out-of-turn skips
    if (currentPlayer - 1 != targetPlayerIndex) return;

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

    broadcastState();
  }

  void processTakePenaltyIntent(int targetPlayerIndex) {
    if (pendingDrawCount <= 0) return;

    for (int i = 0; i < pendingDrawCount; i++) {
      if (deck.isEmpty) continue;
      IshiCard card = deck.removeLast();
      playerHands[targetPlayerIndex].insert(0, card);
    }

    pendingDrawCount = 0;
    actionPoints[targetPlayerIndex] = 0;
    cardDraws[targetPlayerIndex] = 0;
    hasDrawnCard = true;

    broadcastState();
  }

  /// THE CARD RULES ENGINE\
  /// Also includes some rules reminiscent of Uno.
  void _applyCardEffect(IshiCard playedCard) {
    switch (playedCard.type) {
      case .reverse:
        if (playerCount == 2) {
          _playersToSkip++;
        } else {
          isClockwise = !isClockwise;
          debugPrint(
            "Turn Direction reversed: "
            "${isClockwise ? "clockwise" : "counter-clockwise"}",
          );
        }
        break;
      case .skip:
        if (pendingDrawCount > 0) {
          debugPrint("Player has deflected!");
        } else {
          _playersToSkip++;
          debugPrint("Player has skipped the next player!");
        }
        break;
      case .draw2:
        pendingDrawCount += 2;
        break;
      case .draw4:
        pendingDrawCount += 4;
        break;
      default:
        break;
    }

    _applyActiveDeckEventEffects(playedCard);
  }
}
