import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.spacing = FocuslaneTokens.spacing24,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final compact = FocuslaneTokens.isCompact(context);
        final effectiveSpacing =
            compact ? FocuslaneTokens.gridGapFor(context, spacing) : spacing;
        final mobileColumns = width >= 340 && minItemWidth <= 220 ? 2 : 1;
        final columns =
            compact
                ? mobileColumns
                : (width / minItemWidth).floor().clamp(1, 4).toInt();
        return Wrap(
          spacing: effectiveSpacing,
          runSpacing: effectiveSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: (width - effectiveSpacing * (columns - 1)) / columns,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
