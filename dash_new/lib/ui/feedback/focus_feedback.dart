import 'package:flutter/material.dart';
import '../tokens/focuslane_tokens.dart';

class FocusFeedback {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, icon: Icons.check_circle, tone: null);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, icon: Icons.error_outline, tone: null, isError: true);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, icon: Icons.info_outline, tone: null);
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    Color? tone,
    bool isError = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final fg = tone ?? (isError ? cs.error : FocuslaneTokens.accent(context));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
