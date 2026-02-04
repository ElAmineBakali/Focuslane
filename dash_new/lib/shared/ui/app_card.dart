import 'package:flutter/material.dart';
import '../../theme/focuslane_ui.dart';

class AppCardStyle {
  static double radius = FocuslaneUI.radius;
  static double borderWidth = FocuslaneUI.borderW;

  static BorderSide borderSide(BuildContext context) {
    final color = FocuslaneUI.borderColor(context);
    return BorderSide(color: color, width: borderWidth);
  }

  static BorderRadius borderRadius([double? custom]) {
    return BorderRadius.circular(custom ?? radius);
  }
}

class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final BorderSide? borderSide;

  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? AppCardStyle.borderRadius();
    final side = borderSide ?? AppCardStyle.borderSide(context);
    final bg = backgroundColor ?? Theme.of(context).colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: Border.fromBorderSide(side),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: br as BorderRadius?,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? maxHeight;
  final double? maxWidth;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.maxHeight,
    this.maxWidth,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppSurface(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );

    if (maxHeight == null && maxWidth == null) {
      return surface;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? double.infinity,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: surface,
    );
  }
}
