import 'package:ishi/core/data_types.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/relic/relic.dart';

class _GameKey {
  static const String myPlayerIndex = 'myPlayerIndex';
  static const String currentPlayer = 'currentPlayer';
  static const String direction = 'direction';
  static const String topCard = 'topCard';
  static const String deckSize = 'deckSize';
  static const String myHand = 'myHand';
  static const String opponentHandSizes = 'opponentHandSizes';
  static const String pendingDrawCount = 'pendingDrawCount';
  static const String declaredColor = 'declaredColor';
  static const String actionPoints = 'actionPoints';
  static const String cardDraws = 'cardDraws';
  static const String hasPlayedCard = 'hasPlayedCard';
  static const String hasDrawnCard = 'hasDrawnCard';
  static const String playerRelics = 'playerRelics';
  static const String winnerIndex = 'winnerIndex';
  static const String turnDeadline = 'turnDeadline';
  static const String roundCount = 'roundCount';
  static const String activeDeckEvent = 'activeDeckEvent';
}

class GameStatePayload {
  final int myPlayerIndex;
  final int currentPlayer;
  final bool direction;
  final IshiCard? topCard;
  final int deckSize;
  final List<IshiCard> myHand;
  final List<int> opponentHandSizes;
  final int pendingDrawCount;
  final int? declaredColorIndex;
  final List<int> actionPoints;
  final List<int> cardDraws;
  final bool hasPlayedCard;
  final bool hasDrawnCard;
  final List<List<Relic>> playerRelics;
  final int? winnerIndex;
  final int turnDeadline;
  final int roundCount;
  final int activeDeckEventIndex;

  GameStatePayload({
    required this.myPlayerIndex,
    required this.currentPlayer,
    required this.direction,
    this.topCard,
    required this.deckSize,
    required this.myHand,
    required this.opponentHandSizes,
    required this.pendingDrawCount,
    this.declaredColorIndex,
    required this.actionPoints,
    required this.cardDraws,
    required this.hasPlayedCard,
    required this.hasDrawnCard,
    required this.playerRelics,
    this.winnerIndex,
    required this.turnDeadline,
    required this.roundCount,
    required this.activeDeckEventIndex,
  });

  // Serialization
  StringDynamicMap toJson() => {
    _GameKey.myPlayerIndex: myPlayerIndex,
    _GameKey.currentPlayer: currentPlayer,
    _GameKey.direction: direction,
    _GameKey.topCard: topCard?.toJson(),
    _GameKey.deckSize: deckSize,
    _GameKey.myHand: myHand.map((c) => c.toJson()).toList(),
    _GameKey.opponentHandSizes: opponentHandSizes,
    _GameKey.pendingDrawCount: pendingDrawCount,
    _GameKey.declaredColor: declaredColorIndex,
    _GameKey.actionPoints: actionPoints,
    _GameKey.cardDraws: cardDraws,
    _GameKey.hasPlayedCard: hasPlayedCard,
    _GameKey.hasDrawnCard: hasDrawnCard,
    _GameKey.playerRelics: playerRelics
        .map((list) => list.map((r) => r.toJson()).toList())
        .toList(),
    _GameKey.winnerIndex: winnerIndex,
    _GameKey.turnDeadline: turnDeadline,
    _GameKey.roundCount: roundCount,
    _GameKey.activeDeckEvent: activeDeckEventIndex,
  };

  // Deserialization
  factory GameStatePayload.fromJson(StringDynamicMap json) => GameStatePayload(
    myPlayerIndex: json[_GameKey.myPlayerIndex] as int,
    currentPlayer: json[_GameKey.currentPlayer] as int,
    direction: json[_GameKey.direction] as bool,
    topCard: json[_GameKey.topCard] != null
        ? IshiCard.fromJson(json[_GameKey.topCard])
        : null,
    deckSize: json[_GameKey.deckSize] as int,
    myHand: (json[_GameKey.myHand] as List)
        .map((c) => IshiCard.fromJson(c as StringDynamicMap))
        .toList(),
    opponentHandSizes: List<int>.from(json[_GameKey.opponentHandSizes]),
    pendingDrawCount: json[_GameKey.pendingDrawCount] as int,
    declaredColorIndex: json[_GameKey.declaredColor] as int?,
    actionPoints: List<int>.from(json[_GameKey.actionPoints]),
    cardDraws: List<int>.from(json[_GameKey.cardDraws]),
    hasPlayedCard: json[_GameKey.hasPlayedCard] as bool,
    hasDrawnCard: json[_GameKey.hasDrawnCard] as bool,
    playerRelics: (json[_GameKey.playerRelics] as List)
        .map(
          (list) => (list as List)
              .map((r) => Relic.fromJson(r as StringDynamicMap))
              .toList(),
        )
        .toList(),
    winnerIndex: json[_GameKey.winnerIndex] as int?,
    turnDeadline: json[_GameKey.turnDeadline] as int,
    roundCount: json[_GameKey.roundCount] as int,
    activeDeckEventIndex: json[_GameKey.activeDeckEvent] as int,
  );
}
