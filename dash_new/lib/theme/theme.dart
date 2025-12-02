import 'package:flutter/material.dart';

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

  static Color _seed(ThemePreset p) {
    switch (p) {
      case ThemePreset.ocean:
        return const Color(0xFF2563EB);
      case ThemePreset.forest:
        return const Color(0xFF2E7D32);
      case ThemePreset.sunset:
        return const Color(0xFFF97316);
      case ThemePreset.orchid:
        return const Color(0xFF7C3AED);
      case ThemePreset.tealCarbon:
        return const Color(0xFF0EA5A4);
      case ThemePreset.graphite:
        return const Color(0xFF3F3F46);
    }
  }

  static ThemeData _buildLight(ThemePreset p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed(p),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
    );
  }

  static ThemeData _buildDark(ThemePreset p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed(p),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSecondaryContainer),
      ),
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
    );
  }
}
