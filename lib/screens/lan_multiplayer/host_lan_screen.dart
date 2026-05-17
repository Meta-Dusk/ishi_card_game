import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ishi/services/socket_service.dart';
import '../lobby/lobby_waiting_screen.dart';

class HostLANLobbyScreen extends StatefulWidget {
  const HostLANLobbyScreen({super.key, required this.onBack});

  final void Function(BuildContext) onBack;

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

    if (localIp == null) {
      setState(() => _webSocketUrl = 'error');
      return;
    }

    try {
      await SocketService().startServer(localIp, 8080);
      setState(() => _webSocketUrl = 'ws://$localIp:8080');
    } catch (e) {
      debugPrint("Server failed to start: $e");
      setState(() => _webSocketUrl = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () async {
            await SocketService().disconnect();
            if (context.mounted) widget.onBack(context);
          },
        ),
      ),
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(Tween<double>(begin: 0.9, end: 1.0)),
              child: child,
            ),
          ),
          child: _webSocketUrl == null
              ? const CircularProgressIndicator(
                  key: ValueKey("loadingWebSocket"),
                ).animate().fadeIn(delay: 600.ms)
              : _webSocketUrl == 'error'
              ? ErrorView(
                  key: const ValueKey("errorView"),
                  hostLanLobbyScreen: widget,
                )
              : JoinView(
                  key: const ValueKey("joinView"),
                  webSocketUrl: _webSocketUrl,
                ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.hostLanLobbyScreen});

  final HostLANLobbyScreen hostLanLobbyScreen;

  @override
  Widget build(BuildContext context) {
    var mainContent = [
      const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
      const SizedBox(height: 16),
      const Text(
        "Failed to start LAN server.",
        style: TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        onPressed: () => hostLanLobbyScreen.onBack(context),
        child: const Text("GO BACK"),
      ),
    ];

    return Column(
      key: const ValueKey("errorView"),
      mainAxisAlignment: .center,
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }
}

class JoinView extends StatelessWidget {
  const JoinView({super.key, required this.webSocketUrl});

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

    return Column(
      mainAxisAlignment: .center,
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, curve: Curves.easeOutCubic),
    );
  }
}
