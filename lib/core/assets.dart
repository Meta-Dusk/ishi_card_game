import 'package:flutter/material.dart';

class Assets {
  const Assets();

  static const relics = _Relics();
  static const particles = _Particles();
  static const cardIcons = _CardIcons();
  static const otherIcons = _OtherIcons();

  static Widget asImageIcon(String imagePath, {double? size, Color? color}) {
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: .contain,
      gaplessPlayback: true,
      color: color,
    );
  }
}

class _Relics {
  const _Relics();
  final String mightRing = "assets/images/might_ring.png";
  final String greedEye = "assets/images/greed_eye.png";
  final String polymorphStaff = "assets/images/polymorph_staff.png";
  final String goldenTicket = "assets/images/golden_ticket.png";
  final String obliterator = "assets/images/obliterator.png";
}

class _Particles {
  const _Particles();
  final String snowflake = "assets/images/snowflake.png";
}

class _CardIcons {
  const _CardIcons();
  final String chest = "assets/images/chest.png";
}

class _OtherIcons {
  const _OtherIcons();
  final String ishiIcon = "assets/images/ishi_transparent.png";
}
