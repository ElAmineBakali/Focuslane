import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'focuslane_semantic_tokens.dart';

class FocuslaneTokens {
  static const double sidebarWidth = 260.0;
  static const double topBarHeight = 64.0;
  static const double containerMaxWidth = 1440.0;

  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;

  static const double borderW = 1.0;
  static const double dividerW = 1.0;

  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(spacing16);
  static const EdgeInsets pagePadding = EdgeInsets.all(spacing24);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(spacing16);
  static const EdgeInsets cardPadding = EdgeInsets.all(spacing24);

  static const Color pastelTeal = Color(0xFF7FBEB7);
  static const Color pastelTealClaro = Color(0xFF9FD0CB);
  static const Color pastelTealSuavizado = Color(0xFF6CA9A1);
  static const Color pastelTealClaroSuavizado = Color(0xFF86BEB8);

  static bool isDark(BuildContext c) {
    return Theme.of(c).brightness == Brightness.dark;
  }

  static Color accent(BuildContext c) {
    return FocuslaneSemanticTokens.primary(c);
  }

  static Color accent2(BuildContext c) {
    return FocuslaneSemanticTokens.secondary(c);
  }

  static Color borderColor(BuildContext c) {
    return FocuslaneSemanticTokens.border(c);
  }

  static Color borderColorFromScheme(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? FocuslaneSemanticTokens.darkBorder
        : FocuslaneSemanticTokens.lightBorder;
  }

  static Color dividerColor(BuildContext c) {
    return Theme.of(c).dividerColor.withValues(alpha: isDark(c) ? 0.55 : 0.35);
  }

  static Color surfaceColor(BuildContext c) {
    return Theme.of(c).colorScheme.surfaceContainerLowest;
  }

  static Color surfaceLow(BuildContext c) {
    return Theme.of(c).colorScheme.surfaceContainerLow;
  }

  static Color surfaceContainer(BuildContext c) {
    return Theme.of(c).colorScheme.surfaceContainer;
  }

  static Color surfaceHigh(BuildContext c) {
    return Theme.of(c).colorScheme.surfaceContainerHigh;
  }

  static Color mutedTextColor(BuildContext c) {
    return FocuslaneSemanticTokens.textSecondary(c);
  }

  static LinearGradient primaryGradient(BuildContext c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent(c), FocuslaneSemanticTokens.secondary(c)],
    );
  }

  static Color accentSurface(BuildContext c, {double opacity = 0.14}) {
    return accent(c).withValues(alpha: opacity);
  }

  static List<BoxShadow> cardShadow(BuildContext c) {
    final dark = isDark(c);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.28 : 0.06),
        blurRadius: dark ? 22 : 18,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.12 : 0.03),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static List<BoxShadow> subtleShadow(BuildContext c) {
    final dark = isDark(c);
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.20 : 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

class FocusColors {
  static const Color food = Color(0xFFFF6B35);
  static const Color gym = Color(0xFF6C63FF);
  static const Color study = Color(0xFF4CAF50);
  static const Color finance = Color(0xFF2196F3);
  static const Color mindfulness = Color(0xFF9C27B0);
  static const Color habits = Color(0xFFFF9800);
  static const Color goals = Color(0xFFE91E63);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  static const Color textPrimary = grey900;
  static const Color textSecondary = grey600;
  static const Color borderLight = grey300;

  static LinearGradient createGradient(Color color) {
    return LinearGradient(
      colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient appBarGradient(Color primary, Color secondary) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary.withValues(alpha: 0.8)],
    );
  }
}

class FocusSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 9999;

  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 40.0;
}

