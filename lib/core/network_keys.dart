part of 'network_messages.dart';

class _NetKey {
  // --- MESSAGE TYPES ---
  static const String type = 'type';
  // static const String playerJoined = 'PLAYER_JOINED';
  // static const String requestLobbyState = 'REQUEST_LOBBY_STATE';
  // static const String gameStateUpdate = 'GAME_STATE_UPDATE';
  // static const String playIntent = 'PLAY_INTENT';
  // static const String lobbySyncResponse = "LOBBY_SYNC_RESPONSE";

  // --- LOBBY PAYLOADS ---
  // static const String ping = 'PING';
  // static const String pong = 'PONG';
  static const String timestamp = 'timestamp';
  static const String payload = 'payload';

  // static const String lobbyState = 'LOBBY_STATE';
  // static const String lobbyName = 'lobbyName';
  static const String playersList = 'playersList';
  static const String playerName = 'playerName';
  static const String pingMs = 'pingMs';

  // static const String clientCount = 'clientCount';
  static const String totalPlayers = 'totalPlayers';
  static const String avatarColor = 'avatarColor';

  // --- GAME STATE PAYLOADS ---
  static const String playerIndex = 'playerIndex';
  // static const String myPlayerIndex = 'myPlayerIndex';
  // static const String currentPlayer = 'currentPlayer';
  // static const String direction = 'direction';
  // static const String topCard = 'topCard';
  // static const String deckSize = 'deckSize';
  // static const String myHand = 'myHand';
  // static const String opponentHandSizes = 'opponentHandSizes';
  // static const String pendingDrawCount = 'pendingDrawCount';
  static const String declaredColor = 'declaredColor';
  // static const String actionPoints = 'actionPoints';
  // static const String cardDraws = 'cardDraws';
  // static const String hasPlayedCard = 'hasPlayedCard';
  // static const String hasDrawnCard = 'hasDrawnCard';
  // static const String playerRelics = 'playerRelics';

  // --- INTENT ACTIONS ---
  static const String action = 'action';
  // static const String drawCard = 'DRAW_CARD';
  // static const String endTurn = 'END_TURN';
  // static const String takePenalty = 'TAKE_PENALTY';
  // static const String playCard = 'PLAY_CARD';
  // static const String setProfile = "SET_PROFILE";

  // --- ACTION PAYLOADS ---
  static const String cardId = 'cardId';
  static const String relicId = 'relicId';
}
