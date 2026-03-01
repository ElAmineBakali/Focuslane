import 'package:flutter/material.dart';
import '../ui/tokens/focuslane_tokens.dart';

class FocuslaneUI {
  static const double borderW = FocuslaneTokens.borderW;
  static const double dividerW = FocuslaneTokens.dividerW;
  static const double radius = FocuslaneTokens.radius16;
  static const EdgeInsets pagePaddingCompact =
      FocuslaneTokens.pagePaddingCompact;
  static const EdgeInsets cardPaddingCompact =
      FocuslaneTokens.cardPaddingCompact;

  static bool isDark(BuildContext c) => FocuslaneTokens.isDark(c);
  static Color borderColor(BuildContext c) => FocuslaneTokens.borderColor(c);
  static Color dividerColor(BuildContext c) => FocuslaneTokens.dividerColor(c);

  static const Color pastelTeal = FocuslaneTokens.pastelTeal;
  static const Color pastelTealClaro = FocuslaneTokens.pastelTealClaro;
  static const Color pastelTealSuavizado = FocuslaneTokens.pastelTealSuavizado;
  static const Color pastelTealClaroSuavizado =
      FocuslaneTokens.pastelTealClaroSuavizado;

  static Color accent(BuildContext c) => FocuslaneTokens.accent(c);
  static Color accent2(BuildContext c) => FocuslaneTokens.accent2(c);

  static LinearGradient primaryGradient(BuildContext c) =>
      FocuslaneTokens.primaryGradient(c);

  static Color accentSurface(BuildContext c, {double opacity = 0.14}) =>
      FocuslaneTokens.accentSurface(c, opacity: opacity);
}

