import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ui/tokens/focuslane_semantic_tokens.dart';
import '../ui/tokens/focuslane_tokens.dart';

enum ThemePreset { ocean, forest, sunset, orchid, tealCarbon, graphite }

class AppTheme {
  static ThemeData lightTheme = _buildLight(ThemePreset.ocean);
  static ThemeData darkTheme = _buildDark(ThemePreset.ocean);

  static List<ThemePreset> get presets => ThemePreset.values;

  static String presetLabel(ThemePreset p) {
    switch (p) {
      case ThemePreset.ocean:
        return 'Ocean';
      case ThemePreset.forest:
        return 'Forest';
      case ThemePreset.sunset:
        return 'Sunset';
      case ThemePreset.orchid:
        return 'Orchid';
      case ThemePreset.tealCarbon:
        return 'TealCarbon';
      case ThemePreset.graphite:
        return 'Graphite';
    }
  }

  static ThemeData getLight(ThemePreset p) => _buildLight(p);
  static ThemeData getDark(ThemePreset p) => _buildDark(p);

  static ThemeData _buildLight(ThemePreset p) {
    assert(p.index >= 0);
    final scheme = FocuslaneSemanticTokens.lightScheme();
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return _buildBase(
      brightness: Brightness.light,
      scheme: scheme,
      textTheme: textTheme,
    );
  }

  static ThemeData _buildDark(ThemePreset p) {
    assert(p.index >= 0);
    final scheme = FocuslaneSemanticTokens.darkScheme();
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    return _buildBase(
      brightness: Brightness.dark,
      scheme: scheme,
      textTheme: textTheme,
    );
  }

  static ThemeData _buildBase({
    required Brightness brightness,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(0, 44),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(
            color: FocuslaneTokens.borderColorFromScheme(scheme),
            width: FocuslaneTokens.borderW,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(
            color: FocuslaneTokens.borderColorFromScheme(scheme),
            width: FocuslaneTokens.borderW,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius8),
          borderSide: BorderSide(
            color: scheme.primary,
            width: FocuslaneTokens.borderW,
          ),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius12),
          side: BorderSide(
            color: FocuslaneTokens.borderColorFromScheme(scheme),
            width: FocuslaneTokens.borderW,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        backgroundColor: scheme.surfaceContainerLow,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
        thickness: FocuslaneTokens.dividerW,
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
