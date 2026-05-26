import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:ishi/services/network_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ishi/core/network/network_messages.dart';
import 'package:ishi/core/managers/profile_manager.dart';

class WebRTCService implements NetworkService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  // --- STUN/TURN CONFIGURATION ---
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add Metered.ca TURN here later if needed!
    ],
  };

  // --- PERSISTENT STATES ---
  @override
  int currentPlayer = 1;

  @override
  List<LobbyPlayer> get playersList => listOfPlayers;

  List<LobbyPlayer> listOfPlayers = [];
  Timer? _pingTimer;

  // --- SUPABASE SIGNALING ---
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _signalingChannel;

  @override
  String? currentRoomCode;

  final String _localClientId = const Uuid().v4();

  // --- HOST STATE (STAR TOPOLOGY) ---
  @override
  bool isHost = false;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final List<String> _clientIds = []; // Maintains order for clientIndex math

  // --- CLIENT STATE ---
  RTCPeerConnection? _hostConnection;
  RTCDataChannel? _hostDataChannel;

  final _messageController = StreamController<NetMessage>.broadcast();

  @override
  Stream<NetMessage> get messages => _messageController.stream;

  @override
  bool get isConnected => _hostConnection != null || isHost;

  // ==========================================
  // HOST: CREATE ROOM
  // ==========================================
  Future<String?> createRoom() async {
    isHost = true;
    currentRoomCode = _generateRoomCode();

    listOfPlayers = [
      LobbyPlayer(
        playerName: ProfileManager().playerName,
        pingMs: 0,
        avatarColorName: ProfileManager().avatarColorName,
      ),
    ];

    // Register room code in the database
    await _supabase.from('rooms').insert({'id': currentRoomCode});

    // Subscribe to the high-speed signaling channel
    _signalingChannel = _supabase.channel('room:$currentRoomCode');

    _signalingChannel!
        .onBroadcast(
          event: 'join-request',
          callback: (payload) => _handleClientJoinRequest(payload),
        )
        .onBroadcast(
          event: 'answer',
          callback: (payload) => _handleClientAnswer(payload),
        )
        .onBroadcast(
          event: 'ice-candidate',
          callback: (payload) => _handleIceCandidate(payload, isHost: true),
        )
        .subscribe();

    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      broadcast(PingMessage(DateTime.now().millisecondsSinceEpoch));
    });

    return currentRoomCode;
  }

  Future<void> _handleClientJoinRequest(Map<String, dynamic> payload) async {
    final clientId = payload['clientId'];

    final pc = await createPeerConnection(_rtcConfig);
    _peerConnections[clientId] = pc;
    _clientIds.add(clientId);

    final dc = await pc.createDataChannel('game_data', RTCDataChannelInit());
    _setupDataChannel(dc, clientId);
    _dataChannels[clientId] = dc;

    pc.onIceCandidate = (candidate) {
      _signalingChannel?.sendBroadcastMessage(
        event: 'ice-candidate',
        payload: {'target': clientId, 'candidate': candidate.toMap()},
      );
    };

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _signalingChannel?.sendBroadcastMessage(
      event: 'offer',
      payload: {'target': clientId, 'offer': offer.toMap()},
    );
  }

  Future<void> _handleClientAnswer(Map<String, dynamic> payload) async {
    final clientId = payload['clientId'];
    if (_peerConnections.containsKey(clientId)) {
      final answer = RTCSessionDescription(
        payload['answer']['sdp'],
        payload['answer']['type'],
      );
      await _peerConnections[clientId]!.setRemoteDescription(answer);
    }
  }

  Future<void> lockLobby() async {
    if (isHost && currentRoomCode != null) {
      await _supabase.from('rooms').delete().eq('id', currentRoomCode!);
      // We don't clear the variable, we just delete it from the DB
      // so no one else can search for it!
    }
  }

  // ==========================================
  // CLIENT: JOIN ROOM
  // ==========================================
  Future<bool> joinRoom(String roomCode) async {
    isHost = false;
    currentRoomCode = roomCode.toUpperCase();

    // Check if the room exists in the DB before trying to signal
    final room = await _supabase
        .from('rooms')
        .select()
        .eq('id', currentRoomCode!)
        .maybeSingle();
    if (room == null) return false;

    _signalingChannel = _supabase.channel('room:$currentRoomCode');

    _signalingChannel!
        .onBroadcast(
          event: 'offer',
          callback: (payload) => _handleHostOffer(payload),
        )
        .onBroadcast(
          event: 'ice-candidate',
          callback: (payload) => _handleIceCandidate(payload, isHost: false),
        )
        .subscribe((status, [error]) {
          if (status == .subscribed) {
            // Request an offer from the host
            _signalingChannel?.sendBroadcastMessage(
              event: 'join-request',
              payload: {'clientId': _localClientId},
            );
          }
        });

    return true;
  }

  Future<void> _handleHostOffer(Map<String, dynamic> payload) async {
    if (payload['target'] != _localClientId) return;

    _hostConnection = await createPeerConnection(_rtcConfig);

    _hostConnection!.onIceCandidate = (candidate) {
      _signalingChannel?.sendBroadcastMessage(
        event: 'ice-candidate',
        payload: {'clientId': _localClientId, 'candidate': candidate.toMap()},
      );
    };

    _hostConnection!.onDataChannel = (channel) {
      _hostDataChannel = channel;
      _setupDataChannel(channel, 'HOST');

      // Send Profile upon successful connection!
      sendIntent(
        SetProfileMessage(
          ProfileManager().playerName,
          ProfileManager().avatarColorName,
        ),
      );
    };

    final offer = RTCSessionDescription(
      payload['offer']['sdp'],
      payload['offer']['type'],
    );
    await _hostConnection!.setRemoteDescription(offer);

    final answer = await _hostConnection!.createAnswer();
    await _hostConnection!.setLocalDescription(answer);

    _signalingChannel?.sendBroadcastMessage(
      event: 'answer',
      payload: {'clientId': _localClientId, 'answer': answer.toMap()},
    );
  }

  // ==========================================
  // SHARED LOGIC
  // ==========================================
  Future<void> _handleIceCandidate(
    Map<String, dynamic> payload, {
    required bool isHost,
  }) async {
    final candidateData = payload['candidate'];
    final candidate = RTCIceCandidate(
      candidateData['candidate'],
      candidateData['sdpMid'],
      candidateData['sdpMLineIndex'],
    );

    if (isHost) {
      final clientId = payload['clientId'];
      if (_peerConnections.containsKey(clientId)) {
        await _peerConnections[clientId]!.addCandidate(candidate);
      }
    } else {
      if (payload['target'] == _localClientId && _hostConnection != null) {
        await _hostConnection!.addCandidate(candidate);
      }
    }
  }

  void _setupDataChannel(RTCDataChannel channel, String peerId) {
    channel.onMessage = (RTCDataChannelMessage data) {
      if (!data.isBinary) _routeIncomingMessage(data.text, peerId);
    };

    channel.onDataChannelState = (RTCDataChannelState state) {
      if (state == .RTCDataChannelOpen && isHost) {
        // A new client successfully tunneled in!
        currentPlayer = _clientIds.length + 1;
        listOfPlayers.add(LobbyPlayer(playerName: "Connecting...", pingMs: 0));
        broadcast(PlayerJoinedMessage(currentPlayer));
        broadcast(LobbyStateMessage(listOfPlayers));
      } else if (state == .RTCDataChannelClosed) {
        _handleDisconnect(peerId);
      }
    };
  }

  void _routeIncomingMessage(String rawJsonStr, String peerId) {
    final rawJson = jsonDecode(rawJsonStr);
    final message = NetMessage.fromJson(rawJson);

    if (isHost) {
      switch (message) {
        case PongMessage(:final timestamp):
          int rtt = DateTime.now().millisecondsSinceEpoch - timestamp;
          int clientIndex = _clientIds.indexOf(peerId) + 1;
          if (clientIndex > 0 && clientIndex < listOfPlayers.length) {
            listOfPlayers[clientIndex].pingMs = rtt ~/ 2;
          }
          broadcast(LobbyStateMessage(listOfPlayers));
          break;
        case RequestLobbyStateMessage():
          broadcast(LobbyStateMessage(listOfPlayers));
          broadcast(PlayerJoinedMessage(currentPlayer));
          break;
        case SetProfileMessage(:final playerName, :final avatarColorName):
          int clientIndex = _clientIds.indexOf(peerId) + 1;
          if (clientIndex > 0 && clientIndex < listOfPlayers.length) {
            final player = listOfPlayers[clientIndex];
            player.playerName = playerName;
            player.avatarColorName = avatarColorName;
          }
          broadcast(LobbyStateMessage(listOfPlayers));
          break;
        default:
          _messageController.add(message);
      }
    } else {
      switch (message) {
        case PingMessage(:final timestamp):
          sendIntent(PongMessage(timestamp));
          break;
        case LobbyStateMessage(:final playersList):
          listOfPlayers = List<LobbyPlayer>.from(playersList);
          _messageController.add(message);
          break;
        case PlayerJoinedMessage(:final totalPlayers):
          currentPlayer = totalPlayers;
          _messageController.add(message);
          break;
        default:
          _messageController.add(message);
      }
    }
  }

  void _handleDisconnect(String peerId) {
    if (isHost) {
      int index = _clientIds.indexOf(peerId);
      if (index == -1) return;

      String leftName = "A player";
      if (index + 1 < listOfPlayers.length) {
        leftName = listOfPlayers[index + 1].playerName;
      }

      _clientIds.removeAt(index);
      _peerConnections[peerId]?.close();
      _peerConnections.remove(peerId);
      _dataChannels.remove(peerId);

      if (index + 1 < listOfPlayers.length) listOfPlayers.removeAt(index + 1);
      currentPlayer = _clientIds.length + 1;

      // Broadcast the departure!
      broadcast(SystemNotificationMessage("$leftName disconnected."));
      broadcast(PlayerJoinedMessage(currentPlayer));
      broadcast(LobbyStateMessage(listOfPlayers));
    } else {
      disconnect(); // Host dropped, client leaves
    }
  }

  // ==========================================
  // TRANSMISSION PROTOCOLS
  // ==========================================
  @override
  void sendToClient(int clientIndex, NetMessage message) {
    if (clientIndex >= 0 && clientIndex < _clientIds.length) {
      final clientId = _clientIds[clientIndex];
      _dataChannels[clientId]?.send(
        RTCDataChannelMessage(jsonEncode(message.toJson())),
      );
    }
  }

  @override
  void broadcast(NetMessage message) {
    final jsonStr = jsonEncode(message.toJson());
    for (var channel in _dataChannels.values) {
      if (channel.state == .RTCDataChannelOpen) {
        channel.send(RTCDataChannelMessage(jsonStr));
      }
    }
    if (isHost) _messageController.add(message);
  }

  @override
  void sendIntent(NetMessage message) {
    if (_hostDataChannel?.state == .RTCDataChannelOpen) {
      _hostDataChannel!.send(
        RTCDataChannelMessage(jsonEncode(message.toJson())),
      );
    }
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  @override
  void kickPlayer(int playerIndex, {String? reason}) {
    if (!isHost || playerIndex <= 0 || playerIndex > _clientIds.length) return;

    // CAPTURE the exact peer ID
    final String targetPeerId = _clientIds[playerIndex - 1];

    sendToClient(
      playerIndex - 1,
      reason == null ? const KickedMessage() : KickedMessage(reason),
    );

    // Give the WebRTC data channel time to transmit
    Future.delayed(
      const Duration(milliseconds: 500),
      () => _handleDisconnect(targetPeerId),
    );
  }

  @override
  void purgeInvalidPlayers() {
    if (!isHost) return;
    int purged = 0;

    for (int i = _clientIds.length - 1; i >= 0; i--) {
      final p = listOfPlayers[i + 1];

      if (p.playerName == "Player" || p.playerName == "Connecting...") {
        // Capture the peer ID
        final String targetPeerId = _clientIds[i];

        sendToClient(
          i,
          const KickedMessage("Purged by host due to invalid connection."),
        );

        Future.delayed(
          const Duration(milliseconds: 500),
          () => _handleDisconnect(targetPeerId),
        );
        purged++;
      }
    }

    if (purged > 0) {
      Future.delayed(
        const Duration(milliseconds: 600),
        () => broadcast(
          SystemNotificationMessage("Purged $purged ghost connection(s)."),
        ),
      );
    }
  }

  @override
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _signalingChannel?.unsubscribe();

    if (isHost && currentRoomCode != null) {
      await _supabase.from('rooms').delete().eq('id', currentRoomCode!);
    }

    _hostDataChannel?.close();
    _hostConnection?.close();
    for (RTCDataChannel dc in _dataChannels.values) {
      dc.close();
    }
    for (RTCPeerConnection pc in _peerConnections.values) {
      pc.close();
    }

    _dataChannels.clear();
    _peerConnections.clear();
    _clientIds.clear();
    listOfPlayers.clear();

    _hostDataChannel = null;
    _hostConnection = null;
    currentRoomCode = null;
    isHost = false;
  }
}
