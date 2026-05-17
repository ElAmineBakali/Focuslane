import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';
import 'focus_card.dart';

class FocusMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  const FocusMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = FocuslaneTokens.accent(context);
    final compact = FocuslaneTokens.isCompact(context);

    return FocusCard(
      maxHeight: compact ? 88 : 96,
      padding: EdgeInsets.all(compact ? 9 : 10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: compact ? 22 : 24,
                height: compact ? 22 : 24,
                decoration: BoxDecoration(
                  color: FocuslaneTokens.accentSurface(context, opacity: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: compact ? 13 : 14),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 10,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
