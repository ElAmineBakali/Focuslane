import 'package:flutter/material.dart';

class FocuslaneSemanticTokens {
  static const Color darkBackgroundMain = Color(0xFF121318);
  static const Color darkCardBackground = Color(0xFF121318);
  static const Color darkFilledSurface = Color(0xFF34343A);
  static const Color darkBorder = Color(0xFF757575);
  static const Color darkPrimary = Color(0xFF6CA9A1);
  static const Color darkSecondary = Color(0xFF86BEB8);
  static const Color darkTextPrimary = Color(0xFFE3E2E9);
  static const Color darkTextSecondary = Color(0xFFC5C6D0);
  static const Color darkSidebarActive = Color(0x296CA9A1);

  static const Color lightBackgroundMain = Color(0xFFFAF8FF);
  static const Color lightCardBackground = Color(0xFFFAF8FF);
  static const Color lightFilledSurface = Color(0xFFE3E2E9);
  static const Color lightBorder = Color(0xFFBDBDBD);
  static const Color lightPrimary = Color(0xFF7FBEB7);
  static const Color lightSecondary = Color(0xFF9FD0CB);
  static const Color lightTextPrimary = Color(0xFF1A1B21);
  static const Color lightTextSecondary = Color(0xFF45464F);
  static const Color lightSidebarActive = Color(0x297FBEB7);

  static const Color chartBlue = Color(0xFF2196F3);
  static const Color chartGreen = Color(0xFF4CAF50);
  static const Color chartPurple = Color(0xFF9C27B0);
  static const Color chartOrange = Color(0xFFFF9800);
  static const Color chartRed = Color(0xFFF44336);

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color backgroundMain(BuildContext context) {
    return isDark(context) ? darkBackgroundMain : lightBackgroundMain;
  }

  static Color cardBackground(BuildContext context) {
    return isDark(context) ? darkCardBackground : lightCardBackground;
  }

  static Color filledSurface(BuildContext context) {
    return isDark(context) ? darkFilledSurface : lightFilledSurface;
  }

  static Color border(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color primary(BuildContext context) {
    return isDark(context) ? darkPrimary : lightPrimary;
  }

  static Color secondary(BuildContext context) {
    return isDark(context) ? darkSecondary : lightSecondary;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color sidebarActiveBackground(BuildContext context) {
    return isDark(context) ? darkSidebarActive : lightSidebarActive;
  }

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: lightTextPrimary,
      secondary: lightSecondary,
      onSecondary: lightTextPrimary,
      error: chartRed,
      onError: Colors.white,
      surface: lightBackgroundMain,
      onSurface: lightTextPrimary,
      tertiary: chartBlue,
      onTertiary: Colors.white,
      outline: lightBorder,
      outlineVariant: lightBorder,
      shadow: Color(0x14000000),
      scrim: Color(0x14000000),
      inverseSurface: darkBackgroundMain,
      onInverseSurface: darkTextPrimary,
      inversePrimary: darkPrimary,
      surfaceTint: lightPrimary,
    ).copyWith(
      surfaceContainerHighest: lightFilledSurface,
      surfaceContainerHigh: lightFilledSurface,
      surfaceContainer: lightFilledSurface,
      surfaceContainerLow: lightBackgroundMain,
      surfaceContainerLowest: lightBackgroundMain,
      primaryContainer: lightFilledSurface,
      onPrimaryContainer: lightTextPrimary,
      secondaryContainer: lightFilledSurface,
      onSecondaryContainer: lightTextPrimary,
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: darkTextPrimary,
      secondary: darkSecondary,
      onSecondary: darkTextPrimary,
      error: chartRed,
      onError: Colors.white,
      surface: darkBackgroundMain,
      onSurface: darkTextPrimary,
      tertiary: chartBlue,
      onTertiary: Colors.white,
      outline: darkBorder,
      outlineVariant: darkBorder,
      shadow: Color(0x1A000000),
      scrim: Color(0x1A000000),
      inverseSurface: lightBackgroundMain,
      onInverseSurface: lightTextPrimary,
      inversePrimary: lightPrimary,
      surfaceTint: darkPrimary,
    ).copyWith(
      surfaceContainerHighest: darkFilledSurface,
      surfaceContainerHigh: darkFilledSurface,
      surfaceContainer: darkFilledSurface,
      surfaceContainerLow: darkBackgroundMain,
      surfaceContainerLowest: darkBackgroundMain,
      primaryContainer: darkFilledSurface,
      onPrimaryContainer: darkTextPrimary,
      secondaryContainer: darkFilledSurface,
      onSecondaryContainer: darkTextPrimary,
    );
  }
}
