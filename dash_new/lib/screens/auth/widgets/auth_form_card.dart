import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/focuslane_ui.dart';

class AuthFormCard extends StatelessWidget {
  const AuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return FocusCard(
      padding: EdgeInsets.all(width < 420 ? 18 : 24),
      child: child,
    );
  }
}
