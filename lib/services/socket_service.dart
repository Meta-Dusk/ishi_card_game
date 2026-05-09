import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:ishi/core/data_types.dart';
import 'package:ishi/core/managers/profile_manager.dart';
import 'package:ishi/core/network_keys.dart';

class SocketService {
  // Singleton pattern so the whole app shares one connection
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // --- PERSISTENT STATES ---
  int currentPlayers = 1;

  // THE NEW GLOBAL PLAYERS LIST
  List<Map<String, dynamic>> playersList = [];
  Timer? _pingTimer;

  // --- HOST STATE ---
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  // --- CLIENT STATE ---
  WebSocket? _clientSocket;

  final _messageController = StreamController<StringDynamicMap>.broadcast();
  Stream<StringDynamicMap> get messages => _messageController.stream;

  bool get isHost => _server != null;
  bool get isConnected => _clientSocket != null || isHost;

  // ==========================================
  // HOST: START SERVER
  // ==========================================
  Future<void> startServer(String ip, int port) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    playersList = [
      {NetKey.playerName: ProfileManager().playerName, NetKey.pingMs: 0},
    ];

    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      broadcast({
        NetKey.type: NetKey.ping,
        NetKey.timestamp: DateTime.now().millisecondsSinceEpoch,
      });
    });

    _server!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocket socket = await WebSocketTransformer.upgrade(request);
        _clients.add(socket);
        currentPlayers = _clients.length + 1;
        playersList.add({
          NetKey.playerName: ProfileManager().playerName,
          NetKey.pingMs: 0,
        });

        // Immediately broadcast the total count and list to EVERYONE
        broadcast({
          NetKey.type: NetKey.playerJoined,
          NetKey.totalPlayers: currentPlayers, // Use explicit total!
        });
        broadcast({
          NetKey.type: NetKey.lobbyState,
          NetKey.playersList: playersList,
        });

        socket.listen(
          (data) => _onStartServer(data, socket),
          onDone: () => _handleDisconnect(socket),
          onError: (_) => _handleDisconnect(socket),
        );
      }
    });
  }

  void _onStartServer(dynamic data, WebSocket socket) {
    final message = jsonDecode(data);

    if (message[NetKey.type] == NetKey.pong) {
      int rtt =
          DateTime.now().millisecondsSinceEpoch -
          (message[NetKey.timestamp] as int);
      int clientIndex = _clients.indexOf(socket) + 1;
      if (clientIndex > 0 && clientIndex < playersList.length) {
        playersList[clientIndex][NetKey.pingMs] = rtt ~/ 2;
      }
      broadcast({
        NetKey.type: NetKey.lobbyState,
        NetKey.playersList: playersList,
      });
      return;
    }

    // Respond to late-joining clients asking for the state!
    if (message[NetKey.type] == NetKey.requestLobbyState) {
      broadcast({
        NetKey.type: NetKey.lobbyState,
        NetKey.playersList: playersList,
      });
      broadcast({
        NetKey.type: NetKey.playerJoined,
        NetKey.totalPlayers: currentPlayers,
      });
      return;
    }

    _messageController.add(message);
  }

  // ==========================================
  // CLIENT: CONNECT TO HOST
  // ==========================================
  Future<bool> connectToHost(String wsUrl) async {
    try {
      _clientSocket = await WebSocket.connect(wsUrl);

      sendIntent({
        NetKey.type: NetKey.setProfile,
        NetKey.playerName: ProfileManager().playerName,
      });

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
    final message = jsonDecode(data);

    if (message[NetKey.type] == NetKey.ping) {
      sendIntent({
        NetKey.type: NetKey.pong,
        NetKey.timestamp: message[NetKey.timestamp],
      });
      return;
    }

    if (message[NetKey.type] == NetKey.lobbyState) {
      playersList = List<Map<String, dynamic>>.from(
        message[NetKey.playersList],
      );
    }

    // Safely parse the total players regardless of old/new keys
    if (message[NetKey.type] == NetKey.playerJoined) {
      currentPlayers =
          message[NetKey.totalPlayers] ?? (message[NetKey.clientCount] + 1);
    }

    _messageController.add(message);
  }

  void _handleDisconnect(WebSocket socket) {
    int index = _clients.indexOf(socket);
    if (index != -1 && index + 1 < playersList.length) {
      playersList.removeAt(index + 1);
    }
    _clients.remove(socket);
    currentPlayers = _clients.length + 1;

    broadcast({
      NetKey.type: NetKey.playerJoined,
      NetKey.totalPlayers: currentPlayers,
    });
    broadcast({
      NetKey.type: NetKey.lobbyState,
      NetKey.playersList: playersList,
    });
  }

  // ==========================================
  // DATA TRANSMISSION
  // ==========================================

  /// Send data ONLY to a specific client (used for dealing private hands)
  void sendToClient(int clientIndex, StringDynamicMap data) {
    // Safety check to ensure the client exists
    if (clientIndex >= 0 && clientIndex < _clients.length) {
      _clients[clientIndex].add(jsonEncode(data));
    }
  }

  /// Host updates all clients
  void broadcast(StringDynamicMap data) {
    final jsonStr = jsonEncode(data);
    for (WebSocket client in _clients) {
      client.add(jsonStr);
    }

    if (isHost) _messageController.add(data);
  }

  /// Client asks Host to do something (e.g., play a card)
  void sendIntent(StringDynamicMap data) {
    if (_clientSocket == null) return;
    _clientSocket!.add(jsonEncode(data));
  }

  void disconnect() {
    _pingTimer?.cancel();
    _server?.close(force: true);
    _clientSocket?.close();
    _server = null;
    _clientSocket = null;
    _clients.clear();
    playersList.clear();
  }
}
