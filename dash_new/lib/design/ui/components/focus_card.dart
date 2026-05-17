import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double? maxHeight;
  final double? maxWidth;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final BorderSide? borderSide;
  final bool elevated;
  final Clip clipBehavior;

  const FocusCard({
    super.key,
    required this.child,
    this.padding = FocuslaneTokens.cardPadding,
    this.onTap,
    this.maxHeight,
    this.maxWidth,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
    this.elevated = true,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(FocuslaneTokens.radius12);
    final materialRadius =
        br is BorderRadius
            ? br
            : BorderRadius.circular(FocuslaneTokens.radius12);
    final side =
        borderSide ??
        BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: FocuslaneTokens.borderW,
        );
    final bg = backgroundColor ?? FocuslaneTokens.surfaceColor(context);
    final resolvedPadding =
        padding == FocuslaneTokens.cardPadding
            ? FocuslaneTokens.cardPaddingFor(context)
            : padding;

    final card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: Border.fromBorderSide(side),
        boxShadow: elevated ? FocuslaneTokens.cardShadow(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: materialRadius,
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          borderRadius: materialRadius,
          child: Padding(padding: resolvedPadding, child: child),
        ),
      ),
    );

    if (maxHeight == null && maxWidth == null) {
      return card;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? double.infinity,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: card,
    );
  }
}
