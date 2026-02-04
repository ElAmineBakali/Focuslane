import 'package:flutter/material.dart';

class AppModuleHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showExit;
  final VoidCallback? onExit;
  final bool useSoftGradient;

  const AppModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.showExit = true,
    this.onExit,
    this.useSoftGradient = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final exitAction = IconButton(
      icon: const Icon(Icons.logout, size: 18),
      tooltip: 'Salir del módulo',
      onPressed: onExit ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
    );

    final mergedActions = <Widget>[
      ...?actions,
      if (showExit) exitAction,
    ];

    return AppBar(
      toolbarHeight: 48,
      titleSpacing: 12,
      centerTitle: centerTitle,
      leading: leading,
      flexibleSpace: useSoftGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primaryContainer.withOpacity(0.6),
                    cs.secondaryContainer.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            )
          : null,
      title: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: mergedActions.isEmpty ? null : mergedActions,
    );
  }
}
