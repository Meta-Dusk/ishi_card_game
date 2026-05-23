import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ishi/components/cards/card_display.dart';

class MinimalistCard extends StatelessWidget {
  final Color cardColor;
  final Widget? centerWidget;
  final Widget? cornerWidget;
  final WidgetRecord? widgets;
  final double width;
  final double height;

  const MinimalistCard({
    super.key,
    required this.cardColor,
    this.centerWidget,
    this.cornerWidget,
    this.widgets,
    this.width = 120,
    this.height = 180,
  }) : assert(
         centerWidget != null || cornerWidget != null || widgets != null,
         "[widgets] or both [centerWidget] and [cornerWidget] must be provided!",
       ),
       assert(
         (centerWidget == null && cornerWidget == null) || widgets == null,
         "Use either [widgets] or both [centerWidget] and [cornerWidget] only!",
       ),
       assert(
         (centerWidget == null) == (cornerWidget == null),
         "You must always provide both [centerWidget] and [cornerWidget] if using them!",
       );

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: .circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black26, offset: Offset(2, 4), blurRadius: 4),
      ],
    ),
    child: Stack(children: _stackedContent),
  );

  List<Widget> get _stackedContent => [
    _topLeftCorner(cornerWidget ?? widgets!.cornerWidget),
    Center(child: centerWidget ?? widgets!.centerWidget),
    _bottomRightCorner(cornerWidget ?? widgets!.cornerWidget),
  ];

  Positioned _topLeftCorner(Widget child) =>
      Positioned(top: 10, left: 10, child: child);

  /// Also rotates the widget by 180 degrees.
  Positioned _bottomRightCorner(Widget child) => Positioned(
    bottom: 10,
    right: 10,
    child: Transform.rotate(angle: math.pi, child: child),
  );
}
