import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static Gradient introBgGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.14),
      const Color(0x45010100),
      const Color(0xA6474747),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
