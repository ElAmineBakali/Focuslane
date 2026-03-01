import 'package:flutter/material.dart';

/// Tema específico del módulo Food con paleta pastel profesional
/// Paleta: Tonos suaves tipo SaaS moderno
class FoodTheme {
  // Paleta principal - Tonos pastel elegantes
  static const Color beigeSoft = Color(0xFFD7CDC2); // Beige suave
  static const Color taupe = Color(0xFFB5A89B); // Taupe
  static const Color tealSoft = Color(0xFF80AAA6); // Teal suave
  static const Color tealLight = Color(0xFFA0BFBD); // Teal claro
  static const Color tealDark = Color(0xFF5A8A86); // Teal oscuro
  static const Color paleGrey = Color(0xFFF5F5F5); // Gris pálido
  static const Color backgroundLight = Color(0xFFD2E2E0); // Fondo claro
  static const Color backgroundVeryLight = Color(0xFFE5EDEF); // Gris muy claro

  // Versiones oscuras para dark mode
  static const Color darkBase = Color(0xFF1A1D1E);
  static const Color darkSurface = Color(0xFF242729);
  static const Color darkCard = Color(0xFF2D3133);
  static const Color darkBorder = Color(0xFF3A3E41);

  // Acentos suavizados para dark mode
  static Color tealSoftDark = const Color(0xFF80AAA6).withOpacity(0.7);
  static Color tealLightDark = const Color(0xFFA0BFBD).withOpacity(0.7);

  // Gradientes principales
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      tealSoft,
      tealLight,
    ],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      beigeSoft,
      taupe,
    ],
  );

  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundLight,
      backgroundVeryLight,
    ],
  );

  // Colores semánticos (versión pastel)
  static const Color success = Color(0xFF88C999); // Verde suave
  static const Color warning = Color(0xFFE8C68E); // Amarillo suave
  static const Color error = Color(0xFFD89A9A); // Rojo suave
  static const Color info = Color(0xFF8FA8BC); // Azul suave

  // Sistema de espaciado consistente
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing30 = 30.0;
  static const double spacing40 = 40.0;

  // Bordes redondeados profesionales
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;

  // Sombras sutiles
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> cardShadowHover(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.4)
            : Colors.black.withOpacity(0.12),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];
  }

  // Colores de fondo según tema
  static Color getCardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkCard : Theme.of(context).colorScheme.surface;
  }

  static Color getSurfaceBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : backgroundVeryLight;
  }

  static Color getScaffoldBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBase : backgroundVeryLight;
  }

  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBorder : beigeSoft.withOpacity(0.3);
  }

  // Colores de texto según tema
  static Color getTextPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.95) : const Color(0xFF2D3436);
  }

  static Color getTextSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.65) : const Color(0xFF636E72);
  }

  static Color getTextTertiary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white.withOpacity(0.45) : const Color(0xFF95A5A6);
  }

  // Colores de acción
  static Color getPrimaryAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? tealLightDark : tealSoft;
  }

  static Color getSecondaryAccent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? tealSoftDark : tealLight;
  }
}

/// Tipografía del módulo Food (consistente con Focuslane)
class FoodTypography {
  static TextStyle display(BuildContext context) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle heading1(BuildContext context) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.3,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle heading2(BuildContext context) {
    return TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.2,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle heading3(BuildContext context) {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.4,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle heading4(BuildContext context) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle body(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: FoodTheme.getTextSecondary(context),
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: FoodTheme.getTextTertiary(context),
    );
  }

  static TextStyle labelLarge(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: 0.1,
      color: FoodTheme.getTextPrimary(context),
    );
  }

  static TextStyle labelSmall(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.2,
      color: FoodTheme.getTextSecondary(context),
    );
  }
}
