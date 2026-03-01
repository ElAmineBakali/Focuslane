import 'package:flutter/material.dart';
import 'package:mi_dashboard_personal/navigation/app_routes.dart';
import 'package:flutter/services.dart';
import '../../../design/ui/components/focus_card.dart';
import '../../../design/ui/components/focus_module_header.dart';
import '../../../design/ui/components/focus_text_field.dart';
import '../../../design/ui/feedback/focus_feedback.dart';
import '../../../design/ui/tokens/focuslane_tokens.dart';

class FoodCompactCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double maxHeight;
  final double? maxWidth;
  final Color? background;
  final BorderRadiusGeometry borderRadius;

  const FoodCompactCard({
    super.key,
    required this.child,
    this.padding = FocuslaneTokens.cardPaddingCompact,
    this.onTap,
    this.maxHeight = 150,
    this.maxWidth,
    this.background,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(FocuslaneTokens.radius16),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return FocusCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: background,
      borderRadius: borderRadius,
      maxHeight: maxHeight,
      maxWidth: maxWidth,
      child: child,
    );
  }
}

class FoodCompactTile extends StatelessWidget {
  final Widget? leading;
  final Widget? trailing;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double height;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const FoodCompactTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.height = 44,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );
    final effectiveSubtitleStyle =
        subtitleStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.2,
        );

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(FocuslaneTokens.radius12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FocuslaneTokens.radius12),
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(height: height),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: effectiveTitleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: effectiveSubtitleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FoodCompactTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffix;
  final bool obscureText;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const FoodCompactTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.obscureText = false,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTextField(
      label: label,
      hint: hint,
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffix: suffix,
      obscureText: obscureText,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
    );
  }
}

class FoodInlineBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const FoodInlineBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 52),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: FocuslaneTokens.accentSurface(context, opacity: 0.12),
          borderRadius: BorderRadius.circular(FocuslaneTokens.radius16),
          border: Border.all(
            color: FocuslaneTokens.borderColor(context),
            width: FocuslaneTokens.borderW,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: FocuslaneTokens.accent(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

class FoodCompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final FocusModuleLeadingMode leadingMode;
  final VoidCallback? onExit;
  final VoidCallback? onBack;
  final String? backRouteName;

  const FoodCompactAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leadingMode = FocusModuleLeadingMode.backToModuleDashboard,
    this.onExit,
    this.onBack,
    this.backRouteName = AppRoutes.foodDashboard,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return FocusModuleHeader(
      title: title,
      subtitle: subtitle,
      actions: actions,
      leadingMode: leadingMode,
      onExit: onExit,
      onBack: onBack,
      backRouteName: backRouteName,
    );
  }
}

class FoodFeedback {
  static void showSuccess(BuildContext context, String message) {
    FocusFeedback.showSuccess(context, message);
  }

  static void showError(BuildContext context, String message) {
    FocusFeedback.showError(context, message);
  }

  static void showInfo(BuildContext context, String message) {
    FocusFeedback.showInfo(context, message);
  }
}

