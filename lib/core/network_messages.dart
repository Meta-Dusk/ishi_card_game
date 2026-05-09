enum _NetType { ping, pong, playerJoined, lobbyState, gameState }

sealed class NetMessage {
  const NetMessage();

  Map<String, dynamic> toJson();

  // The Master Parser: Converts raw JSON back into strongly typed objects
  factory NetMessage.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;

    // Convert string to enum for safer parsing
    final type = _NetType.values.firstWhere(
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
      case .lobbyState:
        return LobbyStateMessage.fromJson(json);
      case .gameState:
        return GameStateMessage.fromJson(json);
    }
  }
}

// --- HEARTBEAT MESSAGES ---
class PingMessage extends NetMessage {
  final int timestamp;
  PingMessage({required this.timestamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': _NetType.ping.name,
    'timestamp': timestamp,
  };

  factory PingMessage.fromJson(Map<String, dynamic> json) =>
      PingMessage(timestamp: json['timestamp'] as int);
}

class PongMessage extends NetMessage {
  final int timestamp;
  PongMessage({required this.timestamp});

  @override
  Map<String, dynamic> toJson() => {
    'type': _NetType.pong.name,
    'timestamp': timestamp,
  };

  factory PongMessage.fromJson(Map<String, dynamic> json) =>
      PongMessage(timestamp: json['timestamp'] as int);
}

// --- LOBBY MESSAGES ---
class PlayerJoinedMessage extends NetMessage {
  final int totalPlayers;
  PlayerJoinedMessage({required this.totalPlayers});

  @override
  Map<String, dynamic> toJson() => {
    'type': _NetType.playerJoined.name,
    'totalPlayers': totalPlayers,
  };

  factory PlayerJoinedMessage.fromJson(Map<String, dynamic> json) =>
      PlayerJoinedMessage(totalPlayers: json['totalPlayers'] as int);
}

class LobbyStateMessage extends NetMessage {
  final List<Map<String, dynamic>> playersList;
  LobbyStateMessage({required this.playersList});

  @override
  Map<String, dynamic> toJson() => {
    'type': _NetType.lobbyState.name,
    'playersList': playersList,
  };

  factory LobbyStateMessage.fromJson(Map<String, dynamic> json) =>
      LobbyStateMessage(
        playersList: List<Map<String, dynamic>>.from(json['playersList']),
      );
}

// --- GAMEPLAY MESSAGES ---
class GameStateMessage extends NetMessage {
  final Map<String, dynamic> payload;

  const GameStateMessage({required this.payload});

  @override
  Map<String, dynamic> toJson() => {
    'type': _NetType.gameState.name,
    'payload': payload,
  };

  factory GameStateMessage.fromJson(Map<String, dynamic> json) =>
      GameStateMessage(payload: json['payload'] as Map<String, dynamic>);
}
