import 'dart:io';
import 'package:ishi/screens/lobby_waiting_screen.dart';

import '../services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class HostLobbyScreen extends StatefulWidget {
  const HostLobbyScreen({super.key});

  @override
  State<HostLobbyScreen> createState() => _HostLobbyScreenState();
}

class _HostLobbyScreenState extends State<HostLobbyScreen> {
  String? _wsUrl;

  @override
  void initState() {
    super.initState();
    _initializeHost();
  }

  Future<void> _initializeHost() async {
    // Find the Local IP Address
    String? localIp;
    final interfaces = await NetworkInterface.list(
      type: .IPv4,
      includeLinkLocal: false,
    );

    for (NetworkInterface interface in interfaces) {
      for (InternetAddress addr in interface.addresses) {
        if (!addr.isLoopback && !addr.address.startsWith('169.254.')) {
          localIp = addr.address;
          break;
        }
      }
      if (localIp != null) break;
    }

    if (localIp != null) {
      setState(() => _wsUrl = 'ws://$localIp:8080');

      try {
        await SocketService().startServer(localIp, 8080);
      } catch (e) {
        debugPrint("Server failed to start: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: _wsUrl == null
            ? const CircularProgressIndicator()
            : _JoinView(wsUrl: _wsUrl),
      ),
    );
  }
}

class _JoinView extends StatelessWidget {
  const _JoinView({required this.wsUrl});

  final String? wsUrl;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "SCAN TO JOIN",
        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: .bold),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const .all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: .circular(16),
        ),
        child: QrImageView(data: wsUrl!, version: QrVersions.auto, size: 250.0),
      ),
      const SizedBox(height: 20),
      Text("IP: $wsUrl", style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 40),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const .symmetric(horizontal: 32, vertical: 12),
        ),
        onPressed: () {
          // Move the Host to the waiting room
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LobbyWaitingScreen()),
          );
        },
        child: const Text("ENTER LOBBY", style: TextStyle(fontWeight: .bold)),
      ),
    ];
    return Column(mainAxisAlignment: .center, children: mainContent);
  }
}
