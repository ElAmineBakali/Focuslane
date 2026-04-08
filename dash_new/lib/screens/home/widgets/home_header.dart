import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/ui/tokens/focuslane_semantic_tokens.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.dateLabel,
    required this.summary,
    required this.onOpenSettings,
    required this.onToggleTheme,
    required this.isDark,
  });

  final String greeting;
  final String dateLabel;
  final String summary;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleTheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: FocuslaneSemanticTokens.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: FocuslaneSemanticTokens.textSecondary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                style: textTheme.bodySmall?.copyWith(
                  color: FocuslaneSemanticTokens.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
        ),
        const SizedBox(width: 2),
        IconButton(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Perfil y ajustes',
        ),
      ],
    );
  }
}
