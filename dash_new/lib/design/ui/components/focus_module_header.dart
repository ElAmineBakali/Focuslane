import 'package:flutter/material.dart';
import 'focus_header.dart';

enum FocusModuleLeadingMode { exitModule, backToModuleDashboard }

class FocusModuleHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final FocusModuleLeadingMode leadingMode;
  final List<Widget>? actions;
  final VoidCallback? onExit;
  final VoidCallback? onBack;
  final String? backRouteName;
  final double leadingWidth;

  const FocusModuleHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.leadingMode,
    this.actions,
    this.onExit,
    this.onBack,
    this.backRouteName,
    this.leadingWidth = 96,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  static Widget buildLeading(
    BuildContext context, {
    required FocusModuleLeadingMode mode,
    VoidCallback? onExit,
    VoidCallback? onBack,
    String? backRouteName,
  }) {
    final label = mode == FocusModuleLeadingMode.exitModule ? 'Salir' : 'Panel';
    final icon =
        mode == FocusModuleLeadingMode.exitModule
            ? Icons.close
            : Icons.arrow_back_rounded;

    return TextButton.icon(
      onPressed: () {
        if (mode == FocusModuleLeadingMode.exitModule) {
          if (onExit != null) {
            onExit();
            return;
          }
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }
        if (onBack != null) {
          onBack();
          return;
        }
        if (backRouteName != null) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(backRouteName, (route) => route.isFirst);
          return;
        }
        Navigator.of(context).maybePop();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      leading: FocusModuleHeader.buildLeading(
        context,
        mode: leadingMode,
        onExit: onExit,
        onBack: onBack,
        backRouteName: backRouteName,
      ),
      leadingWidth: leadingWidth,
      useSoftGradient: true,
    );
  }
}
