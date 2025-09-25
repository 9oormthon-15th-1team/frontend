import 'package:flutter/material.dart';

class AppTypography {
  static const String _fontFamily = 'KakaoSmallSans';

  // Title styles
  static const TextStyle titleLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20.0,
    fontWeight: FontWeight.w800,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.1,
  );

  static const TextStyle titleSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.1,
  );

  // Body styles
  static const TextStyle bodyDefault = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.0,
  );

  static const TextStyle bodyDefaultBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.0,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.0,
  );

  // Caption style
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.1,
  );

  // Helper method to get all typography styles
  static Map<String, TextStyle> get styles => {
    'titleLg': titleLg,
    'titleMd': titleMd,
    'titleSm': titleSm,
    'bodyDefault': bodyDefault,
    'bodyDefaultBold': bodyDefaultBold,
    'bodySm': bodySm,
    'caption': caption,
  };

  // Helper method to copy typography with color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  // Helper method to copy typography with weight
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }
}
