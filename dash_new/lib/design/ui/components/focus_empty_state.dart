import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const FocusEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = color ?? FocuslaneTokens.accent(context);
    final compact = FocuslaneTokens.isCompact(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : FocuslaneTokens.spacing16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 48 : 64,
              color: tone.withValues(alpha: 0.35),
            ),
            SizedBox(height: compact ? 10 : FocuslaneTokens.spacing12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: compact ? 6 : FocuslaneTokens.spacing8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 10 : FocuslaneTokens.spacing12),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: FocuslaneTokens.accent(context),
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
