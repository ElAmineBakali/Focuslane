import 'package:flutter/material.dart';
import '../../ui/components/focus_card.dart';
import '../../ui/tokens/focuslane_tokens.dart';

class AppCardStyle {
  static double radius = FocuslaneTokens.radius16;
  static double borderWidth = FocuslaneTokens.borderW;

  static BorderSide borderSide(BuildContext context) {
    final color = FocuslaneTokens.borderColor(context);
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
    return FocusCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      borderSide: borderSide,
      child: child,
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
    return FocusCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      child: child,
    );
  }
}
