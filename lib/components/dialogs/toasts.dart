import 'package:flutter/material.dart';

class SnackBars {
  static SnackBar simple(
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool? persist,
    bool showCloseIcon = true,
  }) => SnackBar(
    dismissDirection: .startToEnd,
    content: SnackbarWidget(message: message, showCloseButton: showCloseIcon),
    backgroundColor: Colors.transparent,
    elevation: 0.0,
    behavior: .floating,
    duration: duration,
    persist: persist,
  );

  static SnackBar error(
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool? persist,
    bool showCloseIcon = true,
  }) => SnackBar(
    dismissDirection: .startToEnd,
    content: SnackbarWidget(
      message: message,
      backgroundColor: Colors.red.shade600,
      showCloseButton: showCloseIcon,
    ),
    backgroundColor: Colors.transparent,
    elevation: 0.0,
    behavior: .floating,
    duration: duration,
    persist: persist,
  );
}

class SnackbarWidget extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool showCloseButton;

  const SnackbarWidget({
    super.key,
    required this.message,
    this.backgroundColor = Colors.black,
    this.borderColor = Colors.white,
    this.textColor = Colors.white,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final messageText = Text(
      message,
      style: TextStyle(color: textColor, fontWeight: .bold),
    );

    final mainContentWithClose = Row(
      mainAxisSize: .min,
      children: [
        Flexible(child: messageText),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          visualDensity: .compact,
          onPressed: ScaffoldMessenger.of(context).hideCurrentSnackBar,
        ),
      ],
    );

    final flexibleContent = Flexible(
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.9),
          borderRadius: .circular(16),
          border: .all(color: borderColor.withValues(alpha: 0.2), width: 2),
        ),
        padding: const .symmetric(horizontal: 16, vertical: 8),
        child: showCloseButton ? mainContentWithClose : messageText,
      ),
    );

    return Align(
      alignment: .center,
      child: Row(mainAxisSize: .min, children: [flexibleContent]),
    );
  }
}
