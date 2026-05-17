import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final compact = FocuslaneTokens.isCompact(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 46 : 54,
          height: compact ? 46 : 54,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.psychology_rounded,
            color: scheme.onPrimary,
            size: compact ? 24 : 28,
          ),
        ),
        SizedBox(height: compact ? 10 : 14),
        Text(
          'FocusLane',
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (compact ? textTheme.titleLarge : textTheme.headlineSmall)
              ?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
        ),
        SizedBox(height: compact ? 6 : 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