class FocusTypography {
  static TextStyle heading1(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: color ?? (isDark ? Colors.white : FocusColors.grey900),
      height: 1.2,
    );
  }

  static TextStyle heading2(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: color ?? (isDark ? Colors.white : FocusColors.grey900),
      height: 1.3,
    );
  }

  static TextStyle heading3(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: color ?? (isDark ? Colors.white : FocusColors.grey900),
      height: 1.4,
    );
  }

  static TextStyle heading4(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: color ?? (isDark ? Colors.white : FocusColors.grey900),
      height: 1.5,
    );
  }

  static TextStyle body(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? FocusColors.grey200 : FocusColors.grey800),
      height: 1.5,
    );
  }

  static TextStyle bodySmall(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? FocusColors.grey300 : FocusColors.grey700),
      height: 1.4,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: color ?? (isDark ? FocusColors.grey400 : FocusColors.grey600),
      height: 1.3,
    );
  }

  static TextStyle label(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? (isDark ? Colors.white : FocusColors.grey900),
      height: 1.4,
    );
  }

  static TextStyle button(BuildContext context, {Color? color}) {
    return GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: color ?? Colors.white,
      letterSpacing: 0.5,
    );
  }
}

class AppColors {
  static const Color food = FocusColors.food;
  static const Color gym = FocusColors.gym;
  static const Color study = FocusColors.study;
  static const Color finance = FocusColors.finance;
  static const Color mindfulness = FocusColors.mindfulness;
  static const Color habits = FocusColors.habits;
  static const Color goals = FocusColors.goals;
  static const Color success = FocusColors.success;
  static const Color warning = FocusColors.warning;
  static const Color error = FocusColors.error;
  static const Color info = FocusColors.info;
  static const Color grey50 = FocusColors.grey50;
  static const Color grey100 = FocusColors.grey100;
  static const Color grey200 = FocusColors.grey200;
  static const Color grey300 = FocusColors.grey300;
  static const Color grey400 = FocusColors.grey400;
  static const Color grey500 = FocusColors.grey500;
  static const Color grey600 = FocusColors.grey600;
  static const Color grey700 = FocusColors.grey700;
  static const Color grey800 = FocusColors.grey800;
  static const Color grey900 = FocusColors.grey900;
  static const Color textPrimary = FocusColors.textPrimary;
  static const Color textSecondary = FocusColors.textSecondary;
  static const Color borderLight = FocusColors.borderLight;
}

class AppSpacing {
  static const double xs = FocusSpacing.xs;
  static const double sm = FocusSpacing.sm;
  static const double md = FocusSpacing.md;
  static const double lg = FocusSpacing.lg;
  static const double xl = FocusSpacing.xl;
  static const double xxl = FocusSpacing.xxl;
  static const double xxxl = FocusSpacing.xxxl;

  static const double radiusXs = FocusSpacing.radiusXs;
  static const double radiusSm = FocusSpacing.radiusSm;
  static const double radiusMd = FocusSpacing.radiusMd;
  static const double radiusLg = FocusSpacing.radiusLg;
  static const double radiusXl = FocusSpacing.radiusXl;
  static const double radiusXxl = FocusSpacing.radiusXxl;
  static const double radiusFull = FocusSpacing.radiusFull;

  static const double elevationSm = FocusSpacing.elevationSm;
  static const double elevationMd = FocusSpacing.elevationMd;
  static const double elevationLg = FocusSpacing.elevationLg;
  static const double elevationXl = FocusSpacing.elevationXl;
}

class AppTypography {
  static TextStyle heading1(BuildContext context, {Color? color}) =>
      FocusTypography.heading1(context, color: color);
  static TextStyle heading2(BuildContext context, {Color? color}) =>
      FocusTypography.heading2(context, color: color);
  static TextStyle heading3(BuildContext context, {Color? color}) =>
      FocusTypography.heading3(context, color: color);
  static TextStyle heading4(BuildContext context, {Color? color}) =>
      FocusTypography.heading4(context, color: color);
  static TextStyle body(BuildContext context, {Color? color}) =>
      FocusTypography.body(context, color: color);
  static TextStyle bodySmall(BuildContext context, {Color? color}) =>
      FocusTypography.bodySmall(context, color: color);
  static TextStyle caption(BuildContext context, {Color? color}) =>
      FocusTypography.caption(context, color: color);
  static TextStyle label(BuildContext context, {Color? color}) =>
      FocusTypography.label(context, color: color);
  static TextStyle button(BuildContext context, {Color? color}) =>
      FocusTypography.button(context, color: color);
}

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
