import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../lobby_waiting_screen.dart';
import '../../services/socket_service.dart';

class HostLANLobbyScreen extends StatefulWidget {
  const HostLANLobbyScreen({super.key});

  @override
  State<HostLANLobbyScreen> createState() => _HostLANLobbyScreenState();
}

class _HostLANLobbyScreenState extends State<HostLANLobbyScreen> {
  String? _webSocketUrl;

  @override
  void initState() {
    super.initState();
    _initializeHost();
  }

  String? _checkAddress(InternetAddress address) {
    if (!address.isLoopback && !address.address.startsWith('169.254.')) {
      return address.address;
    }
    return null;
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
        localIp = _checkAddress(addr);
        if (localIp != null) break;
      }
      if (localIp != null) break;
    }

    if (localIp == null) return;
    setState(() => _webSocketUrl = 'ws://$localIp:8080');

    try {
      await SocketService().startServer(localIp, 8080);
    } catch (e) {
      debugPrint("Server failed to start: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: _webSocketUrl == null
            ? const CircularProgressIndicator()
            : _JoinView(webSocketUrl: _webSocketUrl),
      ),
    );
  }
}

class _JoinView extends StatelessWidget {
  const _JoinView({required this.webSocketUrl});

  final String? webSocketUrl;

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
        child: QrImageView(
          data: webSocketUrl!,
          version: QrVersions.auto,
          size: 250.0,
        ),
      ),
      const SizedBox(height: 20),
      Text("IP: $webSocketUrl", style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 40),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const .symmetric(horizontal: 32, vertical: 12),
        ),
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LobbyWaitingScreen(network: SocketService()),
          ),
        ),
        child: const Text("ENTER LOBBY", style: TextStyle(fontWeight: .bold)),
      ),
    ];
    return Column(mainAxisAlignment: .center, children: mainContent);
  }
}
