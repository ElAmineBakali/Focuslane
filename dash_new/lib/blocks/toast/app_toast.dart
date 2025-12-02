import 'package:flutter/material.dart';

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info,
    Color? color,
    Color? textColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = color ?? cs.surfaceContainerHigh;
    final fgColor = textColor ?? cs.onSurface;
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      margin: EdgeInsets.fromLTRB(
        isMobile ? 16 : 20,
        0,
        isMobile ? 16 : 20,
        isMobile ? 20 : 24,
      ),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 14 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bg,
              bg.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: fgColor, size: isMobile ? 20 : 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                  fontSize: isMobile ? 14 : 15,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
    final sm = ScaffoldMessenger.of(context);
    sm.clearSnackBars();
    sm.showSnackBar(snack);
  }

  static void success(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        context,
        message,
        icon: Icons.check_circle_rounded,
        color: Theme.of(context).colorScheme.primaryContainer,
        textColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      
  static void error(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        context,
        message,
        icon: Icons.error_rounded,
        color: Theme.of(context).colorScheme.errorContainer,
        textColor: Theme.of(context).colorScheme.onErrorContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      
  static void info(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        context,
        message,
        icon: Icons.info_rounded,
        color: Theme.of(context).colorScheme.secondaryContainer,
        textColor: Theme.of(context).colorScheme.onSecondaryContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );
      
  static void warning(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(
        context,
        message,
        icon: Icons.warning_rounded,
        color: Theme.of(context).colorScheme.tertiaryContainer,
        textColor: Theme.of(context).colorScheme.onTertiaryContainer,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}
