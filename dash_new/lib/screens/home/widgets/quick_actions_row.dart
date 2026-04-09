import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_semantic_tokens.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.actions,
  });

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: actions
          .map(
            (item) => OutlinedButton.icon(
              onPressed: item.onTap,
              icon: Icon(item.icon, size: 18),
              label: Text(item.label),
              style: OutlinedButton.styleFrom(
                backgroundColor: FocuslaneSemanticTokens.filledSurface(context).withOpacity(0.35),
                foregroundColor: FocuslaneSemanticTokens.textPrimary(context),
                side: BorderSide(color: FocuslaneSemanticTokens.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

