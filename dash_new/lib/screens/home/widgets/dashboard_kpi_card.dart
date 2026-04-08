import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/ui/components/focus_card.dart';
import 'package:mi_dashboard_personal/design/ui/tokens/focuslane_semantic_tokens.dart';

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.onTap,
    this.tone,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? FocuslaneSemanticTokens.primary(context);
    final textTheme = Theme.of(context).textTheme;

    return FocusCard(
      onTap: onTap,
      backgroundColor: FocuslaneSemanticTokens.cardBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: FocuslaneSemanticTokens.textSecondary(context)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(color: FocuslaneSemanticTokens.textSecondary(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
