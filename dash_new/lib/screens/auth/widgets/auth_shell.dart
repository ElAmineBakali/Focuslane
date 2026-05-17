import 'package:flutter/material.dart';
import 'package:focuslane/design/ui/tokens/focuslane_tokens.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = FocuslaneTokens.isCompact(context);

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: width < 640 ? 12 : 24,
              vertical:
                  compact
                      ? 12
                      : width < 640
                      ? 18
                      : 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
