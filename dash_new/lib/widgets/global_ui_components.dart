import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FocusColors {
  static const Color gym = Color(0xFF2196F3);
  static const Color food = Color(0xFFFF9800);
  static const Color study = Color(0xFF9C27B0);
  static const Color habits = Color(0xFF4CAF50);
  static const Color goals = Color(0xFFE91E63);
  static const Color calendar = Color(0xFF00BCD4);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static Color grey50 = Colors.grey[50]!;
  static Color grey100 = Colors.grey[100]!;
  static Color grey200 = Colors.grey[200]!;
  static Color grey300 = Colors.grey[300]!;
  static Color grey600 = Colors.grey[600]!;
  static Color grey700 = Colors.grey[700]!;
  static Color grey800 = Colors.grey[800]!;

  static LinearGradient createGradient(Color color) {
    return LinearGradient(
      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient appBarGradient(Color primary, Color secondary) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primary, secondary.withOpacity(0.8)],
    );
  }
}

class FocusTypography {
  static TextStyle heading1(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w700);

  static TextStyle heading2(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700);

  static TextStyle heading3(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700);

  static TextStyle heading4(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600);

  static TextStyle bodyLarge(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w400);

  static TextStyle bodyMedium(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle bodySmall(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400);

  static TextStyle caption(BuildContext context) => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: Colors.grey[600],
  );

  static TextStyle label(BuildContext context) =>
      GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle valueDisplay(Color color) => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

class FocusSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  static const double cardElevation = 1.0;
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 40.0;
}

class FocusKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FocusKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: FocusColors.createGradient(color),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(FocusSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: FocusSpacing.md),
                Text(value, style: FocusTypography.valueDisplay(color)),
                Text(label, style: FocusTypography.caption(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FocusStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const FocusStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(FocusSpacing.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: FocusSpacing.iconSizeMedium),
                  const Spacer(),
                  Text(value, style: FocusTypography.valueDisplay(color)),
                ],
              ),
              const SizedBox(height: FocusSpacing.sm),
              Text(
                label,
                style: FocusTypography.label(
                  context,
                ).copyWith(color: FocusColors.grey700),
              ),
              Text(subtitle, style: FocusTypography.caption(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Duration? animationDelay;

  const FocusActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(FocusSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: FocusSpacing.iconSizeLarge, color: color),
                const SizedBox(height: FocusSpacing.md),
                Text(
                  title,
                  style: FocusTypography.heading4(
                    context,
                  ).copyWith(color: color),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (animationDelay != null) {
      return widget
          .animate(delay: animationDelay)
          .fadeIn(duration: 400.ms)
          .scale();
    }
    return widget;
  }
}

class FocusActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Duration? animationDelay;

  const FocusActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.animationDelay,
  });
}

class FocusActionsGrid extends StatelessWidget {
  final List<FocusActionItem> items;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const FocusActionsGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = FocusSpacing.md,
    this.crossAxisSpacing = FocusSpacing.md,
    this.childAspectRatio = 1.3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: [
        for (final item in items)
          FocusActionCard(
            title: item.title,
            icon: item.icon,
            color: item.color,
            onTap: item.onTap,
            animationDelay: item.animationDelay,
          ),
      ],
    );
  }
}

class FocusFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const FocusFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: FocusSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(FocusSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(FocusSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: FocusSpacing.iconSizeMedium + 4,
                ),
              ),
              const SizedBox(width: FocusSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: FocusTypography.heading4(context)),
                    const SizedBox(height: FocusSpacing.xs),
                    Text(subtitle, style: FocusTypography.caption(context)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: FocusColors.grey600),
            ],
          ),
        ),
      ),
    );
  }
}

class FocusInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final ColorScheme? colorScheme;

  const FocusInfoChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme ?? Theme.of(context).colorScheme;
    final chipColor = color ?? cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FocusSpacing.sm,
        vertical: FocusSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: FocusSpacing.xs),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: chipColor),
          ),
        ],
      ),
    );
  }
}

class FocusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const FocusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FocusSpacing.sm,
        vertical: FocusSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: FocusSpacing.xs),
          ],
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class FocusProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final bool showPercentage;
  final String? suffix;

  const FocusProgressBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.showPercentage = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = max > 0 ? (value / max * 100).clamp(0, 100).toInt() : 0;
    final progress = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: FocusSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: FocusTypography.heading4(context)),
              if (showPercentage)
                Text(
                  suffix != null
                      ? '${value.toStringAsFixed(0)}/${max.toStringAsFixed(0)} $suffix'
                      : '$percentage%',
                  style: FocusTypography.caption(context),
                ),
            ],
          ),
          const SizedBox(height: FocusSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.2, end: 0);
  }
}

class FocusGradientAppBar extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Widget>? actions;
  final Widget? bottom;
  final double expandedHeight;

  const FocusGradientAppBar({
    super.key,
    required this.title,
    this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.actions,
    this.bottom,
    this.expandedHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      backgroundColor: primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: FocusSpacing.lg,
          bottom: bottom != null ? 60 : FocusSpacing.lg,
        ),
        title: Text(title, style: FocusTypography.heading1(context)),
        background: Container(
          decoration: BoxDecoration(
            gradient: FocusColors.appBarGradient(primaryColor, secondaryColor),
          ),
          child: SafeArea(
            child: Center(
              child:
                  icon != null
                      ? Icon(
                        icon,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      )
                      : null,
            ),
          ),
        ),
      ),
      actions: actions,
      bottom: bottom as PreferredSizeWidget?,
    );
  }
}

class FocusListCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;
  final List<Widget>? additionalInfo;

  const FocusListCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
    this.additionalInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: FocusSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FocusSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(FocusSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(FocusSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        FocusSpacing.radiusSm,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: FocusSpacing.iconSizeSmall,
                    ),
                  ),
                  const SizedBox(width: FocusSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: FocusTypography.heading4(context)),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: FocusTypography.caption(context),
                          ),
                      ],
                    ),
                  ),
                  trailing ??
                      const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              if (additionalInfo != null) ...[
                const SizedBox(height: FocusSpacing.md),
                Wrap(
                  spacing: FocusSpacing.sm,
                  runSpacing: FocusSpacing.sm,
                  children: additionalInfo!,
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.2, end: 0);
  }
}

class FocusEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  const FocusEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(FocusSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color.withOpacity(0.3)),
            const SizedBox(height: FocusSpacing.lg),
            Text(
              message,
              style: FocusTypography.bodyMedium(
                context,
              ).copyWith(color: FocusColors.grey600),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: FocusSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().scale();
  }
}

class FocusMeterCard extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final Color color;
  final IconData? icon;

  const FocusMeterCard({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(FocusSpacing.lg),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(FocusSpacing.radiusLg),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: FocusSpacing.iconSizeSmall),
                    const SizedBox(width: FocusSpacing.sm),
                  ],
                  Text(label, style: FocusTypography.heading4(context)),
                ],
              ),
              Text(
                '${value.toStringAsFixed(1)}/$max',
                style: FocusTypography.valueDisplay(
                  color,
                ).copyWith(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: FocusSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(FocusSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: FocusColors.grey300,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

class FocusSection extends StatelessWidget {
  final String title;
  final Widget? action;
  final List<Widget> children;

  const FocusSection({
    super.key,
    required this.title,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: FocusTypography.heading3(context)),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: FocusSpacing.md),
        ...children,
      ],
    );
  }
}

double screenPad(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 600) return 80.0;
  return 0.0;
}

PageRouteBuilder<T> focusPageRoute<T>({
  required Widget page,
  bool useHero = false,
}) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
