import 'package:flutter/material.dart';

class CombatMessage {
  final String text;
  final Color color;
  final double fontSize;

  const CombatMessage({
    required this.text,
    this.color = Colors.redAccent,
    this.fontSize = 48,
  });
}

class FloatingCombatTextGroup extends StatelessWidget {
  final List<CombatMessage> messages;
  final Duration interval;

  const FloatingCombatTextGroup({
    super.key,
    required this.messages,
    this.interval = const Duration(milliseconds: 600),
  });

  @override
  Widget build(BuildContext context) => Stack(
    alignment: .center,
    clipBehavior: .none,
    children: List.generate(
      messages.length,
      (index) => _FloatingCombatText(
        message: messages[index],
        delay: interval * index,
      ),
    ),
  );
}

class _FloatingCombatText extends StatefulWidget {
  final CombatMessage message;
  final Duration delay;

  const _FloatingCombatText({required this.message, required this.delay});

  @override
  State<_FloatingCombatText> createState() => _FloatingCombatTextState();
}

class _FloatingCombatTextState extends State<_FloatingCombatText> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delay == .zero) {
      _isVisible = true;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _isVisible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 3),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.translate(
        offset: Offset(0, -120 * value),
        child: Opacity(opacity: 1.0 - value, child: child),
      ),
      child: Text(
        widget.message.text,
        textAlign: .center,
        style: TextStyle(
          fontSize: widget.message.fontSize,
          fontWeight: .w900,
          color: widget.message.color,
          letterSpacing: 2,
          shadows: const [
            Shadow(color: Colors.black87, offset: Offset(2, 4), blurRadius: 4),
            Shadow(
              color: Colors.black87,
              offset: Offset(-1, -1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
