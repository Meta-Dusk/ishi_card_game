import 'dart:io' show Platform;

import 'package:esther_gift/screens/lobby_waiting_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinGameScreen extends StatefulWidget {
  const JoinGameScreen({super.key});

  @override
  State<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends State<JoinGameScreen> {
  bool _isConnecting = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isConnecting) return; // Prevent multiple fires from the scanner

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String scannedCode = barcodes.first.rawValue!;

      // Validate it's actually our game's WebSocket URL
      if (scannedCode.startsWith('ws://')) {
        setState(() => _isConnecting = true);
        await _connect(scannedCode);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to $scannedCode...')),
        );
      }
    }
  }

  Future<void> _connect(String url) async {
    final success = await SocketService().connectToHost(url);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected to Lobby!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LobbyWaitingScreen()),
      );
    } else {
      setState(() => _isConnecting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection Failed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showManualEntry() {
    final TextEditingController ipController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _ManualEntryDialog(
        ipController: ipController,
        onJoin: () {
          Navigator.pop(context);
          setState(() => _isConnecting = true);

          String cleanIp = ipController.text.trim();

          // If you accidentally pasted the "ws://", strip it out
          if (cleanIp.startsWith('ws://')) cleanIp = cleanIp.substring(5);

          // If you accidentally pasted the ":8080", strip it out
          if (cleanIp.endsWith(':8080')) {
            cleanIp = cleanIp.replaceAll(':8080', '');
          }

          _connect('ws://$cleanIp:8080');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainContent = [
      if (!_isDesktop) _mobileScanner() else _windowsFallbackUi(),
      if (_isConnecting) _loadingView(),
      if (!_isDesktop) _scanHostQrLabel(),
      _ManulEntryButton(onShowManualEntry: _showManualEntry),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(alignment: .center, children: mainContent),
    );
  }

  Positioned _scanHostQrLabel() {
    return const Positioned(
      top: 60,
      child: Text(
        "SCAN HOST QR",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: .bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Container _loadingView() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      ),
    );
  }

  Widget _windowsFallbackUi() {
    final mainContent = [
      Icon(Icons.desktop_windows, size: 80, color: Colors.grey.shade800),
      const SizedBox(height: 16),
      const Text(
        "CAMERA NOT SUPPORTED ON DESKTOP",
        style: TextStyle(color: Colors.grey, fontWeight: .bold),
      ),
      const SizedBox(height: 8),
      const Text(
        "Please use the Manual Entry button below.",
        style: TextStyle(color: Colors.grey),
      ),
    ];
    return Center(
      child: Column(mainAxisAlignment: .center, children: mainContent),
    );
  }

  MobileScanner _mobileScanner() {
    return MobileScanner(
      onDetect: _onDetect,
      overlayBuilder: (_, constraints) => Container(
        decoration: BoxDecoration(
          border: .all(color: Colors.orangeAccent, width: 4),
          borderRadius: .circular(12),
        ),
        width: 250,
        height: 250,
        constraints: constraints,
      ),
    );
  }
}

class _ManulEntryButton extends StatelessWidget {
  const _ManulEntryButton({required this.onShowManualEntry});

  final VoidCallback onShowManualEntry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade900,
          padding: const .symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: .circular(12)),
        ),
        onPressed: onShowManualEntry,
        icon: const Icon(Icons.keyboard, color: Colors.white),
        label: const Text(
          "MANUAL ENTRY",
          style: TextStyle(
            color: Colors.white,
            fontWeight: .bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ManualEntryDialog extends StatelessWidget {
  const _ManualEntryDialog({required this.ipController, required this.onJoin});

  final TextEditingController ipController;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: const Text(
        "Manual Connect",
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: ipController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: "192.168.x.x",
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(onPressed: onJoin, child: const Text("JOIN")),
      ],
    );
  }
}
