import 'package:flutter/material.dart';
import '../../ui/components/focus_header.dart';

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
    return FocusHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      showExit: showExit,
      onExit: onExit,
      useSoftGradient: useSoftGradient,
    );
  }
}
