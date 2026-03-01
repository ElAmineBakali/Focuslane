import 'package:flutter/material.dart';

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 3),
    Color? color,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = color ?? cs.surfaceContainerHigh;
    final fg = cs.onSurfaceVariant;

    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: duration,
      elevation: 8,
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'OK',
        textColor: cs.primary,
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message,
      icon: Icons.error_rounded,
      color: Theme.of(context).colorScheme.errorContainer,
    );
  }

  static void info(BuildContext context, String message) {
    show(context, message, icon: Icons.info_rounded);
  }

  static void success(BuildContext context, String message) {
    show(context, message, icon: Icons.check_circle_rounded);
  }
}
