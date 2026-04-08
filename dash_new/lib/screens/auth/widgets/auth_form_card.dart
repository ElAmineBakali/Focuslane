import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/design/ui/components/focus_card.dart';
import 'package:mi_dashboard_personal/design/ui/tokens/focuslane_semantic_tokens.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      backgroundColor: FocuslaneSemanticTokens.cardBackground(context),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: child,
      ),
    );
  }
}
