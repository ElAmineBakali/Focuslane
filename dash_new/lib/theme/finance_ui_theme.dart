import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño compartido para el módulo de Finanzas
/// Inspirado en Gym module para consistencia visual
class FinanceUI {
  FinanceUI._();

  // Colores específicos de finanzas
  static const Color income = Color(0xFF4CAF50);
  static const Color expense = Color(0xFFFF5252);
  static const Color neutral = Color(0xFF9E9E9E);
  static const Color warning = Color(0xFFFFA726);
  static const Color critical = Color(0xFFEF5350);

  /// Header estilo Gym con gradiente
  static SliverAppBar sliverAppBar(
    BuildContext context, {
    required String title,
    List<Widget>? actions,
    double expandedHeight = 200,
    IconData? backgroundIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar.large(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primaryContainer,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              if (backgroundIcon != null)
                Positioned(
                  right: -20,
                  top: 40,
                  child: Icon(
                    backgroundIcon,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: actions,
    );
  }

  /// Card con gradiente
  static Widget gradientCard({
    required BuildContext context,
    required Widget child,
    VoidCallback? onTap,
    List<Color>? gradientColors,
    EdgeInsetsGeometry? padding,
    double borderRadius = 20,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = gradientColors ??
        [colorScheme.primaryContainer, colorScheme.secondaryContainer];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Card de estadística/KPI
  static Widget statCard({
    required BuildContext context,
    required String label,
    required String value,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 20),
                ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Card de acción con icono
  static Widget actionCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  /// Título de sección
  static Widget sectionTitle(
    BuildContext context,
    String title, {
    String? subtitle,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Empty state
  static Widget emptyState(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(
                  actionText,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Modal styled card for bottom sheets/dialogs
  static Widget modalCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary.withOpacity(0.15),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Barra de progreso estilizada
  static Widget progressBar({
    required BuildContext context,
    required double progress,
    Color? color,
    Color? backgroundColor,
    double height = 8,
    bool showPercentage = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;
    final effectiveBackgroundColor = backgroundColor ?? colorScheme.surfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: effectiveBackgroundColor,
            valueColor: AlwaysStoppedAnimation(effectiveColor),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: effectiveColor,
            ),
          ),
        ],
      ],
    );
  }

  /// Indicador de monto (positivo/negativo)
  static Widget amountIndicator({
    required double amount,
    String currency = '€',
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    bool showSign = true,
  }) {
    final isPositive = amount >= 0;
    final color = isPositive ? income : expense;
    final sign = isPositive ? '+' : '-';

    return Text(
      '${showSign ? sign : ''}${amount.abs().toStringAsFixed(2)}$currency',
      style: GoogleFonts.poppins(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

/// Theme wrapper para formularios
class FinanceFormTheme extends StatelessWidget {
  final Widget child;
  const FinanceFormTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final cs = base.colorScheme;
    final input = base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.2),
      ),
      labelStyle: base.textTheme.bodySmall,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );

    final btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    return Theme(
      data: base.copyWith(
        inputDecorationTheme: input,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: btnShape,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: btnShape,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: btnShape,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: child,
    );
  }
}

EdgeInsets financeBodyPadding(BuildContext context) {
  final bottom = MediaQuery.of(context).viewPadding.bottom;
  return EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom);
}

double financeScreenPad(BuildContext context) {
  return MediaQuery.of(context).viewPadding.bottom + 80;
}

class FinanceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const FinanceCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: child,
      ),
    );
  }
}

class FinanceKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const FinanceKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: FinanceCard(
        child: ListTile(
          leading: Icon(icon),
          title: Center(child: Text(title)),
          subtitle: Center(child: Text(value)),
        ),
      ),
    );
  }
}

class FinanceSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const FinanceSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleLarge),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitle!, style: t.bodySmall),
          ),
      ],
    );
  }
}

/// Large finance header with gradient background and icon.
class FinanceHeaderLarge extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;
  const FinanceHeaderLarge({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return SliverAppBar.large(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: cs.primaryContainer,
      actions: actions,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                top: 36,
                child: Icon(
                  icon,
                  size: 120,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern floating action with extended label
class FinanceFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  const FinanceFab({
    super.key,
    required this.onPressed,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      icon: Icon(icon),
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Styled chips used for filters and tags
class FinanceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  const FinanceChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = color ?? cs.primary;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      selected: selected,
      onSelected: (_) => onTap?.call(),
      selectedColor: base.withOpacity(0.18),
      backgroundColor: cs.surfaceVariant.withOpacity(0.4),
      labelStyle: TextStyle(color: selected ? base : cs.onSurfaceVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

/// Helper for section padding and grid spacing
class FinanceGaps {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
}

/// Screen scaffold wrapper to provide consistent padding and background
class FinanceScreenBody extends StatelessWidget {
  final List<Widget> slivers;
  const FinanceScreenBody({super.key, required this.slivers});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: slivers);
  }
}
