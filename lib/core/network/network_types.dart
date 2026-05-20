part of 'network_messages.dart';

enum NetType {
  ping,
  pong,
  playerJoined,
  requestLobbyState,
  lobbyState,
  lobbySyncResponse,
  gameStateUpdate,
  playIntent,
  setProfile,
  kicked,
  systemNotification,
  lobbySettings,
  deckEventSync,
}

enum IntentAction {
  drawCard,
  endTurn,
  takePenalty,
  playCard,
  activateRelic,
  requestDeckRestock,
}

sealed class NetMessage {
  const NetMessage();

  StringDynamicMap toJson();

  factory NetMessage.fromJson(StringDynamicMap json) {
    final typeStr = json[_NetKey.type] as String?;
    final NetType type = NetType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => throw FormatException('Unknown message type: $typeStr'),
    );

    switch (type) {
      case .ping:
        return PingMessage.fromJson(json);
      case .pong:
        return PongMessage.fromJson(json);
      case .playerJoined:
        return PlayerJoinedMessage.fromJson(json);
      case .requestLobbyState:
        return RequestLobbyStateMessage.fromJson(json);
      case .lobbyState:
        return LobbyStateMessage.fromJson(json);
      case .lobbySyncResponse:
        return LobbySyncResponseMessage.fromJson(json);
      case .gameStateUpdate:
        return GameStateMessage.fromJson(json);
      case .playIntent:
        return PlayIntentMessage.fromJson(json);
      case .setProfile:
        return SetProfileMessage.fromJson(json);
      case .kicked:
        return KickedMessage.fromJson(json);
      case .systemNotification:
        return SystemNotificationMessage.fromJson(json);
      case .lobbySettings:
        return LobbySettingsMessage.fromJson(json);
      case .deckEventSync:
        return DeckEventSyncMessage.fromJson(json);
    }
  }
}
