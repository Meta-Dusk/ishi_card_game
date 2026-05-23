import 'package:flutter/material.dart';
import 'package:ishi/core/assets.dart';
import 'color_ring.dart';
import 'card_designs.dart';
import 'minimalist_card.dart';
import 'package:ishi/core/models/ishi_card.dart';

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

  bool get needsUnderline => underlinedNumbers.contains(card.number);

  @override
  Widget build(BuildContext context) {
    late Widget centerWidget;
    late Widget cornerWidget;

    switch (card.type) {
      case .number:
        centerWidget = Text(
          card.number.toString(),
          style: TextStyle(
            fontSize: 80,
            fontWeight: .w300,
            color: Colors.white,
            decoration: needsUnderline ? .underline : .none,
            decorationColor: Colors.white,
          ),
        );

        cornerWidget = Text(
          card.number.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: .w300,
            color: Colors.white,
            decoration: needsUnderline ? .underline : .none,
            decorationColor: Colors.white,
          ),
        );
        break;

      case .skip:
        centerWidget = const Icon(Icons.block, size: 70, color: Colors.white);
        cornerWidget = const Icon(Icons.block, size: 16, color: Colors.white);
        break;

      case .reverse:
        // swap_vert creates that classic two-way arrow look
        centerWidget = const Icon(
          Icons.swap_vert,
          size: 70,
          color: Colors.white,
        );
        cornerWidget = const Icon(
          Icons.swap_vert,
          size: 18,
          color: Colors.white,
        );
        break;

      case .draw2:
        cornerWidget = const Text(
          '+2',
          style: TextStyle(color: Colors.white, fontSize: 16),
        );
        centerWidget = const SizedBox(
          width: 60,
          height: 80,
          child: Stack(
            children: [
              Positioned(top: 30, left: 10, child: OutlineCard()),
              Positioned(top: 10, left: 25, child: OutlineCard()),
            ],
          ),
        );
        break;

      case .wild:
        cornerWidget = ColorRing(size: 16);
        centerWidget = ColorRing(size: 60);
        break;

      case .wildDraw4:
        cornerWidget = const Text(
          '+4',
          style: TextStyle(color: Colors.white, fontSize: 16),
        );
        centerWidget = const SizedBox(
          width: 70,
          height: 80,
          child: Stack(
            children: [
              // 4 staggered outlines in the 4 primary colors
              Positioned(
                top: 30,
                left: 0,
                child: OutlineCard(color: Colors.amber),
              ),
              Positioned(
                top: 20,
                left: 15,
                child: OutlineCard(color: Colors.green),
              ),
              Positioned(
                top: 10,
                left: 30,
                child: OutlineCard(color: Colors.red),
              ),
              Positioned(
                top: 0,
                left: 45,
                child: OutlineCard(color: Colors.blue),
              ),
            ],
          ),
        );
        break;

      case .chest:
        centerWidget = AppAssets.asImageIcon(
          AppAssets.cardIcons.chest,
          size: 60,
          color: Colors.amber,
        );
        cornerWidget = AppAssets.asImageIcon(
          AppAssets.cardIcons.chest,
          size: 16,
          color: Colors.amber,
        );
        break;
    }

    return MinimalistCard(
      cardColor: getCardBgColor,
      centerWidget: centerWidget,
      cornerWidget: cornerWidget,
    );
  }
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
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: .circular(12),
      ),
      alignment: .center,
      child: Center(child: CardBackTitle(fontSize: fontSize)),
    );
  }
}

class CardBackTitle extends StatelessWidget {
  const CardBackTitle({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
}
