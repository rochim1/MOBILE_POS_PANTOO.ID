import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // app color
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5F59);
  static const Color primarySoft = Color(0xFFE7F5F3);
  static const Color secondary = Color(0xFF159E91);
  static const Color accent = Color(0xFFF59E0B);

  // component color
  static const Color divider = Color(0xFFC6C6C8);
  static const Color dividerLight = Color(0xFFEBEBF5);
  static const Color danger = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF32D74B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;
  static const Color splash = Color(0x2AFFF8FF);
  static const Color listMenu = Color(0xFF1F3682);

  // border
  static final Color borderGrey = Colors.grey.shade300;

  // label text light
  static const Color labelPrimary = Color(0xFF3C3C43);
  static Color labelSecondary = const Color(0xFF3C3C43).withValues(alpha: 0.6);
  static Color labelTertiary = const Color(0xFF3C3C43).withValues(alpha: 0.3);
  static Color labelQuarternary = const Color(
    0xFF3C3C43,
  ).withValues(alpha: 0.18);

  // label text dark
  static Color labelPrimaryDark = const Color(0xFFFFFFFF);
  static Color labelSecondaryDark = const Color(0x99EBEBF5);
  static Color labelTertiaryDark = const Color(0x4CEBEBF5);
  static Color labelQuarternaryDark = const Color(0x2DEBEBF5);

  // fill color
  static Color fillPrimary = const Color(0xFF787880).withValues(alpha: 0.2);
  static Color fillSecondary = const Color(0xFF787880).withValues(alpha: 0.16);
  static Color fillTertiary = const Color(0xFF767680).withValues(alpha: 0.12);
  static Color fillQuarternary = const Color(
    0xFF747480,
  ).withValues(alpha: 0.08);

  // system fill color
  static const Color red = Color(0xFFFF3B30);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color green = Color(0xFF34C759);
  static const Color tial = Color(0xFF5AC8FA);
  static const Color blue = Color(0xFF007AFF);
  static const Color indigo = Color(0xFF5856D6);
  static const Color purple = Color(0xFFAF52DE);
  static const Color pink = Color(0xFFFF2D55);

  // system light color
  static const Color lightRed = Color(0xFFFFDDDB);
  static const Color lightOrange = Color(0xFFFFEDD3);
  static const Color lightYellow = Color(0xFFFFF6D3);
  static const Color lightGreen = Color(0xFFDBF6E2);
  static const Color lightTial = Color(0xFFE2F5FE);
  static const Color lightBlue = Color(0xFFD3E8FF);
  static const Color lightIndigo = Color(0xFFE2E2F8);
  static const Color lightPurple = Color(0xFFF1E1F9);
  static const Color lightPink = Color(0xFFFFDAE1);

  // backgroud color light
  static const Color bgPrimary = Color(0xFFF4F7FA);
  static const Color bgSecondary = Color(0xFFF2F2F7);

  // backgroud color dark
  static const Color bgPrimaryDark = Color(0xFF1C1C1E);
  static const Color bgSecondaryDark = Color(0xFF2C2C2E);

  // App Shimmer
  static const Color shimmerBaseColor = Color(0xFFCCCCCC);
  static const Color shimmerHighlightColor = Color(0xFFEFEFEF);

  /// [MaterialColor] theme map color
  static const MaterialColor grey = MaterialColor(0xFF8E8E93, <int, Color>{
    50: Color(0xFFF2F2F7), //10%
    100: Color(0xFFE5E5EA), //20%
    200: Color(0xFFD1D1D6), //30%
    300: Color(0xFFC7C7CC), //40%
    400: Color(0xFFAEAEB2), //50%
    500: Color(0xFF8E8E93), //60%
    600: Color(0xFF636366), //70%
    700: Color(0xFF48484A), //80%
    800: Color(0xFF3A3A3C), //90%
    850: Color(0xFF2C2C2E), //95%
    900: Color(0xFF1C1C1E), //100%
  });

  /// [MaterialColor] theme map color
  static const MaterialColor primaryTheme =
      MaterialColor(0xFF4CAF50, <int, Color>{
        50: Color(0xFFEAF5EA),
        100: Color(0xFFC9E7CB),
        200: Color(0xFFA6D7A8),
        300: Color(0xFF82C785),
        400: Color(0xFF67BB6A),
        500: Color(0xFF4CAF50),
        600: Color(0xFF45A849),
        700: Color(0xFF3C9F40),
        800: Color(0xFF339637),
        900: Color(0xFF248627),
      });
}
