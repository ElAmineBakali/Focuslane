import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusBadge extends StatelessWidget {
  final String? label;
  final String? text;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry padding;

  const FocusBadge({
    super.key,
    this.label,
    this.text,
    this.color,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? FocuslaneTokens.accent(context);
    final resolvedLabel = label ?? text ?? '';
    final compact = FocuslaneTokens.isCompact(context);
    final resolvedPadding =
        padding == const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            ? EdgeInsets.symmetric(
              horizontal: compact ? 7 : 8,
              vertical: compact ? 3 : 4,
            )
            : padding;

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
        border: Border.all(
          color: tone.withValues(alpha: 0.22),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Text(
        resolvedLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor ?? tone,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
