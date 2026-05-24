import 'package:flutter/material.dart';
import 'package:ishi/core/assets.dart';
import 'color_ring.dart';
import 'card_designs.dart';
import 'minimalist_card.dart';
import 'package:ishi/core/models/ishi_card.dart';

typedef WidgetRecord = ({Widget centerWidget, Widget cornerWidget});

class CardFront extends StatelessWidget {
  const CardFront({
    super.key,
    required this.card,
    this.underlinedNumbers = const [6, 9],
  });

  final IshiCard card;
  final List<int> underlinedNumbers;

  Color get getCardBgColor {
    switch (card.color) {
      case .red:
        return Colors.red.shade600;
      case .blue:
        return Colors.blue.shade600;
      case .green:
        return Colors.green.shade600;
      case .yellow:
        return Colors.amber.shade500;
      case .wild:
        return Colors.black;
    }
  }

  bool get _needsUnderline => underlinedNumbers.contains(card.number);

  WidgetRecord get numberWidgets => (
    centerWidget: Text(
      card.number.toString(),
      style: TextStyle(
        fontSize: 80,
        fontWeight: .w300,
        color: Colors.white,
        decoration: _needsUnderline ? .underline : .none,
        decorationColor: Colors.white,
      ),
    ),
    cornerWidget: Text(
      card.number.toString(),
      style: TextStyle(
        fontSize: 18,
        fontWeight: .w300,
        color: Colors.white,
        decoration: _needsUnderline ? .underline : .none,
        decorationColor: Colors.white,
      ),
    ),
  );

  WidgetRecord get skipWidgets => const (
    centerWidget: Icon(Icons.block, size: 70, color: Colors.white),
    cornerWidget: Icon(Icons.block, size: 16, color: Colors.white),
  );

  WidgetRecord get reverseWidgets => const (
    centerWidget: Icon(Icons.swap_vert, size: 70, color: Colors.white),
    cornerWidget: Icon(Icons.swap_vert, size: 18, color: Colors.white),
  );

  WidgetRecord get draw2Widgets => const (
    centerWidget: SizedBox(
      width: 60,
      height: 80,
      child: Stack(
        children: [
          Positioned(top: 30, left: 10, child: OutlineCard()),
          Positioned(top: 10, left: 25, child: OutlineCard()),
        ],
      ),
    ),
    cornerWidget: Text(
      '+2',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  );

  WidgetRecord get chooseColorWidgets =>
      (centerWidget: ColorRing(size: 60), cornerWidget: ColorRing(size: 16));

  WidgetRecord get draw4Wigets => const (
    centerWidget: SizedBox(
      width: 70,
      height: 80,
      child: Stack(
        children: [
          // 4 staggered outlines in the 4 primary colors
          Positioned(top: 30, left: 0, child: OutlineCard(color: Colors.amber)),
          Positioned(
            top: 20,
            left: 15,
            child: OutlineCard(color: Colors.green),
          ),
          Positioned(top: 10, left: 30, child: OutlineCard(color: Colors.red)),
          Positioned(top: 0, left: 45, child: OutlineCard(color: Colors.blue)),
        ],
      ),
    ),
    cornerWidget: Text(
      '+4',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  );

  WidgetRecord get chestWidgets => (
    centerWidget: Assets.asImageIcon(
      Assets.cardIcons.chest,
      size: 60,
      color: Colors.amber,
    ),
    cornerWidget: Assets.asImageIcon(
      Assets.cardIcons.chest,
      size: 16,
      color: Colors.amber,
    ),
  );

  WidgetRecord _getWidgets(CardType cardType) {
    switch (card.type) {
      case .number:
        return numberWidgets;
      case .skip:
        return skipWidgets;
      case .reverse:
        return reverseWidgets;
      case .draw2:
        return draw2Widgets;
      case .chooseColor:
        return chooseColorWidgets;
      case .draw4:
        return draw4Wigets;
      case .chest:
        return chestWidgets;
    }
  }

  @override
  Widget build(BuildContext context) => MinimalistCard(
    cardColor: getCardBgColor,
    widgets: _getWidgets(card.type),
  );
}

class CardBack extends StatelessWidget {
  const CardBack({
    super.key,
    this.width = 120,
    this.height = 180,
    this.fontSize = 20,
    this.decoration,
  });

  final double width;
  final double height;
  final double fontSize;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: Colors.black, borderRadius: .circular(12)),
    alignment: .center,
    child: Center(child: _CardBackTitle(fontSize: fontSize)),
  );
}

class _CardBackTitle extends StatelessWidget {
  const _CardBackTitle({this.fontSize = 20});
  final double fontSize;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Text(
        "ISHI",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: .w900,
          letterSpacing: 16,
          foreground: Paint()
            ..style = .stroke
            ..strokeWidth = 1
            ..color = Colors.white,
        ),
      ),
      Text(
        "ISHI",
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: .w900,
          letterSpacing: 16,
          color: Colors.black,
        ),
      ),
    ],
  );
}
