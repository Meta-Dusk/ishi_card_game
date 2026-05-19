import 'package:ishi/core/data_types.dart';

part 'network_keys.dart';

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
}

enum IntentAction { drawCard, endTurn, takePenalty, playCard, activateRelic }

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
    }
  }
}

// --- SYSTEM & HEARTBEAT ---
class PingMessage extends NetMessage {
  final int timestamp;

  const PingMessage(this.timestamp);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.ping.name,
    _NetKey.timestamp: timestamp,
  };

  factory PingMessage.fromJson(StringDynamicMap json) =>
      PingMessage(json[_NetKey.timestamp] as int);
}

class PongMessage extends NetMessage {
  final int timestamp;

  const PongMessage(this.timestamp);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.pong.name,
    _NetKey.timestamp: timestamp,
  };

  factory PongMessage.fromJson(StringDynamicMap json) =>
      PongMessage(json[_NetKey.timestamp] as int);
}

// --- LOBBY MESSAGES ---
class PlayerJoinedMessage extends NetMessage {
  final int totalPlayers;

  const PlayerJoinedMessage(this.totalPlayers);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.playerJoined.name,
    _NetKey.totalPlayers: totalPlayers,
  };

  factory PlayerJoinedMessage.fromJson(StringDynamicMap json) =>
      PlayerJoinedMessage(json[_NetKey.totalPlayers] as int);
}

class RequestLobbyStateMessage extends NetMessage {
  final int playerIndex;

  const RequestLobbyStateMessage(this.playerIndex);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.requestLobbyState.name,
    _NetKey.playerIndex: playerIndex,
  };

  factory RequestLobbyStateMessage.fromJson(StringDynamicMap json) =>
      RequestLobbyStateMessage(json[_NetKey.playerIndex] as int);
}

class LobbyStateMessage extends NetMessage {
  final List<LobbyPlayer> playersList;

  const LobbyStateMessage(this.playersList);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.lobbyState.name,
    _NetKey.playersList: playersList.map((p) => p.toJson()).toList(),
  };

  factory LobbyStateMessage.fromJson(StringDynamicMap json) {
    final list = json[_NetKey.playersList] as List<dynamic>;
    return LobbyStateMessage(
      list.map((p) => LobbyPlayer.fromJson(p as StringDynamicMap)).toList(),
    );
  }
}

class LobbySyncResponseMessage extends NetMessage {
  final int totalPlayers;

  const LobbySyncResponseMessage(this.totalPlayers);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.lobbySyncResponse.name,
    _NetKey.totalPlayers: totalPlayers,
  };

  factory LobbySyncResponseMessage.fromJson(StringDynamicMap json) =>
      LobbySyncResponseMessage(json[_NetKey.totalPlayers] as int);
}

class SetProfileMessage extends NetMessage {
  final String playerName;
  final String avatarColorName;

  const SetProfileMessage(this.playerName, this.avatarColorName);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.setProfile.name,
    _NetKey.playerName: playerName,
    _NetKey.avatarColor: avatarColorName,
  };

  factory SetProfileMessage.fromJson(StringDynamicMap json) =>
      SetProfileMessage(
        json[_NetKey.playerName] as String,
        json[_NetKey.avatarColor] as String,
      );
}

// --- GAMEPLAY MESSAGES ---
class GameStateMessage extends NetMessage {
  final StringDynamicMap payload;

  const GameStateMessage(this.payload);

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.gameStateUpdate.name,
    _NetKey.payload: payload,
  };

  factory GameStateMessage.fromJson(StringDynamicMap json) =>
      GameStateMessage(json[_NetKey.payload] as StringDynamicMap);
}

class PlayIntentMessage extends NetMessage {
  final IntentAction action;
  final int playerIndex;
  final String? cardId;
  final int? declaredColor;
  final String? relicId;
  final List<String>? targetCardIds;
  final StringDynamicMap? polymorphTemplate;

  const PlayIntentMessage({
    required this.action,
    required this.playerIndex,
    this.cardId,
    this.declaredColor,
    this.relicId,
    this.targetCardIds,
    this.polymorphTemplate,
  });

  @override
  StringDynamicMap toJson() => {
    _NetKey.type: NetType.playIntent.name,
    _NetKey.action: action.name,
    _NetKey.playerIndex: playerIndex,
    if (cardId != null) _NetKey.cardId: cardId,
    if (declaredColor != null) _NetKey.declaredColor: declaredColor,
    if (relicId != null) _NetKey.relicId: relicId,
    if (targetCardIds != null) _NetKey.targetCardIds: targetCardIds,
    if (polymorphTemplate != null) _NetKey.polymorphTemplate: polymorphTemplate,
  };

  factory PlayIntentMessage.fromJson(StringDynamicMap json) {
    return PlayIntentMessage(
      action: IntentAction.values.firstWhere(
        (e) => e.name == json[_NetKey.action],
      ),
      playerIndex: json[_NetKey.playerIndex] as int,
      cardId: json[_NetKey.cardId] as String?,
      declaredColor: json[_NetKey.declaredColor] as int?,
      relicId: json[_NetKey.relicId] as String?,
      targetCardIds: json[_NetKey.targetCardIds] as List<String>?,
      polymorphTemplate: json[_NetKey.polymorphTemplate] as StringDynamicMap?,
    );
  }
}

// --- SYSTEM NOTIFICATIONS ---
class KickedMessage extends NetMessage {
  final String reason;

  const KickedMessage([this.reason = "You were kicked by the host."]);

  @override
  StringDynamicMap toJson() => {'type': NetType.kicked.name, 'reason': reason};

  factory KickedMessage.fromJson(StringDynamicMap json) =>
      KickedMessage(json['reason'] as String);
}

class SystemNotificationMessage extends NetMessage {
  final String text;

  const SystemNotificationMessage(this.text);

  @override
  StringDynamicMap toJson() => {
    'type': NetType.systemNotification.name,
    'text': text,
  };

  factory SystemNotificationMessage.fromJson(StringDynamicMap json) =>
      SystemNotificationMessage(json['text'] as String);
}

class LobbySettingsMessage extends NetMessage {
  final int startingHandSize;
  final int maxPlayers;

  const LobbySettingsMessage(this.startingHandSize, this.maxPlayers);

  @override
  StringDynamicMap toJson() => {
    'type': NetType.lobbySettings.name,
    'startingHandSize': startingHandSize,
    'maxPlayers': maxPlayers,
  };

  factory LobbySettingsMessage.fromJson(StringDynamicMap json) =>
      LobbySettingsMessage(
        json['startingHandSize'] as int,
        json['maxPlayers'] as int,
      );
}

class LobbyPlayer {
  String playerName;
  int pingMs;
  String avatarColorName;

  LobbyPlayer({
    required this.playerName,
    this.pingMs = 0,
    this.avatarColorName = "blue",
  });

  Map<String, dynamic> toJson() => {
    _NetKey.playerName: playerName,
    _NetKey.pingMs: pingMs,
    _NetKey.avatarColor: avatarColorName,
  };

  factory LobbyPlayer.fromJson(Map<String, dynamic> json) => LobbyPlayer(
    playerName: json[_NetKey.playerName] as String,
    pingMs: json[_NetKey.pingMs] as int,
    avatarColorName: json[_NetKey.avatarColor] as String,
  );
}
