import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/core/data_types.dart' show isPc;

class SequentialSplashAnimator extends StatefulWidget {
  final List<Widget> splashes;
  final VoidCallback onComplete;
  final Duration fadeDuration;
  final Duration holdDuration;

  const SequentialSplashAnimator({
    super.key,
    required this.splashes,
    required this.onComplete,
    this.fadeDuration = const Duration(milliseconds: 600),
    this.holdDuration = const Duration(seconds: 1),
  });

  @override
  State<SequentialSplashAnimator> createState() =>
      _SequentialSplashAnimatorState();
}

class _SequentialSplashAnimatorState extends State<SequentialSplashAnimator> {
  int _currentIndex = 0;
  bool _isFinished = false;

  void _finishSequence() {
    if (_isFinished) return;
    _isFinished = true;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.splashes.isEmpty) {
      widget.onComplete();
      return const SizedBox.shrink();
    }

    final splash = widget.splashes[_currentIndex]
        .animate(
          onComplete: (_) {
            if (_currentIndex < widget.splashes.length - 1) {
              setState(() => _currentIndex++);
            } else {
              widget.onComplete();
            }
          },
        )
        .fadeIn(duration: widget.fadeDuration, curve: Curves.easeOut)
        .then(delay: widget.holdDuration)
        .fadeOut(duration: widget.fadeDuration, curve: Curves.easeIn);

    final stackedContent = [
      Positioned.fill(child: Center(child: splash)),
      const Positioned(bottom: 32, left: 0, right: 0, child: _DismissText()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isInfinite
            ? MediaQuery.of(context).size.width
            : constraints.maxWidth;

        final double height = constraints.maxHeight.isInfinite
            ? MediaQuery.of(context).size.height
            : constraints.maxHeight;

        return GestureDetector(
          key: ValueKey<int>(_currentIndex),
          onTap: _finishSequence,
          behavior: .opaque,
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: const .all(16.0),
              child: Stack(children: stackedContent),
            ),
          ),
        );
      },
    );
  }
}

class _DismissText extends StatelessWidget {
  const _DismissText();

  @override
  Widget build(BuildContext context) => Text(
    "${isPc ? "Click" : "Tap"} anywhere to skip.",
    style: const TextStyle(
      color: Colors.blueGrey,
      fontStyle: .italic,
      fontSize: 16,
    ),
    textAlign: .center,
  );
}
