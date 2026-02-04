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

  const FocusCard({
    super.key,
    required this.child,
    this.padding = FocuslaneTokens.cardPaddingCompact,
    this.onTap,
    this.maxHeight,
    this.maxWidth,
    this.backgroundColor,
    this.borderRadius,
    this.borderSide,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ??
        BorderRadius.circular(FocuslaneTokens.radius16);
    final side =
        borderSide ??
        BorderSide(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        );
    final bg = backgroundColor ?? FocuslaneTokens.surfaceColor(context);

    final card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: Border.fromBorderSide(side),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br as BorderRadius?,
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
