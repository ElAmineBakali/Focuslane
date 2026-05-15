import 'package:flutter/material.dart';

import '../tokens/focuslane_tokens.dart';

class FocusHeader extends StatelessWidget implements PreferredSizeWidget {
  const FocusHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.centerTitle = false,
    this.showExit = false,
    this.onExit,
    this.useSoftGradient = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final bool centerTitle;
  final bool showExit;
  final VoidCallback? onExit;
  final bool useSoftGradient;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final exitAction = IconButton(
      icon: const Icon(Icons.logout, size: 18),
      tooltip: 'Salir del modulo',
      onPressed:
          onExit ?? () => Navigator.of(context).popUntil((r) => r.isFirst),
    );

    final mergedActions = <Widget>[...?actions, if (showExit) exitAction];

    return AppBar(
      toolbarHeight: preferredSize.height,
      titleSpacing: 12,
      centerTitle: centerTitle,
      backgroundColor: scheme.surface.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      leading: leading,
      leadingWidth: leadingWidth,
      flexibleSpace:
          useSoftGradient
              ? Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.surface.withValues(alpha: 0.92),
                      scheme.surfaceContainerLow.withValues(alpha: 0.92),
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
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: mergedActions.isEmpty ? null : mergedActions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: FocuslaneTokens.dividerW,
          thickness: FocuslaneTokens.dividerW,
          color: scheme.outlineVariant,
        ),
      ),
    );
  }
}
