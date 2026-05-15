import 'package:flutter/material.dart';

class FocuslaneSemanticTokens {
  static const Color darkBackgroundMain = Color(0xFF101415);
  static const Color darkCardBackground = Color(0xFF151A1B);
  static const Color darkSurfaceContainerLow = Color(0xFF182021);
  static const Color darkSurfaceContainer = Color(0xFF1F292A);
  static const Color darkSurfaceContainerHigh = Color(0xFF283334);
  static const Color darkFilledSurface = Color(0xFF313D3E);
  static const Color darkBorder = Color(0xFF465452);
  static const Color darkOutline = Color(0xFF8A9391);
  static const Color darkPrimary = Color(0xFFA4CFCA);
  static const Color darkPrimaryContainer = Color(0xFF244D4A);
  static const Color darkSecondary = Color(0xFFADCDCB);
  static const Color darkSecondaryContainer = Color(0xFF2F4C4A);
  static const Color darkTertiary = Color(0xFFD2C4B7);
  static const Color darkTertiaryContainer = Color(0xFF4F453B);
  static const Color darkTextPrimary = Color(0xFFEAF2F4);
  static const Color darkTextSecondary = Color(0xFFC0C8C6);
  static const Color darkSidebarActive = Color(0x29244D4A);

  static const Color lightBackgroundMain = Color(0xFFF3FBFD);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainerLow = Color(0xFFEDF5F7);
  static const Color lightSurfaceContainer = Color(0xFFE7EFF1);
  static const Color lightSurfaceContainerHigh = Color(0xFFE2EAEC);
  static const Color lightFilledSurface = Color(0xFFDCE4E6);
  static const Color lightBorder = Color(0xFFC0C8C6);
  static const Color lightOutline = Color(0xFF717977);
  static const Color lightPrimary = Color(0xFF3D6562);
  static const Color lightPrimaryContainer = Color(0xFF80AAA6);
  static const Color lightSecondary = Color(0xFF476462);
  static const Color lightSecondaryContainer = Color(0xFFC9E9E7);
  static const Color lightTertiary = Color(0xFF675D52);
  static const Color lightTertiaryContainer = Color(0xFFEFE0D2);
  static const Color lightTextPrimary = Color(0xFF151D1F);
  static const Color lightTextSecondary = Color(0xFF404847);
  static const Color lightSidebarActive = Color(0x1F3D6562);

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

  static Color surfaceContainerLow(BuildContext context) {
    return isDark(context) ? darkSurfaceContainerLow : lightSurfaceContainerLow;
  }

  static Color surfaceContainer(BuildContext context) {
    return isDark(context) ? darkSurfaceContainer : lightSurfaceContainer;
  }

  static Color surfaceContainerHigh(BuildContext context) {
    return isDark(context)
        ? darkSurfaceContainerHigh
        : lightSurfaceContainerHigh;
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

  static Color primaryContainer(BuildContext context) {
    return isDark(context) ? darkPrimaryContainer : lightPrimaryContainer;
  }

  static Color secondary(BuildContext context) {
    return isDark(context) ? darkSecondary : lightSecondary;
  }

  static Color secondaryContainer(BuildContext context) {
    return isDark(context) ? darkSecondaryContainer : lightSecondaryContainer;
  }

  static Color tertiary(BuildContext context) {
    return isDark(context) ? darkTertiary : lightTertiary;
  }

  static Color tertiaryContainer(BuildContext context) {
    return isDark(context) ? darkTertiaryContainer : lightTertiaryContainer;
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
      onPrimary: Colors.white,
      secondary: lightSecondary,
      onSecondary: Colors.white,
      error: chartRed,
      onError: Colors.white,
      surface: lightBackgroundMain,
      onSurface: lightTextPrimary,
      tertiary: lightTertiary,
      onTertiary: Colors.white,
      outline: lightOutline,
      outlineVariant: lightBorder,
      shadow: Color(0x14000000),
      scrim: Color(0x14000000),
      inverseSurface: darkBackgroundMain,
      onInverseSurface: darkTextPrimary,
      inversePrimary: darkPrimary,
      surfaceTint: lightPrimary,
    ).copyWith(
      surfaceContainerHighest: lightFilledSurface,
      surfaceContainerHigh: lightSurfaceContainerHigh,
      surfaceContainer: lightSurfaceContainer,
      surfaceContainerLow: lightSurfaceContainerLow,
      surfaceContainerLowest: lightCardBackground,
      primaryContainer: lightPrimaryContainer,
      onPrimaryContainer: const Color(0xFF143F3C),
      secondaryContainer: lightSecondaryContainer,
      onSecondaryContainer: const Color(0xFF01201F),
      tertiaryContainer: lightTertiaryContainer,
      onTertiaryContainer: const Color(0xFF40372D),
      onSurfaceVariant: lightTextSecondary,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF93000A),
    );
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: darkPrimary,
      onPrimary: Color(0xFF073734),
      secondary: darkSecondary,
      onSecondary: Color(0xFF173735),
      error: chartRed,
      onError: Colors.white,
      surface: darkBackgroundMain,
      onSurface: darkTextPrimary,
      tertiary: darkTertiary,
      onTertiary: Color(0xFF382C22),
      outline: darkOutline,
      outlineVariant: darkBorder,
      shadow: Color(0x1A000000),
      scrim: Color(0x1A000000),
      inverseSurface: lightBackgroundMain,
      onInverseSurface: lightTextPrimary,
      inversePrimary: lightPrimary,
      surfaceTint: darkPrimary,
    ).copyWith(
      surfaceContainerHighest: darkFilledSurface,
      surfaceContainerHigh: darkSurfaceContainerHigh,
      surfaceContainer: darkSurfaceContainer,
      surfaceContainerLow: darkSurfaceContainerLow,
      surfaceContainerLowest: darkCardBackground,
      primaryContainer: darkPrimaryContainer,
      onPrimaryContainer: const Color(0xFFBFEBE6),
      secondaryContainer: darkSecondaryContainer,
      onSecondaryContainer: const Color(0xFFC9E9E7),
      tertiaryContainer: darkTertiaryContainer,
      onTertiaryContainer: const Color(0xFFEFE0D2),
      onSurfaceVariant: darkTextSecondary,
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
    );
  }
}
