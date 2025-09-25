import 'package:flutter/material.dart';

class ColorPalette {
  final Color light;
  final Color lightHover;
  final Color lightActive;
  final Color normal;
  final Color normalHover;
  final Color normalActive;
  final Color dark;
  final Color darkHover;
  final Color darkActive;
  final Color darker;

  const ColorPalette({
    required this.light,
    required this.lightHover,
    required this.lightActive,
    required this.normal,
    required this.normalHover,
    required this.normalActive,
    required this.dark,
    required this.darkHover,
    required this.darkActive,
    required this.darker,
  });
}

class AppColors {
  static const ColorPalette orange = ColorPalette(
    light: Color(0XFFFFF1E9), // rgb(255, 240, 237)
    lightHover: Color(0XFFFFEADE), // rgb(255, 234, 222)
    lightActive: Color(0XFFFFD3BB), // rgb(255, 211, 187)
    normal: Color(0XFFFF7024), // rgb(255, 112, 36)
    normalHover: Color(0XFFE6520C), // rgb(230, 109, 32)
    normalActive: Color(0XFFCC5A1D), // rgb(204, 90, 29)
    dark: Color(0XFFBF541B), // rgb(179, 75, 16)
    darkHover: Color(0XFF994316), // rgb(153, 67, 22)
    darkActive: Color(0XFF733210), // rgb(115, 50, 16)
    darker: Color(0XFF59270D), // rgb(89, 39, 13)
  );

  static const ColorPalette red = ColorPalette(
    light: Color(0XFFFBECED), // rgb(251, 236, 237)
    lightHover: Color(0XFFF9E2E4), // rgb(248, 226, 228)
    lightActive: Color(0XFFF2C4C7), // rgb(242, 196, 199)
    normal: Color(0XFFD54049), // rgb(219, 70, 73)
    normalHover: Color(0XFFC03A42), // rgb(194, 58, 66)
    normalActive: Color(0XFFAA333A), // rgb(170, 51, 58)
    dark: Color(0XFFA03037), // rgb(160, 48, 55)
    darkHover: Color(0XFF80262C), // rgb(128, 38, 44)
    darkActive: Color(0XFF601D21), // rgb(96, 29, 33)
    darker: Color(0XFF4B161A), // rgb(75, 22, 26)
  );

  static const ColorPalette yellow = ColorPalette(
    light: Color(0XFFFFF8E6), // rgb(251, 236, 237)
    lightHover: Color(0XFFFFF5DA), // rgb(248, 226, 228)
    lightActive: Color(0XFFFEEAB2), // rgb(242, 196, 199)
    normal: Color(0XFFFCBC05), // rgb(219, 70, 73)
    normalHover: Color(0XFFE3A905), // rgb(194, 58, 66)
    normalActive: Color(0XFFCA9604), // rgb(170, 51, 58)
    dark: Color(0XFFBD8D04), // rgb(160, 48, 55)
    darkHover: Color(0XFF977103), // rgb(128, 38, 44)
    darkActive: Color(0XFF715502), // rgb(96, 29, 33)
    darker: Color(0XFF584202), // rgb(75, 22, 26)
  );
  static const ColorPalette black = ColorPalette(
    light: Color(0XFFE6E6E6), // rgb(238, 238, 240)
    lightHover: Color(0XFFD9D9D9), // rgb(218, 218, 221)
    lightActive: Color(0XFFB0B0B0), // rgb(176, 176, 176)
    normal: Color(0XFF000000), // rgb(0, 0, 0)
    normalHover: Color(0XFF000000), // rgb(0, 0, 0)
    normalActive: Color(0XFF000000), // rgb(0, 0, 0)
    dark: Color(0XFF000000), // rgb(0, 0, 0)
    darkHover: Color(0XFF000000), // rgb(0, 0, 0)
    darkActive: Color(0XFF000000), // rgb(0, 0, 0)
    darker: Color(0XFF000000), // rgb(0, 0, 0)
  );

  // Semantic colors
  static const ColorPalette primary = orange;
  static const ColorPalette secondary = black;
  static const ColorPalette error = red;

  // Text colors
  static const Color textPrimary = Color(0XFF000000);
  static const Color textSecondary = Color(0XFF666666);
  static const Color textOnPrimary = Color(0XFFFFFFFF);
  static const Color textOnSecondary = Color(0XFFFFFFFF);
  static const Color textOnError = Color(0XFFFFFFFF);
}
