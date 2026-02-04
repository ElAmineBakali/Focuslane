import 'package:flutter/material.dart';

class FocuslaneTokens {
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;

  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;

  static const double borderW = 1.6;
  static const double dividerW = 1.2;

  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(spacing16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spacing12);

  static const Color pastelTeal = Color(0xFF7FBEB7);
  static const Color pastelTealClaro = Color(0xFF9FD0CB);
  static const Color pastelTealSuavizado = Color(0xFF6CA9A1);
  static const Color pastelTealClaroSuavizado = Color(0xFF86BEB8);

  static bool isDark(BuildContext c) {
    return Theme.of(c).brightness == Brightness.dark;
  }

  static Color accent(BuildContext c) {
    return isDark(c) ? pastelTealSuavizado : pastelTeal;
  }

  static Color accent2(BuildContext c) {
    return isDark(c) ? pastelTealClaroSuavizado : pastelTealClaro;
  }

  static Color borderColor(BuildContext c) {
    return isDark(c) ? Colors.grey.shade600 : Colors.grey.shade400;
  }

  static Color borderColorFromScheme(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? Colors.grey.shade600
        : Colors.grey.shade400;
  }

  static Color dividerColor(BuildContext c) {
    return Theme.of(c)
        .dividerColor
        .withOpacity(isDark(c) ? 0.55 : 0.35);
  }

  static Color surfaceColor(BuildContext c) {
    return Theme.of(c).colorScheme.surface;
  }

  static Color mutedTextColor(BuildContext c) {
    return Theme.of(c).colorScheme.onSurfaceVariant;
  }

  static LinearGradient primaryGradient(BuildContext c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accent(c).withOpacity(0.9),
        accent2(c).withOpacity(0.8),
      ],
    );
  }

  static Color accentSurface(BuildContext c, {double opacity = 0.14}) {
    return accent(c).withOpacity(opacity);
  }

  static List<BoxShadow> cardShadow(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return [
      BoxShadow(
        color: cs.shadow.withOpacity(isDark(c) ? 0.2 : 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
