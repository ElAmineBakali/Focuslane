import 'package:flutter/material.dart';
import 'focus_card.dart';

class FocusListCard extends StatelessWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Widget? trailing;

  const FocusListCard({
    super.key,
    this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final builtChild =
        child ??
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leadingIcon != null
              ? Icon(leadingIcon, color: leadingColor)
              : null,
          title: title != null ? Text(title!) : null,
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing,
          onTap: onTap,
        );

    return FocusCard(
      onTap: onTap,
      padding: padding,
      child: builtChild,
    );
  }
}
