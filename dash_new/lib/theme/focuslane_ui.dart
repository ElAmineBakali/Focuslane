import 'package:flutter/material.dart';

class FocuslaneUI {
  static const double borderW = 2.0;
  static const double dividerW = 1.2;
  static const double radius = 16;
  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(16);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12);

  static bool isDark(BuildContext c) {
    return Theme.of(c).brightness == Brightness.dark;
  }

  static Color borderColor(BuildContext c) {
    // Bordes bien visibles: blanco puro en dark, gris en light
    return isDark(c) ? Colors.white : Colors.grey.shade400;
  }

  static Color dividerColor(BuildContext c) {
    return Theme.of(c)
        .dividerColor
        .withOpacity(isDark(c) ? 0.55 : 0.35);
  }

  static const Color pastelTeal = Color(0xFF7FBEB7);
  static const Color pastelTealClaro = Color(0xFF9FD0CB);
  static const Color pastelTealSuavizado = Color(0xFF6CA9A1);
  static const Color pastelTealClaroSuavizado = Color(0xFF86BEB8);

  static Color accent(BuildContext c) {
    return isDark(c) ? pastelTealSuavizado : pastelTeal;
  }

  static Color accent2(BuildContext c) {
    return isDark(c) ? pastelTealClaroSuavizado : pastelTealClaro;
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
}
