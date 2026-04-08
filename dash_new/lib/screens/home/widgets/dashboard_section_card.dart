import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/ui/components/focus_card.dart';
import 'package:mi_dashboard_personal/design/ui/components/focus_section_title.dart';
import 'package:mi_dashboard_personal/design/ui/tokens/focuslane_semantic_tokens.dart';

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    required this.child,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      onTap: onTap,
      backgroundColor: FocuslaneSemanticTokens.cardBackground(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FocusSectionTitle(
            title: title,
            subtitle: subtitle,
            action: action,
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
