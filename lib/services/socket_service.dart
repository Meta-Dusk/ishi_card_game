import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/core/network_messages.dart';
import 'package:ishi/services/network_service.dart';

class SocketService implements NetworkService {
  // Singleton pattern so the whole app shares one connection
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // --- OTHER STATES ---
  @override
  String? get currentRoomCode => null;

  // --- PERSISTENT STATES ---
  @override
  int currentPlayers = 1;

  @override
  List<LobbyPlayer> playersList = [];

  Timer? _pingTimer;

  // --- HOST STATE ---
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  // --- CLIENT STATE ---
  WebSocket? _clientSocket;

  final _messageController = StreamController<NetMessage>.broadcast();

  @override
  Stream<NetMessage> get messages => _messageController.stream;

  @override
  bool get isHost => _server != null;

  @override
  bool get isConnected => _clientSocket != null || isHost;

  // ==========================================
  // HOST: START SERVER
  // ==========================================
  Future<void> startServer(String ip, int port) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    playersList = [
      LobbyPlayer(playerName: ProfileManager().playerName, pingMs: 0),
    ];

    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      broadcast(PingMessage(DateTime.now().millisecondsSinceEpoch));
    });

    _server!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocket socket = await WebSocketTransformer.upgrade(request);
        _clients.add(socket);
        currentPlayers = _clients.length + 1;
        playersList.add(
          LobbyPlayer(playerName: "Player $currentPlayers", pingMs: 0),
        );

        // Immediately broadcast the total count and list to EVERYONE
        broadcast(PlayerJoinedMessage(currentPlayers));
        broadcast(LobbyStateMessage(playersList));

        socket.listen(
          (data) => _onStartServer(data, socket),
          onDone: () => _handleDisconnect(socket),
          onError: (_) => _handleDisconnect(socket),
        );
      }
    });
  }

  void _onStartServer(dynamic data, WebSocket socket) {
    final rawJson = jsonDecode(data);
    final message = NetMessage.fromJson(rawJson);

    switch (message) {
      case PongMessage(:final timestamp):
        int rtt = DateTime.now().millisecondsSinceEpoch - timestamp;
        int clientIndex = _clients.indexOf(socket) + 1;
        if (clientIndex > 0 && clientIndex < playersList.length) {
          playersList[clientIndex].pingMs = rtt ~/ 2;
        }
        broadcast(LobbyStateMessage(playersList));
        break;

      case RequestLobbyStateMessage():
        broadcast(LobbyStateMessage(playersList));
        broadcast(PlayerJoinedMessage(currentPlayers));
        break;

      case SetProfileMessage(:final playerName):
        // Update the name when the client officially connects!
        int clientIndex = _clients.indexOf(socket) + 1;
        if (clientIndex > 0 && clientIndex < playersList.length) {
          playersList[clientIndex].playerName = playerName;
        }
        broadcast(LobbyStateMessage(playersList));
        break;

      default:
        _messageController.add(message);
    }
  }

  // ==========================================
  // CLIENT: CONNECT TO HOST
  // ==========================================
  Future<bool> connectToHost(String wsUrl) async {
    try {
      _clientSocket = await WebSocket.connect(wsUrl);

      sendIntent(
        SetProfileMessage(
          ProfileManager().playerName,
          ProfileManager().avatarColor.toARGB32(),
        ),
      );

      _clientSocket!.listen(
        (data) => _onConnectToHost(data),
        onDone: () => disconnect(),
        onError: (_) => disconnect(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void _onConnectToHost(dynamic data) {
    final rawJson = jsonDecode(data);
    final message = NetMessage.fromJson(rawJson);

    switch (message) {
      case PingMessage(:final timestamp):
        sendIntent(PongMessage(timestamp));
        break;

      case LobbyStateMessage(:final playersList):
        this.playersList = List<LobbyPlayer>.from(playersList);
        _messageController.add(message); // Forward to UI
        break;

      case PlayerJoinedMessage(:final totalPlayers):
        currentPlayers = totalPlayers;
        _messageController.add(message); // Forward to UI
        break;

      default:
        _messageController.add(message);
    }
  }

  void _handleDisconnect(WebSocket socket) {
    int index = _clients.indexOf(socket);
    if (index != -1 && index + 1 < playersList.length) {
      playersList.removeAt(index + 1);
    }
    _clients.remove(socket);
    currentPlayers = _clients.length + 1;

    broadcast(PlayerJoinedMessage(currentPlayers));
    broadcast(LobbyStateMessage(playersList));
  }

  // ==========================================
  // DATA TRANSMISSION
  // ==========================================

  /// Send data ONLY to a specific client (used for dealing private hands)
  @override
  void sendToClient(int clientIndex, NetMessage message) {
    // Safety check to ensure the client exists
    if (clientIndex >= 0 && clientIndex < _clients.length) {
      _clients[clientIndex].add(jsonEncode(message.toJson()));
    }
  }

  /// Host updates all clients
  @override
  void broadcast(NetMessage message) {
    final jsonStr = jsonEncode(message.toJson());
    for (WebSocket client in _clients) {
      client.add(jsonStr);
    }

    if (isHost) _messageController.add(message);
  }

  /// Client asks Host to do something (e.g., play a card)
  @override
  void sendIntent(NetMessage message) {
    if (_clientSocket == null) return;
    _clientSocket!.add(jsonEncode(message.toJson()));
  }

  @override
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _server?.close(force: true);
    _clientSocket?.close();
    _server = null;
    _clientSocket = null;
    _clients.clear();
    playersList.clear();
  }
}
