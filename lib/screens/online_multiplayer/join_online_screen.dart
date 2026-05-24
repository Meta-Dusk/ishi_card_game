import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/screens/main_menu/main_menu_screen.dart';
import '../lobby/lobby_waiting_screen.dart';
import 'package:ishi/services/webrtc_service.dart';

class JoinOnlineScreen extends StatefulWidget {
  final void Function(BuildContext) onBack;
  final MainMenuScreenState menu;

  const JoinOnlineScreen({super.key, required this.onBack, required this.menu});

  @override
  State<JoinOnlineScreen> createState() => _JoinOnlineScreenState();
}

class _JoinOnlineScreenState extends State<JoinOnlineScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isConnecting = false;

  Future<void> _connect(String? input) async {
    final code = input == null
        ? _codeController.text.trim().toUpperCase()
        : input.trim().toUpperCase();
    if (code.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room code must be exactly 5 letters."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    // Attempt the WebRTC handshake
    final success = await WebRTCService().joinRoom(code);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to Lobby!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LobbyWaitingScreen(network: WebRTCService(), menu: widget.menu),
        ),
      );
    } else {
      setState(() => _isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room not found or connection failed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stackedContent = [
      Center(
        child: Padding(
          padding: const .all(32.0),
          child: _JoinOnlineLobbyContent(
            codeController: _codeController,
            isConnecting: _isConnecting,
            onConnect: _connect,
          ),
        ),
      ),

      // The Overlay Loading State
      if (_isConnecting)
        Container(
          color: Colors.black87,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Colors.white,
          onPressed: () => widget.onBack(context),
        ),
        title: const Text(
          "JOIN ONLINE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: .bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(children: stackedContent),
    );
  }
}

class _JoinOnlineLobbyContent extends StatelessWidget {
  const _JoinOnlineLobbyContent({
    required this.codeController,
    required this.isConnecting,
    required this.onConnect,
  });

  final TextEditingController codeController;
  final bool isConnecting;
  final void Function(String?) onConnect;

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      const Text(
        "ENTER ROOM CODE",
        style: TextStyle(
          color: Colors.white70,
          fontSize: 18,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 24),

      // The 5-Letter Code Input
      TextField(
        controller: codeController,
        maxLength: 5,
        textCapitalization: .characters,
        textAlign: .center,
        onSubmitted: onConnect,
        autofocus: true,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: .bold,
          letterSpacing: 12,
          color: Colors.black87,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.grey.shade200,
          hintText: "XXXXX",
          border: OutlineInputBorder(
            borderRadius: .circular(16),
            borderSide: .none,
          ),
        ),
      ),

      const SizedBox(height: 32),
      SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: .circular(12)),
          ),
          onPressed: isConnecting ? null : () => onConnect(null),
          icon: const Icon(Icons.login),
          label: const Text(
            "CONNECT TO LOBBY",
            style: TextStyle(fontSize: 18, fontWeight: .bold, letterSpacing: 1),
          ),
        ),
      ),
    ];

    return Column(
      mainAxisAlignment: .center,
      children: mainContent
          .animate(interval: 100.ms)
          .fadeIn(duration: 400.ms)
          .slideY(delay: 100.ms, begin: 0.5, curve: Curves.easeOutCubic),
    );
  }
}
