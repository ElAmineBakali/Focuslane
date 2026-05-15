import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = FocuslaneTokens.containerMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final resolvedPadding =
        padding ??
        EdgeInsets.all(
          width < 720
              ? FocuslaneTokens.spacing16
              : width < 1180
              ? FocuslaneTokens.spacing24
              : FocuslaneTokens.spacing32,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
