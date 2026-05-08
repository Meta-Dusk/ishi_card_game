import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:esther_gift/core/data_types.dart';
import 'package:esther_gift/core/network_keys.dart';

class SocketService {
  // Singleton pattern so the whole app shares one connection
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // --- PERSISTENT STATES ---
  int currentPlayers = 1; // Always starts with 1 (the Host)

  // --- HOST STATE ---
  HttpServer? _server;
  final List<WebSocket> _clients = [];

  // --- CLIENT STATE ---
  WebSocket? _clientSocket;

  // UI listens to this stream for updates!
  final _messageController = StreamController<StringDynamicMap>.broadcast();
  Stream<StringDynamicMap> get messages => _messageController.stream;

  // Helper getters
  bool get isHost => _server != null;
  bool get isConnected => _clientSocket != null || isHost;

  // ==========================================
  // HOST: START SERVER
  // ==========================================
  Future<void> startServer(String ip, int port) async {
    // Bind to 'anyIPv4' so it listens on both 127.0.0.1 AND 192.168.x.x!
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    debugPrint('Host Server running internally on all interfaces, port: $port');
    debugPrint('Broadcasting IP to UI as: $ip');

    _server!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocket socket = await WebSocketTransformer.upgrade(request);
        _clients.add(socket);
        currentPlayers = _clients.length + 1;

        socket.listen(
          (data) {
            final message = jsonDecode(data);
            _messageController.add(message);
          },
          onDone: () => _handleDisconnect(socket),
          onError: (_) => _handleDisconnect(socket),
        );

        debugPrint('Client connected! Total clients: ${_clients.length}');
        broadcast({
          NetKey.type: NetKey.playerJoined,
          NetKey.clientCount: _clients.length,
        });
      }
    });
  }

  // ==========================================
  // CLIENT: CONNECT TO HOST
  // ==========================================
  Future<bool> connectToHost(String wsUrl) async {
    try {
      _clientSocket = await WebSocket.connect(wsUrl);
      debugPrint('Connected to Host: $wsUrl');

      _clientSocket!.listen(
        (data) {
          final message = jsonDecode(data);

          if (message[NetKey.type] == NetKey.playerJoined) {
            currentPlayers = message[NetKey.clientCount];
          }

          _messageController.add(message); // Pass to UI
        },
        onDone: () => disconnect(),
        onError: (_) => disconnect(),
      );
      return true;
    } catch (e) {
      debugPrint('Connection failed: $e');
      return false;
    }
  }

  void _handleDisconnect(WebSocket socket) {
    _clients.remove(socket);
    currentPlayers = _clients.length + 1;
    broadcast({
      NetKey.type: NetKey.playerJoined,
      NetKey.clientCount: currentPlayers,
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
    _server?.close(force: true);
    _clientSocket?.close();
    _server = null;
    _clientSocket = null;
    _clients.clear();
  }
}
