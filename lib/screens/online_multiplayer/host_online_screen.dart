import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/screens/main_menu/main_menu_screen.dart';
import '../lobby/lobby_waiting_screen.dart';
import 'package:ishi/services/webrtc_service.dart';

class HostOnlineScreen extends StatefulWidget {
  const HostOnlineScreen({super.key, required this.onBack, required this.menu});

  final void Function(BuildContext context) onBack;
  final MainMenuScreenState menu;

  @override
  State<HostOnlineScreen> createState() => _HostOnlineScreenState();
}

class _HostOnlineScreenState extends State<HostOnlineScreen> {
  String _status = "Contacting Signaling Server...";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeHost();
  }

  Future<void> _initializeHost() async {
    // Tell WebRTC to create the Supabase room
    final code = await WebRTCService().createRoom();

    if (!mounted) return;

    if (code != null) {
      // Room created successfully! Jump straight to the lobby.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Pass the WebRTC engine into the network contract!
          builder: (_) =>
              LobbyWaitingScreen(network: WebRTCService(), menu: widget.menu),
        ),
      );
    } else {
      setState(() {
        _status = "Failed to create room.";
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      if (!_hasError) const CircularProgressIndicator(color: Colors.blueAccent),
      if (_hasError)
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
      const SizedBox(height: 24),
      Text(
        _status,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: .bold,
          letterSpacing: 1,
        ),
      ),
      if (_hasError) ...[
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => widget.onBack(context),
          child: const Text("GO BACK"),
        ),
      ],
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: mainContent
              .animate(interval: 100.ms)
              .fadeIn(duration: 400.ms)
              .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}
