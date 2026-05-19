import 'package:flutter/material.dart';
import 'package:ishi/core/dev/dev_console.dart';
import 'autocomplete_input.dart';

class DevConsoleOverlay extends StatefulWidget {
  final VoidCallback onClose;
  const DevConsoleOverlay({super.key, required this.onClose});

  @override
  State<DevConsoleOverlay> createState() => _DevConsoleOverlayState();
}

class _DevConsoleOverlayState extends State<DevConsoleOverlay> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    DevConsole().onLogAdded = () {
      if (!mounted) return;
      setState(() {});
      // Auto-scroll to the bottom when a new log appears
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    };
    DevConsole().onExit = widget.onClose;
  }

  @override
  void dispose() {
    DevConsole().dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: const Border(
          bottom: BorderSide(color: Colors.greenAccent, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            LogHistory(scrollController: _scrollController),
            AutocompleteInput(devConsoleOverlay: widget),
          ],
        ),
      ),
    );
  }
}

class LogHistory extends StatelessWidget {
  const LogHistory({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        controller: scrollController,
        padding: const .all(8),
        itemCount: DevConsole().logs.length,
        itemBuilder: (_, index) => Text(
          DevConsole().logs[index],
          style: const TextStyle(
            color: Colors.greenAccent,
            fontFamily: 'Courier',
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
