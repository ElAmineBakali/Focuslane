import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? color;

  const FocusChip({
    super.key,
    this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = color ?? cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FocuslaneTokens.spacing8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius12),
        border: Border.all(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: tone),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class FocusTag extends StatelessWidget {
  final String text;
  final Color? color;

  const FocusTag({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? FocuslaneTokens.accent(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FocuslaneTokens.spacing8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.14),
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius12),
        border: Border.all(
          color: FocuslaneTokens.borderColor(context),
          width: FocuslaneTokens.borderW,
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
